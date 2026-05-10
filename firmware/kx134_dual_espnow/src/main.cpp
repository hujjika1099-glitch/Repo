#include <Arduino.h>
#include <WiFi.h>
#include <esp_now.h>
#include <esp_wifi.h>

#include "kx134_calibration_constants.h"
#include "kx134_espnow_packet.h"

#if KX134_NODE_ROLE_SENSOR
#include <SparkFun_KX13X.h>
#include <Wire.h>
#endif

#ifndef KX134_NODE_ROLE_SENSOR
#define KX134_NODE_ROLE_SENSOR 0
#endif

#ifndef KX134_NODE_ROLE_RECEIVER
#define KX134_NODE_ROLE_RECEIVER 0
#endif

#ifndef KX134_SENSOR_ID
#define KX134_SENSOR_ID 0
#endif

#ifndef KX134_SAMPLE_RATE_HZ
#define KX134_SAMPLE_RATE_HZ 100
#endif

#ifndef KX134_ODR_HZ
#define KX134_ODR_HZ KX134_SAMPLE_RATE_HZ
#endif

#ifndef KX134_RANGE_G
#define KX134_RANGE_G 8
#endif

#ifndef KX134_I2C_SDA
#define KX134_I2C_SDA 21
#endif

#ifndef KX134_I2C_SCL
#define KX134_I2C_SCL 22
#endif

#ifndef KX134_I2C_FREQ_HZ
#define KX134_I2C_FREQ_HZ 400000
#endif

#ifndef KX134_SERIAL_BAUD
#define KX134_SERIAL_BAUD 921600
#endif

#ifndef KX134_ESPNOW_CHANNEL
#define KX134_ESPNOW_CHANNEL 1
#endif

#if KX134_NODE_ROLE_SENSOR && KX134_NODE_ROLE_RECEIVER
#error "Build must select either sensor or receiver role, not both"
#endif

#if !KX134_NODE_ROLE_SENSOR && !KX134_NODE_ROLE_RECEIVER
#error "Build must select sensor or receiver role"
#endif

#if KX134_NODE_ROLE_SENSOR && ((KX134_SENSOR_ID != 1) && (KX134_SENSOR_ID != 2))
#error "Sensor role requires KX134_SENSOR_ID 1 or 2"
#endif

