#pragma once

#include <Arduino.h>
#include <stdint.h>
#include <stdio.h>

namespace phase14b {

constexpr uint32_t kSerialBaud = 115200;
constexpr uint32_t kSampleHz = 100;
constexpr uint32_t kSamplePeriodUs = 1000000UL / kSampleHz;
constexpr uint8_t kWifiChannel = 6;
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
