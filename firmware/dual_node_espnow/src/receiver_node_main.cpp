#include <Arduino.h>
#include <WiFi.h>
#include <esp_now.h>
#include <esp_wifi.h>

#include "transport_config.h"
#include "transport_packet.h"

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
volatile bool g_sender_seen = false;
uint8_t g_first_sender_mac[6] = {};
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

  if (!g_sender_seen) {
    memcpy(g_first_sender_mac, src_addr, 6);
    g_sender_seen = true;
  }

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

void print_sender_metadata_once() {
  uint8_t sender_mac_copy[6] = {};
  bool sender_seen = false;

  portENTER_CRITICAL(&g_queue_mux);
  sender_seen = g_sender_seen;
  if (sender_seen) {
    memcpy(sender_mac_copy, g_first_sender_mac, sizeof(sender_mac_copy));
  }
  portEXIT_CRITICAL(&g_queue_mux);

  if (!sender_seen) {
    return;
  }

  static bool printed = false;
  if (printed) {
    return;
  }

  char sender_mac[18] = {};
  phase14b::format_mac(sender_mac_copy, sender_mac, sizeof(sender_mac));
  Serial.print("# source_mac=");
  Serial.println(sender_mac);
  printed = true;
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
  print_sender_metadata_once();

  ReceivedFrame frame = {};
  if (pop_frame(frame)) {
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