namespace {

constexpr const char* kProtocolVersion = "kx134.v3";
constexpr const char* kSessionId = "ESPNOW_DUAL_PROTOTYPE";
constexpr const char* kSyncGroupId = "KX134_DUAL_BRINGUP";
constexpr const char* kFirmwareVersion = "kx134_dual_espnow.0.1.0";
constexpr uint32_t kSamplePeriodUs = 1000000UL / KX134_SAMPLE_RATE_HZ;
constexpr uint8_t kPrimaryAddress = 0x1F;
constexpr uint8_t kSecondaryAddress = 0x1E;

const uint8_t kReceiverMac[6] = {
    KX134_RECEIVER_MAC0,
    KX134_RECEIVER_MAC1,
    KX134_RECEIVER_MAC2,
    KX134_RECEIVER_MAC3,
    KX134_RECEIVER_MAC4,
    KX134_RECEIVER_MAC5};

const uint8_t kSensor1Mac[6] = {
    KX134_SENSOR1_MAC0,
    KX134_SENSOR1_MAC1,
    KX134_SENSOR1_MAC2,
    KX134_SENSOR1_MAC3,
    KX134_SENSOR1_MAC4,
    KX134_SENSOR1_MAC5};

const uint8_t kSensor2Mac[6] = {
    KX134_SENSOR2_MAC0,
    KX134_SENSOR2_MAC1,
    KX134_SENSOR2_MAC2,
    KX134_SENSOR2_MAC3,
    KX134_SENSOR2_MAC4,
    KX134_SENSOR2_MAC5};

char local_mac_text[18] = "00:00:00:00:00:00";
uint8_t local_mac[6] = {};

const char* boolText(bool value) {
  return value ? "true" : "false";
}

const char* physicalLabelForSensor(uint8_t sensor_id) {
  return sensor_id == 1 ? "KX134_SENSOR_1" : "KX134_SENSOR_2";
}

const char* nodeIdForSensor(uint8_t sensor_id) {
  return sensor_id == 1 ? "sensor_node_1" : "sensor_node_2";
}

const uint8_t* expectedMacForSensor(uint8_t sensor_id) {
  return sensor_id == 1 ? kSensor1Mac : kSensor2Mac;
}

void cacheLocalMacAddress() {
  WiFi.macAddress(local_mac);
  formatMac(local_mac, local_mac_text, sizeof(local_mac_text));
}

void configureWifiForEspNow() {
  WiFi.mode(WIFI_STA);
  WiFi.disconnect(false, false);
  WiFi.setSleep(false);
  cacheLocalMacAddress();
  esp_wifi_set_channel(KX134_ESPNOW_CHANNEL, WIFI_SECOND_CHAN_NONE);
}

void printCommonStartupMetadata(const char* role) {
  char receiver_mac_text[18] = {};
  char sensor1_mac_text[18] = {};
  char sensor2_mac_text[18] = {};
  formatMac(kReceiverMac, receiver_mac_text, sizeof(receiver_mac_text));
  formatMac(kSensor1Mac, sensor1_mac_text, sizeof(sensor1_mac_text));
  formatMac(kSensor2Mac, sensor2_mac_text, sizeof(sensor2_mac_text));

  Serial.println("# boot_marker=after_serial_begin");
  Serial.println("# firmware=kx134_dual_espnow");
  Serial.print("# firmware_version=");
  Serial.println(kFirmwareVersion);
  Serial.print("# role=");
  Serial.println(role);
  Serial.print("# local_mac=");
  Serial.println(local_mac_text);
  Serial.print("# receiver_mac_expected=");
  Serial.println(receiver_mac_text);
  Serial.print("# sensor_1_mac_expected=");
  Serial.println(sensor1_mac_text);
  Serial.print("# sensor_2_mac_expected=");
  Serial.println(sensor2_mac_text);
  Serial.print("# espnow_channel=");
  Serial.println(KX134_ESPNOW_CHANNEL);
  Serial.print("# serial_baud=");
  Serial.println(KX134_SERIAL_BAUD);
  Serial.print("# protocol_version=");
  Serial.println(kProtocolVersion);
  Serial.print("# sample_rate_hz=");
  Serial.println(KX134_SAMPLE_RATE_HZ);
  Serial.print("# odr_hz=");
  Serial.println(KX134_ODR_HZ);
  Serial.print("# range_g=");
  Serial.println(KX134_RANGE_G);
}

void printCsvHeader() {
  Serial.println(
      "protocol_version,session_id,sensor_id,physical_label,node_id,node_mac,seq,"
      "sensor_t_us,receiver_t_us,pc_wall_s,sync_group_id,pair_seq,x_raw,y_raw,z_raw,"
      "x_g,y_g,z_g,sample_rate_hz,odr_hz,range_g,calibration_id,calibration_applied,"
      "packet_status,packet_error_code,firmware_version,contract_version");
}

#if KX134_NODE_ROLE_SENSOR

SparkFun_KX134 kxAccel;
uint8_t detected_address = 0;
bool sensor_ready = false;
bool espnow_ready = false;
uint32_t sequence_id = 0;
uint32_t next_sample_us = 0;
uint32_t send_ok = 0;
uint32_t send_fail = 0;
uint32_t send_callbacks = 0;
uint32_t last_status_ms = 0;

uint8_t rangeCode() {
#if KX134_RANGE_G == 8
  return SFE_KX134_RANGE8G;
#elif KX134_RANGE_G == 16
  return SFE_KX134_RANGE16G;
#elif KX134_RANGE_G == 32
  return SFE_KX134_RANGE32G;
#else
  return SFE_KX134_RANGE64G;
#endif
}

uint8_t odrCode() {
#if KX134_ODR_HZ == 100
  return 7;
#elif KX134_ODR_HZ == 200
  return 8;
#elif KX134_ODR_HZ == 400
  return 9;
#else
  return 10;
#endif
}

bool beginAtAddress(uint8_t address) {
  return kxAccel.begin(Wire, address);
}

bool configureSensor() {
  if (!kxAccel.softwareReset()) {
    Serial.println("# warning=KX134_SOFTWARE_RESET_FAILED");
    return false;
  }
  delay(30);
  if (!kxAccel.enableAccel(false)) {
    Serial.println("# warning=KX134_DISABLE_ACCEL_FAILED");
    return false;
  }
  delay(5);
  if (!kxAccel.setRange(rangeCode())) {
    Serial.println("# warning=KX134_SET_RANGE_FAILED");
    return false;
  }
  if (!kxAccel.setOutputDataRate(odrCode())) {
    Serial.println("# warning=KX134_SET_ODR_FAILED");
    return false;
  }
  if (!kxAccel.enableDataEngine(true)) {
    Serial.println("# warning=KX134_ENABLE_DATA_ENGINE_FAILED");
    return false;
  }
  if (!kxAccel.enableAccel(true)) {
    Serial.println("# warning=KX134_ENABLE_ACCEL_FAILED");
    return false;
  }
  delay(20);
  return true;
}

bool initializeSensor() {
  if (beginAtAddress(kPrimaryAddress)) {
    detected_address = kPrimaryAddress;
  } else if (beginAtAddress(kSecondaryAddress)) {
    detected_address = kSecondaryAddress;
  } else {
    return false;
  }
  return configureSensor();
}

bool probeI2cAddress(uint8_t address) {
  Wire.beginTransmission(address);
  return Wire.endTransmission() == 0;
}

void printI2cProbe() {
  Serial.print("# i2c_probe_0x1F=");
  Serial.println(probeI2cAddress(kPrimaryAddress) ? "present" : "missing");
  Serial.print("# i2c_probe_0x1E=");
  Serial.println(probeI2cAddress(kSecondaryAddress) ? "present" : "missing");
}

void onSendComplete(const uint8_t* mac_addr, esp_now_send_status_t status) {
  (void)mac_addr;
  ++send_callbacks;
  if (status == ESP_NOW_SEND_SUCCESS) {
    ++send_ok;
  } else {
    ++send_fail;
  }
}

bool initializeEspNowSensor() {
  if (esp_now_init() != ESP_OK) {
    Serial.println("# error=ESPNOW_INIT_FAILED");
    return false;
  }
  esp_now_register_send_cb(onSendComplete);

  esp_now_peer_info_t peer = {};
  memcpy(peer.peer_addr, kReceiverMac, 6);
  peer.channel = KX134_ESPNOW_CHANNEL;
  peer.encrypt = false;
  if (esp_now_add_peer(&peer) != ESP_OK) {
    Serial.println("# error=ESPNOW_ADD_RECEIVER_PEER_FAILED");
    return false;
  }
  return true;
}

void printSensorStartupMetadata() {
  const Kx134Calibration* calibration = calibrationForSensor(KX134_SENSOR_ID);
  Serial.print("# sensor_id=");
  Serial.println(KX134_SENSOR_ID);
  Serial.print("# physical_label=");
  Serial.println(physicalLabelForSensor(KX134_SENSOR_ID));
  Serial.print("# node_id=");
  Serial.println(nodeIdForSensor(KX134_SENSOR_ID));
  Serial.print("# node_mac=");
  Serial.println(local_mac_text);
  Serial.print("# calibration_id=");
  Serial.println(calibration ? calibration->calibration_id : "MISSING_CALIBRATION");
  Serial.print("# i2c_sda=");
  Serial.println(KX134_I2C_SDA);
  Serial.print("# i2c_scl=");
  Serial.println(KX134_I2C_SCL);
  Serial.print("# i2c_freq_hz=");
  Serial.println(KX134_I2C_FREQ_HZ);
  Serial.print("# odr_code=");
  Serial.println(odrCode());
}

void printSensorStatus() {
  Serial.print("#STAT,role=sensor,sensor_id=");
  Serial.print(KX134_SENSOR_ID);
  Serial.print(",node_mac=");
  Serial.print(local_mac_text);
  Serial.print(",receiver_mac=");
  char receiver_mac_text[18] = {};
  formatMac(kReceiverMac, receiver_mac_text, sizeof(receiver_mac_text));
  Serial.print(receiver_mac_text);
  Serial.print(",i2c_address=0x");
  Serial.print(detected_address, HEX);
  Serial.print(",seq=");
  Serial.print(sequence_id);
  Serial.print(",send_ok=");
  Serial.print(send_ok);
  Serial.print(",send_fail=");
  Serial.print(send_fail);
  Serial.print(",callbacks=");
  Serial.print(send_callbacks);
  Serial.print(",sensor_ready=");
  Serial.print(boolText(sensor_ready));
  Serial.print(",espnow_ready=");
  Serial.println(boolText(espnow_ready));
}

void printSensorInitError() {
  Serial.println("# packet_status=SENSOR_INIT_ERROR");
  Serial.println("# packet_error_code=SENSOR_INIT_ERROR");
  Serial.println("# fatal=KX134_NOT_READY_AT_0x1F_OR_0x1E");
  printI2cProbe();
}

void fillPacket(Kx134EspnowPacket& packet, const rawOutputData& raw_data, uint32_t sensor_t_us) {
  const Kx134Calibration* calibration = calibrationForSensor(KX134_SENSOR_ID);
  memset(&packet, 0, sizeof(packet));

  const int16_t x_raw = static_cast<int16_t>(raw_data.xData);
  const int16_t y_raw = static_cast<int16_t>(raw_data.yData);
  const int16_t z_raw = static_cast<int16_t>(raw_data.zData);

  packet.magic = KX134_ESPNOW_MAGIC;
  packet.packet_version = KX134_ESPNOW_PACKET_VERSION;
  packet.packet_size = sizeof(Kx134EspnowPacket);
  packet.sensor_id = KX134_SENSOR_ID;
  memcpy(packet.node_mac, local_mac, sizeof(packet.node_mac));
  packet.seq = sequence_id;
  packet.sensor_t_us = sensor_t_us;
  packet.x_raw = x_raw;
  packet.y_raw = y_raw;
  packet.z_raw = z_raw;
  if (calibration) {
    packet.x_g = calibratedXG(x_raw, KX134_RANGE_G, *calibration);
    packet.y_g = calibratedYG(y_raw, KX134_RANGE_G, *calibration);
    packet.z_g = calibratedZG(z_raw, KX134_RANGE_G, *calibration);
    packet.calibration_applied = 1;
    copyFixedString(packet.calibration_id, sizeof(packet.calibration_id), calibration->calibration_id);
  } else {
    packet.x_g = rawToUncalibratedG(x_raw, KX134_RANGE_G);
    packet.y_g = rawToUncalibratedG(y_raw, KX134_RANGE_G);
    packet.z_g = rawToUncalibratedG(z_raw, KX134_RANGE_G);
    packet.calibration_applied = 0;
    copyFixedString(packet.calibration_id, sizeof(packet.calibration_id), "CALIBRATION_MISSING");
  }
  packet.sample_rate_hz = KX134_SAMPLE_RATE_HZ;
  packet.odr_hz = KX134_ODR_HZ;
  packet.range_g = KX134_RANGE_G;
  copyFixedString(packet.firmware_version, sizeof(packet.firmware_version), kFirmwareVersion);
  copyFixedString(packet.contract_version, sizeof(packet.contract_version), kProtocolVersion);
  packet.checksum = packetChecksum(packet);
}

#endif  // KX134_NODE_ROLE_SENSOR

#if KX134_NODE_ROLE_RECEIVER

struct QueuedPacket {
  Kx134EspnowPacket packet;
  uint8_t src_addr[6];
  uint32_t receiver_t_us;
};

constexpr size_t kQueueCapacity = 64;
QueuedPacket packet_queue[kQueueCapacity] = {};
volatile size_t queue_head = 0;
volatile size_t queue_tail = 0;
volatile uint32_t queue_drops = 0;

uint32_t rx_total = 0;
uint32_t rx_s1 = 0;
uint32_t rx_s2 = 0;
uint32_t invalid_packets = 0;
uint32_t pair_seq = 0;
uint32_t last_status_ms = 0;

bool queuePush(const QueuedPacket& queued) {
  const size_t next_head = (queue_head + 1) % kQueueCapacity;
  if (next_head == queue_tail) {
    ++queue_drops;
    return false;
  }
  packet_queue[queue_head] = queued;
  queue_head = next_head;
  return true;
}

bool queuePop(QueuedPacket& queued) {
  if (queue_tail == queue_head) {
    return false;
  }
  queued = packet_queue[queue_tail];
  queue_tail = (queue_tail + 1) % kQueueCapacity;
  return true;
}

#if ESP_ARDUINO_VERSION_MAJOR >= 3
void onDataReceived(const esp_now_recv_info_t* recv_info, const uint8_t* data, int len) {
  const uint8_t* src_addr = recv_info ? recv_info->src_addr : nullptr;
#else
void onDataReceived(const uint8_t* src_addr, const uint8_t* data, int len) {
#endif
  QueuedPacket queued = {};
  if (src_addr) {
    memcpy(queued.src_addr, src_addr, 6);
  }
  queued.receiver_t_us = micros();
  if (data && len == static_cast<int>(sizeof(Kx134EspnowPacket))) {
    memcpy(&queued.packet, data, sizeof(queued.packet));
  } else {
    queued.packet.packet_size = static_cast<uint8_t>(len > 255 ? 255 : len);
  }
  queuePush(queued);
}

bool initializeEspNowReceiver() {
  if (esp_now_init() != ESP_OK) {
    Serial.println("# error=ESPNOW_INIT_FAILED");
    return false;
  }
  esp_now_register_recv_cb(onDataReceived);
  return true;
}

void printInvalidPacket(const char* error_code, const uint8_t* src_addr, uint8_t sensor_id) {
  char src_text[18] = {};
  formatMac(src_addr, src_text, sizeof(src_text));
  Serial.print("#INVALID,error=");
  Serial.print(error_code ? error_code : "UNKNOWN_ERROR");
  Serial.print(",src_mac=");
  Serial.print(src_text);
  Serial.print(",sensor_id=");
  Serial.println(sensor_id);
}

bool validatePacketIdentity(const Kx134EspnowPacket& packet, const uint8_t* src_addr, const char** error_code) {
  if (!macEquals(packet.node_mac, src_addr)) {
    if (error_code) {
      *error_code = "SRC_MAC_NODE_MAC_MISMATCH";
    }
    return false;
  }
  if (!macEquals(packet.node_mac, expectedMacForSensor(packet.sensor_id))) {
    if (error_code) {
      *error_code = "UNEXPECTED_SENSOR_MAC";
    }
    return false;
  }
  if (packet.sample_rate_hz != KX134_SAMPLE_RATE_HZ) {
    if (error_code) {
      *error_code = "BAD_SAMPLE_RATE";
    }
    return false;
  }
  if (packet.odr_hz != KX134_ODR_HZ) {
    if (error_code) {
      *error_code = "BAD_ODR";
    }
    return false;
  }
  if (packet.range_g != KX134_RANGE_G) {
    if (error_code) {
      *error_code = "BAD_RANGE";
    }
    return false;
  }
  if (packet.calibration_applied != 1) {
    if (error_code) {
      *error_code = "CALIBRATION_NOT_APPLIED";
    }
    return false;
  }
  if (strncmp(packet.contract_version, kProtocolVersion, KX134_CONTRACT_VERSION_LEN) != 0) {
    if (error_code) {
      *error_code = "BAD_CONTRACT_VERSION";
    }
    return false;
  }
  if (error_code) {
    *error_code = "OK";
  }
  return true;
}

void printCsvRow(const Kx134EspnowPacket& packet, uint32_t receiver_t_us) {
  char node_mac_text[18] = {};
  formatMac(packet.node_mac, node_mac_text, sizeof(node_mac_text));

  Serial.print(kProtocolVersion);
  Serial.print(',');
  Serial.print(kSessionId);
  Serial.print(',');
  Serial.print(packet.sensor_id);
  Serial.print(',');
  Serial.print(physicalLabelForSensor(packet.sensor_id));
  Serial.print(',');
  Serial.print(nodeIdForSensor(packet.sensor_id));
  Serial.print(',');
  Serial.print(node_mac_text);
  Serial.print(',');
  Serial.print(packet.seq);
  Serial.print(',');
  Serial.print(packet.sensor_t_us);
  Serial.print(',');
  Serial.print(receiver_t_us);
  Serial.print(',');
  Serial.print(0);
  Serial.print(',');
  Serial.print(kSyncGroupId);
  Serial.print(',');
  Serial.print(pair_seq++);
  Serial.print(',');
  Serial.print(packet.x_raw);
  Serial.print(',');
  Serial.print(packet.y_raw);
  Serial.print(',');
  Serial.print(packet.z_raw);
  Serial.print(',');
  Serial.print(packet.x_g, 6);
  Serial.print(',');
  Serial.print(packet.y_g, 6);
  Serial.print(',');
  Serial.print(packet.z_g, 6);
  Serial.print(',');
  Serial.print(packet.sample_rate_hz);
  Serial.print(',');
  Serial.print(packet.odr_hz);
  Serial.print(',');
  Serial.print(packet.range_g);
  Serial.print(',');
  Serial.print(packet.calibration_id);
  Serial.print(',');
  Serial.print("true");
  Serial.print(',');
  Serial.print("OK");
  Serial.print(',');
  Serial.print("OK");
  Serial.print(',');
  Serial.print(packet.firmware_version);
  Serial.print(',');
  Serial.println(packet.contract_version);
}

void printReceiverStatus() {
  Serial.print("#STAT,role=receiver,rx_total=");
  Serial.print(rx_total);
  Serial.print(",rx_s1=");
  Serial.print(rx_s1);
  Serial.print(",rx_s2=");
  Serial.print(rx_s2);
  Serial.print(",invalid=");
  Serial.print(invalid_packets);
  Serial.print(",queue_drops=");
  Serial.println(queue_drops);
}

void processQueuedPacket(const QueuedPacket& queued) {
  const char* error_code = "OK";
  Kx134EspnowPacket packet = {};
  if (!packetIsStructurallyValid(
          reinterpret_cast<const uint8_t*>(&queued.packet),
          sizeof(queued.packet),
          &packet,
          &error_code)) {
    ++invalid_packets;
    printInvalidPacket(error_code, queued.src_addr, queued.packet.sensor_id);
    return;
  }

  if (!validatePacketIdentity(packet, queued.src_addr, &error_code)) {
    ++invalid_packets;
    printInvalidPacket(error_code, queued.src_addr, packet.sensor_id);
    return;
  }

  ++rx_total;
  if (packet.sensor_id == 1) {
    ++rx_s1;
  } else if (packet.sensor_id == 2) {
    ++rx_s2;
  }
  printCsvRow(packet, queued.receiver_t_us);
}

#endif  // KX134_NODE_ROLE_RECEIVER

}  // namespace

void setup() {
  Serial.begin(KX134_SERIAL_BAUD);
  delay(300);
  configureWifiForEspNow();

#if KX134_NODE_ROLE_SENSOR
  printCommonStartupMetadata("sensor");
  printSensorStartupMetadata();

  Wire.begin(KX134_I2C_SDA, KX134_I2C_SCL);
  Wire.setClock(KX134_I2C_FREQ_HZ);
  printI2cProbe();

  sensor_ready = initializeSensor();
  if (sensor_ready) {
    Serial.print("# detected_i2c_address=0x");
    Serial.println(detected_address, HEX);
  } else {
    printSensorInitError();
  }

  espnow_ready = initializeEspNowSensor();
  next_sample_us = micros();
#endif

#if KX134_NODE_ROLE_RECEIVER
  printCommonStartupMetadata("receiver");
  if (initializeEspNowReceiver()) {
    Serial.println("# receiver_status=ESPNOW_READY");
  } else {
    Serial.println("# receiver_status=ESPNOW_INIT_FAILED");
  }
  printCsvHeader();
#endif
}

void loop() {
#if KX134_NODE_ROLE_SENSOR
  const uint32_t now_ms = millis();
  if (now_ms - last_status_ms >= 2000) {
    last_status_ms = now_ms;
    printSensorStatus();
  }

  if (!sensor_ready) {
    delay(1000);
    sensor_ready = initializeSensor();
    if (sensor_ready) {
      Serial.print("# detected_i2c_address=0x");
      Serial.println(detected_address, HEX);
      next_sample_us = micros();
    } else {
      printSensorInitError();
    }
    return;
  }

  if (!espnow_ready) {
    delay(1000);
    espnow_ready = initializeEspNowSensor();
    return;
  }

  const uint32_t now_us = micros();
  if (static_cast<int32_t>(now_us - next_sample_us) < 0) {
    return;
  }

  rawOutputData raw_data = {};
  const bool ok = kxAccel.getRawAccelData(&raw_data);
  const uint32_t sensor_t_us = micros();
  if (ok) {
    Kx134EspnowPacket packet = {};
    fillPacket(packet, raw_data, sensor_t_us);
    const esp_err_t send_result = esp_now_send(kReceiverMac, reinterpret_cast<uint8_t*>(&packet), sizeof(packet));
    if (send_result != ESP_OK) {
      ++send_fail;
    }
    ++sequence_id;
  } else {
    Serial.println("# warning=SENSOR_READ_ERROR");
  }

  next_sample_us += kSamplePeriodUs;
  const uint32_t after_us = micros();
  if (static_cast<int32_t>(after_us - next_sample_us) > static_cast<int32_t>(kSamplePeriodUs * 4)) {
    Serial.println("# warning=sampling_resync_after_severe_lag");
    next_sample_us = after_us + kSamplePeriodUs;
  }
#endif

#if KX134_NODE_ROLE_RECEIVER
  QueuedPacket queued = {};
  while (queuePop(queued)) {
    processQueuedPacket(queued);
  }

  const uint32_t now_ms = millis();
  if (now_ms - last_status_ms >= 2000) {
    last_status_ms = now_ms;
    printReceiverStatus();
  }
#endif
}
