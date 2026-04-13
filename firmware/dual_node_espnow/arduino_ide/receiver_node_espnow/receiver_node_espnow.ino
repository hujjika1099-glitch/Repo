#include <Arduino.h>
#include <WiFi.h>
#include <esp_now.h>
#include <esp_wifi.h>

namespace phase14b {

constexpr uint32_t kSerialBaud = 115200;
constexpr uint32_t kSampleHz = 100;
constexpr uint8_t kWifiChannel = 6;
constexpr uint32_t kStatusPrintIntervalMs = 5000;
constexpr size_t kReceiverQueueCapacity = 64;
constexpr uint8_t kPrimarySensorId = 1;
constexpr uint8_t kSecondarySensorId = 2;
constexpr char kCsvHeader[] = "sensor_id,seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z";

struct __attribute__((packed)) TransportPacket {
  uint8_t sensor_id_u8;
  uint8_t version_u8;
  uint16_t reserved_u16;
  uint32_t seq_u32;
  uint32_t t_us_u32;
  uint16_t raw_x_u16;
  uint16_t raw_y_u16;
  uint16_t raw_z_u16;
  uint16_t mv_x_u16;
  uint16_t mv_y_u16;
  uint16_t mv_z_u16;
};

static_assert(sizeof(TransportPacket) == 24, "TransportPacket size must stay stable");

inline const char* sensor_label_from_id(const uint8_t sensor_id) {
  switch (sensor_id) {
    case kPrimarySensorId:
      return "sensor_B";
    case kSecondarySensorId:
      return "sensor_A";
    default:
      return "sensor_unknown";
  }
}

inline void format_mac(const uint8_t* mac, char* out, const size_t out_size) {
  if (out == nullptr || out_size < 18) {
    return;
  }

  if (mac == nullptr) {
    out[0] = '\0';
    return;
  }

  snprintf(out, out_size, "%02X:%02X:%02X:%02X:%02X:%02X", mac[0], mac[1], mac[2], mac[3],
           mac[4], mac[5]);
}

}  // namespace phase14b

