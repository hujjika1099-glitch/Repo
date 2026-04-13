#include <Arduino.h>
#include <WiFi.h>
#include <esp_now.h>
#include <esp_wifi.h>

#include "transport_config.h"
#include "transport_packet.h"

namespace {

constexpr int PIN_X = 32;
constexpr int PIN_Y = 33;
constexpr int PIN_Z = 34;
constexpr int PIN_ST = 23;

uint32_t g_sequence = 0;
uint32_t g_next_sample_us = 0;
uint32_t g_send_ok = 0;
uint32_t g_send_fail = 0;
uint32_t g_send_callbacks = 0;
uint32_t g_last_status_ms = 0;

void read_local_mac(uint8_t* out_mac) {
  if (out_mac == nullptr) {
    return;
  }

  WiFi.macAddress(out_mac);
}

void configure_adc() {
  analogReadResolution(12);

#if defined(ADC_11db)
  analogSetPinAttenuation(PIN_X, ADC_11db);
  analogSetPinAttenuation(PIN_Y, ADC_11db);
  analogSetPinAttenuation(PIN_Z, ADC_11db);
#elif defined(ADC_ATTEN_DB_12)
  analogSetPinAttenuation(PIN_X, ADC_ATTEN_DB_12);
  analogSetPinAttenuation(PIN_Y, ADC_ATTEN_DB_12);
  analogSetPinAttenuation(PIN_Z, ADC_ATTEN_DB_12);
#endif
}

#if defined(ESP_ARDUINO_VERSION_MAJOR) && (ESP_ARDUINO_VERSION_MAJOR >= 3)
void on_data_sent(const wifi_tx_info_t* tx_info, esp_now_send_status_t status) {
  (void)tx_info;
#else
void on_data_sent(const uint8_t* mac_addr, esp_now_send_status_t status) {
  (void)mac_addr;
#endif
  ++g_send_callbacks;

  if (status == ESP_NOW_SEND_SUCCESS) {
    ++g_send_ok;
  } else {
    ++g_send_fail;
  }
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

  esp_now_register_send_cb(on_data_sent);

  esp_now_peer_info_t peer_info = {};
  memcpy(peer_info.peer_addr, phase14b::kPeerMac, sizeof(phase14b::kPeerMac));
  peer_info.channel = phase14b::kWifiChannel;
  peer_info.encrypt = false;

  if (esp_now_add_peer(&peer_info) != ESP_OK) {
    return false;
  }

  return true;
}

void print_identification() {
  uint8_t sta_mac[6] = {};
  read_local_mac(sta_mac);

  char local_mac[18] = {};
  char peer_mac[18] = {};
  phase14b::format_mac(sta_mac, local_mac, sizeof(local_mac));
  phase14b::format_mac(phase14b::kPeerMac, peer_mac, sizeof(peer_mac));

  Serial.println("# sensor_node=adxl335_espnow");
  Serial.print("# local_mac=");
  Serial.println(local_mac);
  Serial.print("# peer_mac=");
  Serial.println(peer_mac);
  Serial.print("# sensor_id=");
  Serial.println(phase14b::kSensorId);
  Serial.print("# sensor_label=");
  Serial.println(phase14b::kSensorLabel);
  Serial.print("# wifi_channel=");
  Serial.println(phase14b::kWifiChannel);
  Serial.print("# sample_hz=");
  Serial.println(phase14b::kSampleHz);
  Serial.println("# pins:x=GPIO32,y=GPIO33,z=GPIO34,st=GPIO23");
  Serial.print("# peer_mode=");
  Serial.println(phase14b::kUseBroadcastPeer ? "broadcast" : "unicast");
}

void print_status() {
  Serial.print("#STAT,node=sensor,seq=");
  Serial.print(g_sequence);
  Serial.print(",send_ok=");
  Serial.print(g_send_ok);
  Serial.print(",send_fail=");
  Serial.print(g_send_fail);
  Serial.print(",callbacks=");
  Serial.println(g_send_callbacks);
}

void sample_and_send() {
  const int raw_x = analogRead(PIN_X);
  const int raw_y = analogRead(PIN_Y);
  const int raw_z = analogRead(PIN_Z);

  const uint32_t mv_x = analogReadMilliVolts(PIN_X);
  const uint32_t mv_y = analogReadMilliVolts(PIN_Y);
  const uint32_t mv_z = analogReadMilliVolts(PIN_Z);

  phase14b::TransportPacket packet = {};
  packet.sensor_id_u8 = phase14b::kSensorId;
  packet.version_u8 = phase14b::kTransportVersion;
  packet.reserved_u16 = 0;
  packet.seq_u32 = g_sequence;
  packet.t_us_u32 = micros();
  packet.raw_x_u16 = static_cast<uint16_t>(raw_x);
  packet.raw_y_u16 = static_cast<uint16_t>(raw_y);
  packet.raw_z_u16 = static_cast<uint16_t>(raw_z);
  packet.mv_x_u16 = static_cast<uint16_t>(mv_x);
  packet.mv_y_u16 = static_cast<uint16_t>(mv_y);
  packet.mv_z_u16 = static_cast<uint16_t>(mv_z);

  const esp_err_t err =
      esp_now_send(phase14b::kPeerMac, reinterpret_cast<const uint8_t*>(&packet), sizeof(packet));
  if (err != ESP_OK) {
    ++g_send_fail;
  }

  ++g_sequence;
}

}  // namespace

void setup() {
  Serial.begin(phase14b::kSerialBaud);
  delay(300);

  pinMode(PIN_ST, OUTPUT);
  digitalWrite(PIN_ST, LOW);
  configure_adc();

  if (!init_espnow()) {
    Serial.println("# fatal=espnow_init_failed");
    while (true) {
      delay(1000);
    }
  }

  print_identification();
  g_next_sample_us = micros();
  g_last_status_ms = millis();
}

void loop() {
  const uint32_t now_us = micros();
  if ((int32_t)(now_us - g_next_sample_us) >= 0) {
    g_next_sample_us += phase14b::kSamplePeriodUs;
    if ((int32_t)(now_us - g_next_sample_us) >= 0) {
      g_next_sample_us = now_us + phase14b::kSamplePeriodUs;
    }

    sample_and_send();
  }

  const uint32_t now_ms = millis();
  if (now_ms - g_last_status_ms >= phase14b::kStatusPrintIntervalMs) {
    print_status();
    g_last_status_ms = now_ms;
  }
}
