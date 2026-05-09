#include <Arduino.h>
#include <SparkFun_KX13X.h>
#include <WiFi.h>
#include <Wire.h>

#ifndef KX134_SENSOR_ID
#define KX134_SENSOR_ID 1
#endif

#ifndef KX134_SAMPLE_RATE_HZ
#define KX134_SAMPLE_RATE_HZ 100
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

#if (KX134_SENSOR_ID != 1) && (KX134_SENSOR_ID != 2)
#error "KX134_SENSOR_ID must be 1 or 2"
#endif

#if (KX134_SAMPLE_RATE_HZ != 100) && (KX134_SAMPLE_RATE_HZ != 200) && \
    (KX134_SAMPLE_RATE_HZ != 400) && (KX134_SAMPLE_RATE_HZ != 800)
#error "KX134_SAMPLE_RATE_HZ must be 100, 200, 400, or 800"
#endif

#if (KX134_RANGE_G != 8) && (KX134_RANGE_G != 16) && (KX134_RANGE_G != 32) && \
    (KX134_RANGE_G != 64)
#error "KX134_RANGE_G must be 8, 16, 32, or 64"
#endif

namespace {

constexpr const char* kProtocolVersion = "kx134.v3";
constexpr const char* kSessionId = "NODE_PROTOTYPE";
constexpr const char* kFirmwareVersion = "kx134_single_node_i2c.0.1.0";
constexpr uint32_t kSamplePeriodUs = 1000000UL / KX134_SAMPLE_RATE_HZ;
constexpr uint8_t kPrimaryAddress = 0x1F;
constexpr uint8_t kSecondaryAddress = 0x1E;

SparkFun_KX134 kxAccel;
uint8_t detected_address = 0;
uint32_t sequence_id = 0;
uint32_t next_sample_us = 0;
char node_mac[18] = "00:00:00:00:00:00";

const char* physicalLabel() {
  return (KX134_SENSOR_ID == 1) ? "KX134_SENSOR_1" : "KX134_SENSOR_2";
}

const char* nodeId() {
  return (KX134_SENSOR_ID == 1) ? "sensor_node_1" : "sensor_node_2";
}

const char* calibrationId() {
  return (KX134_SENSOR_ID == 1) ? "UNCALIBRATED_SENSOR_1" : "UNCALIBRATED_SENSOR_2";
}

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
#if KX134_SAMPLE_RATE_HZ == 100
  return 7;
#elif KX134_SAMPLE_RATE_HZ == 200
  return 8;
#elif KX134_SAMPLE_RATE_HZ == 400
  return 9;
#else
  return 10;
#endif
}

float rawToG(int16_t raw_value) {
  return static_cast<float>(raw_value) * static_cast<float>(KX134_RANGE_G) / 32768.0f;
}

void cacheMacAddress() {
  uint8_t mac[6] = {};
  WiFi.macAddress(mac);
  snprintf(
      node_mac,
      sizeof(node_mac),
      "%02X:%02X:%02X:%02X:%02X:%02X",
      mac[0],
      mac[1],
      mac[2],
      mac[3],
      mac[4],
      mac[5]);
}

void printCsvHeader() {
  Serial.println(
      "protocol_version,session_id,sensor_id,physical_label,node_id,node_mac,seq,"
      "sensor_t_us,receiver_t_us,pc_wall_s,sync_group_id,pair_seq,x_raw,y_raw,z_raw,"
      "x_g,y_g,z_g,sample_rate_hz,odr_hz,range_g,calibration_id,calibration_applied,"
      "packet_status,packet_error_code,firmware_version,contract_version");
}

void printStartupMetadata() {
  Serial.println("# firmware=kx134_single_node_i2c");
  Serial.println("# prototype_scope=single_sensor_node_i2c_only");
  Serial.println("# esp_now=not_implemented_in_this_ticket");
  Serial.println("# receiver_t_us_placeholder=0");
  Serial.println("# pc_wall_s_placeholder=0");
  Serial.print("# protocol_version=");
  Serial.println(kProtocolVersion);
  Serial.print("# sensor_id=");
  Serial.println(KX134_SENSOR_ID);
  Serial.print("# physical_label=");
  Serial.println(physicalLabel());
  Serial.print("# node_id=");
  Serial.println(nodeId());
  Serial.print("# node_mac=");
  Serial.println(node_mac);
  Serial.print("# sample_rate_hz=");
  Serial.println(KX134_SAMPLE_RATE_HZ);
  Serial.print("# odr_code=");
  Serial.println(odrCode());
  Serial.print("# range_g=");
  Serial.println(KX134_RANGE_G);
  Serial.print("# i2c_sda=");
  Serial.println(KX134_I2C_SDA);
  Serial.print("# i2c_scl=");
  Serial.println(KX134_I2C_SCL);
  Serial.print("# i2c_freq_hz=");
  Serial.println(KX134_I2C_FREQ_HZ);
  Serial.print("# calibration_id=");
  Serial.println(calibrationId());
}