namespace {

struct ReceivedFrame {
  phase14b::TransportPacket packet;
  uint8_t sender_mac[6];
};

ReceivedFrame g_queue[phase14b::kReceiverQueueCapacity];
volatile size_t g_queue_head = 0;
volatile size_t g_queue_tail = 0;
volatile uint32_t g_packets_received = 0;
volatile uint32_t g_packets_invalid = 0;
volatile uint32_t g_queue_drops = 0;
uint32_t g_last_status_ms = 0;

portMUX_TYPE g_queue_mux = portMUX_INITIALIZER_UNLOCKED;

void read_local_mac(uint8_t* out_mac) {
  if (out_mac == nullptr) {
    return;
  }

  WiFi.macAddress(out_mac);
}

bool lock_wifi_channel() {
  esp_err_t err = esp_wifi_set_promiscuous(true);
  if (err != ESP_OK) {
    return false;
  }

  err = esp_wifi_set_channel(phase14b::kWifiChannel, WIFI_SECOND_CHAN_NONE);
  const bool ok = (err == ESP_OK);
  esp_wifi_set_promiscuous(false);
  return ok;
}

bool init_espnow() {
  WiFi.mode(WIFI_STA);
  WiFi.disconnect(false, false);
  WiFi.setSleep(false);

  if (!lock_wifi_channel()) {
    return false;
  }

  if (esp_now_init() != ESP_OK) {
    return false;
  }

  return true;
}

void enqueue_frame(const uint8_t* src_addr, const uint8_t* data, int data_len) {
  if (src_addr == nullptr || data == nullptr || data_len != sizeof(phase14b::TransportPacket)) {
    ++g_packets_invalid;
    return;
  }

  portENTER_CRITICAL_ISR(&g_queue_mux);

  const size_t next_head = (g_queue_head + 1) % phase14b::kReceiverQueueCapacity;
  if (next_head == g_queue_tail) {
    ++g_queue_drops;
    portEXIT_CRITICAL_ISR(&g_queue_mux);
    return;
  }

  g_queue[g_queue_head].packet = *reinterpret_cast<const phase14b::TransportPacket*>(data);
  memcpy(g_queue[g_queue_head].sender_mac, src_addr, 6);
  g_queue_head = next_head;
  ++g_packets_received;

  portEXIT_CRITICAL_ISR(&g_queue_mux);
}

#if defined(ESP_ARDUINO_VERSION_MAJOR) && (ESP_ARDUINO_VERSION_MAJOR >= 3)
void on_data_recv(const esp_now_recv_info_t* recv_info, const uint8_t* data, int data_len) {
  if (recv_info == nullptr) {
    ++g_packets_invalid;
    return;
  }

  enqueue_frame(recv_info->src_addr, data, data_len);
}
#else
void on_data_recv(const uint8_t* mac_addr, const uint8_t* data, int data_len) {
  enqueue_frame(mac_addr, data, data_len);
}
#endif

bool pop_frame(ReceivedFrame& out) {
  bool has_frame = false;

  portENTER_CRITICAL(&g_queue_mux);
  if (g_queue_tail != g_queue_head) {
    out = g_queue[g_queue_tail];
    g_queue_tail = (g_queue_tail + 1) % phase14b::kReceiverQueueCapacity;
    has_frame = true;
  }
  portEXIT_CRITICAL(&g_queue_mux);

  return has_frame;
}

void print_startup_metadata() {
  uint8_t sta_mac[6] = {};
  read_local_mac(sta_mac);

  char local_mac[18] = {};
  phase14b::format_mac(sta_mac, local_mac, sizeof(local_mac));

  Serial.println("# relay=espnow_receiver");
  Serial.println("# source=sensor_node");
  Serial.print("# relay_mac=");
  Serial.println(local_mac);
  Serial.print("# wifi_channel=");
  Serial.println(phase14b::kWifiChannel);
  Serial.print("# sample_hz_target=");
  Serial.println(phase14b::kSampleHz);
  Serial.println(phase14b::kCsvHeader);
}

void print_sender_metadata_once(const ReceivedFrame& frame) {
  static bool printed_sensor_1 = false;
  static bool printed_sensor_2 = false;

  bool* printed_flag = nullptr;
  switch (frame.packet.sensor_id_u8) {
    case phase14b::kPrimarySensorId:
      printed_flag = &printed_sensor_1;
      break;
    case phase14b::kSecondarySensorId:
      printed_flag = &printed_sensor_2;
      break;
    default:
      return;
  }

  if (*printed_flag) {
    return;
  }

  char sender_mac[18] = {};
  phase14b::format_mac(frame.sender_mac, sender_mac, sizeof(sender_mac));
  Serial.print("# source_sensor_id=");
  Serial.print(frame.packet.sensor_id_u8);
  Serial.print(",source_sensor_label=");
  Serial.print(phase14b::sensor_label_from_id(frame.packet.sensor_id_u8));
  Serial.print(",source_mac=");
  Serial.println(sender_mac);
  *printed_flag = true;
}

void print_status() {
  Serial.print("#STAT,relay=receiver,rx=");
  Serial.print(g_packets_received);
  Serial.print(",invalid=");
  Serial.print(g_packets_invalid);
  Serial.print(",queue_drops=");
  Serial.println(g_queue_drops);
}

void print_packet_csv(const phase14b::TransportPacket& packet) {
  Serial.print(packet.sensor_id_u8);
  Serial.print(',');
  Serial.print(packet.seq_u32);
  Serial.print(',');
  Serial.print(packet.t_us_u32);
  Serial.print(',');
  Serial.print(packet.raw_x_u16);
  Serial.print(',');
  Serial.print(packet.raw_y_u16);
  Serial.print(',');
  Serial.print(packet.raw_z_u16);
  Serial.print(',');
  Serial.print(packet.mv_x_u16);
  Serial.print(',');
  Serial.print(packet.mv_y_u16);
  Serial.print(',');
  Serial.println(packet.mv_z_u16);
}

}  // namespace

void setup() {
  Serial.begin(phase14b::kSerialBaud);
  delay(300);

  if (!init_espnow()) {
    Serial.println("# fatal=espnow_init_failed");
    while (true) {
      delay(1000);
    }
  }

  esp_now_register_recv_cb(on_data_recv);
  print_startup_metadata();
  g_last_status_ms = millis();
}

void loop() {
  ReceivedFrame frame = {};
  if (pop_frame(frame)) {
    print_sender_metadata_once(frame);
    print_packet_csv(frame.packet);
  } else {
    delay(1);
  }

  const uint32_t now_ms = millis();
  if (now_ms - g_last_status_ms >= phase14b::kStatusPrintIntervalMs) {
    print_status();
    g_last_status_ms = now_ms;
  }
}
