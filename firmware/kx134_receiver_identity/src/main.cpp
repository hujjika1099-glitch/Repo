#include <Arduino.h>
#include <WiFi.h>

namespace {
constexpr uint32_t kSerialBaud = 921600;
constexpr uint32_t kReportIntervalMs = 2000;

String receiverMac;
uint32_t lastReportMs = 0;

void printIdentityBlock() {
  Serial.println("# firmware=kx134_receiver_identity");
  Serial.println("# role=receiver_esp32");
  Serial.println("# node_id=receiver_esp32");
  Serial.print("# serial_baud=");
  Serial.println(kSerialBaud);
  Serial.print("# receiver_mac=");
  Serial.println(receiverMac);
  Serial.println("# transport_future=ESP-NOW_RECEIVER_TO_USB_SERIAL");
  Serial.println("# status=READY_FOR_NODE_MAP_CAPTURE");
}
}  // namespace

void setup() {
  Serial.begin(kSerialBaud);
  delay(300);

  WiFi.mode(WIFI_STA);
  WiFi.disconnect(false, false);
  WiFi.setSleep(false);

  receiverMac = WiFi.macAddress();
  printIdentityBlock();
}

void loop() {
  const uint32_t nowMs = millis();
  if (nowMs - lastReportMs >= kReportIntervalMs) {
    lastReportMs = nowMs;
    Serial.print("# receiver_identity,mac=");
    Serial.print(receiverMac);
    Serial.print(",millis=");
    Serial.println(nowMs);
  }
}