bool beginAtAddress(uint8_t address) {
  return kxAccel.begin(Wire, address);
}

bool configureSensor() {
  kxAccel.softwareReset();
  delay(30);
  kxAccel.enableAccel(false);
  delay(5);
  kxAccel.setRange(rangeCode());
  kxAccel.setOutputDataRate(odrCode());
  kxAccel.enableDataEngine(true);
  kxAccel.enableAccel(true);
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

void printSampleRow(
    uint32_t sensor_t_us,
    int16_t x_raw,
    int16_t y_raw,
    int16_t z_raw,
    const char* packet_status,
    const char* packet_error_code) {
  Serial.print(kProtocolVersion);
  Serial.print(',');
  Serial.print(kSessionId);
  Serial.print(',');
  Serial.print(KX134_SENSOR_ID);
  Serial.print(',');
  Serial.print(physicalLabel());
  Serial.print(',');
  Serial.print(nodeId());
  Serial.print(',');
  Serial.print(node_mac);
  Serial.print(',');
  Serial.print(sequence_id);
  Serial.print(',');
  Serial.print(sensor_t_us);
  Serial.print(',');
  Serial.print(0);
  Serial.print(',');
  Serial.print(0);
  Serial.print(',');
  Serial.print("NA");
  Serial.print(',');
  Serial.print(0);
  Serial.print(',');
  Serial.print(x_raw);
  Serial.print(',');
  Serial.print(y_raw);
  Serial.print(',');
  Serial.print(z_raw);
  Serial.print(',');
  Serial.print(rawToG(x_raw), 6);
  Serial.print(',');
  Serial.print(rawToG(y_raw), 6);
  Serial.print(',');
  Serial.print(rawToG(z_raw), 6);
  Serial.print(',');
  Serial.print(KX134_SAMPLE_RATE_HZ);
  Serial.print(',');
  Serial.print(KX134_SAMPLE_RATE_HZ);
  Serial.print(',');
  Serial.print(KX134_RANGE_G);
  Serial.print(',');
  Serial.print(calibrationId());
  Serial.print(',');
  Serial.print("false");
  Serial.print(',');
  Serial.print(packet_status);
  Serial.print(',');
  Serial.print(packet_error_code);
  Serial.print(',');
  Serial.print(kFirmwareVersion);
  Serial.print(',');
  Serial.println(kProtocolVersion);
  ++sequence_id;
}

void printReadError(uint32_t sensor_t_us) {
  printSampleRow(sensor_t_us, 0, 0, 0, "UNKNOWN_ERROR", "SENSOR_READ_ERROR");
}

}  // namespace

void setup() {
  Serial.begin(KX134_SERIAL_BAUD);
  delay(300);

  WiFi.mode(WIFI_STA);
  WiFi.disconnect(false, false);
  cacheMacAddress();

  Wire.begin(KX134_I2C_SDA, KX134_I2C_SCL);
  Wire.setClock(KX134_I2C_FREQ_HZ);

  printStartupMetadata();

  if (!initializeSensor()) {
    Serial.println("# packet_status=SENSOR_INIT_ERROR");
    Serial.println("# packet_error_code=SENSOR_INIT_ERROR");
    Serial.println("# fatal=KX134_NOT_DETECTED_AT_0x1F_OR_0x1E");
    printCsvHeader();
    while (true) {
      delay(1000);
    }
  }

  Serial.print("# detected_i2c_address=0x");
  Serial.println(detected_address, HEX);
  printCsvHeader();
  next_sample_us = micros();
}

void loop() {
  const uint32_t now_us = micros();
  if (static_cast<int32_t>(now_us - next_sample_us) < 0) {
    return;
  }

  rawOutputData raw_data = {};
  const bool ok = kxAccel.getRawAccelData(&raw_data);
  const uint32_t sensor_t_us = micros();

  if (ok) {
    printSampleRow(
        sensor_t_us,
        static_cast<int16_t>(raw_data.xData),
        static_cast<int16_t>(raw_data.yData),
        static_cast<int16_t>(raw_data.zData),
        "CALIBRATION_MISSING",
        "CALIBRATION_MISSING");
  } else {
    printReadError(sensor_t_us);
  }

  next_sample_us += kSamplePeriodUs;
  const uint32_t after_us = micros();
  if (static_cast<int32_t>(after_us - next_sample_us) > static_cast<int32_t>(kSamplePeriodUs * 4)) {
    Serial.println("# warning=sampling_resync_after_severe_lag");
    next_sample_us = after_us + kSamplePeriodUs;
  }
}
