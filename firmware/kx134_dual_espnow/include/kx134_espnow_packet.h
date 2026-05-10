#pragma once

#include <Arduino.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

constexpr uint16_t KX134_ESPNOW_MAGIC = 0x4B58;  // "KX"
constexpr uint8_t KX134_ESPNOW_PACKET_VERSION = 1;
constexpr size_t KX134_CALIBRATION_ID_LEN = 32;
constexpr size_t KX134_FIRMWARE_VERSION_LEN = 32;
constexpr size_t KX134_CONTRACT_VERSION_LEN = 16;

struct __attribute__((packed)) Kx134EspnowPacket {
  uint16_t magic;
  uint8_t packet_version;
  uint8_t packet_size;
  uint8_t sensor_id;
  uint8_t node_mac[6];
  uint32_t seq;
  uint32_t sensor_t_us;
  int16_t x_raw;
  int16_t y_raw;
  int16_t z_raw;
  float x_g;
  float y_g;
  float z_g;
  uint16_t sample_rate_hz;
  uint16_t odr_hz;
  uint8_t range_g;
  uint8_t calibration_applied;
  char calibration_id[KX134_CALIBRATION_ID_LEN];
  char firmware_version[KX134_FIRMWARE_VERSION_LEN];
  char contract_version[KX134_CONTRACT_VERSION_LEN];
  uint16_t checksum;
};

static_assert(sizeof(Kx134EspnowPacket) <= 240, "Kx134EspnowPacket must fit ESP-NOW payload");

inline void formatMac(const uint8_t* mac, char* out, size_t out_len) {
  if (!mac || !out || out_len < 18) {
    return;
  }
  snprintf(
      out,
      out_len,
      "%02X:%02X:%02X:%02X:%02X:%02X",
      mac[0],
      mac[1],
      mac[2],
      mac[3],
      mac[4],
      mac[5]);
}

inline bool macEquals(const uint8_t* lhs, const uint8_t* rhs) {
  return lhs && rhs && memcmp(lhs, rhs, 6) == 0;
}

inline bool macIsEmpty(const uint8_t* mac) {
  if (!mac) {
    return true;
  }
  for (size_t i = 0; i < 6; ++i) {
    if (mac[i] != 0) {
      return false;
    }
  }
  return true;
}

inline uint16_t checksum16(const uint8_t* data, size_t len) {
  uint16_t checksum = 0xA5A5;
  for (size_t i = 0; i < len; ++i) {
    checksum = static_cast<uint16_t>((checksum << 5) | (checksum >> 11));
    checksum = static_cast<uint16_t>(checksum + data[i]);
  }
  return checksum;
}

inline uint16_t packetChecksum(const Kx134EspnowPacket& packet) {
  return checksum16(
      reinterpret_cast<const uint8_t*>(&packet),
      offsetof(Kx134EspnowPacket, checksum));
}

inline void copyFixedString(char* dest, size_t dest_len, const char* src) {
  if (!dest || dest_len == 0) {
    return;
  }
  memset(dest, 0, dest_len);
  if (!src) {
    return;
  }
  strncpy(dest, src, dest_len - 1);
}

inline bool packetIsStructurallyValid(
    const uint8_t* data,
    int len,
    Kx134EspnowPacket* out_packet,
    const char** error_code) {
  if (error_code) {
    *error_code = "OK";
  }
  if (!data || len != static_cast<int>(sizeof(Kx134EspnowPacket))) {
    if (error_code) {
      *error_code = "BAD_PACKET_SIZE";
    }
    return false;
  }

  Kx134EspnowPacket packet = {};
  memcpy(&packet, data, sizeof(packet));

  if (packet.magic != KX134_ESPNOW_MAGIC) {
    if (error_code) {
      *error_code = "BAD_MAGIC";
    }
    return false;
  }
  if (packet.packet_version != KX134_ESPNOW_PACKET_VERSION) {
    if (error_code) {
      *error_code = "BAD_PACKET_VERSION";
    }
    return false;
  }
  if (packet.packet_size != sizeof(Kx134EspnowPacket)) {
    if (error_code) {
      *error_code = "BAD_PACKET_SIZE_FIELD";
    }
    return false;
  }
  if (packet.sensor_id != 1 && packet.sensor_id != 2) {
    if (error_code) {
      *error_code = "BAD_SENSOR_ID";
    }
    return false;
  }
  if (macIsEmpty(packet.node_mac)) {
    if (error_code) {
      *error_code = "MISSING_NODE_MAC";
    }
    return false;
  }
  if (packet.checksum != packetChecksum(packet)) {
    if (error_code) {
      *error_code = "BAD_CHECKSUM";
    }
    return false;
  }

  if (out_packet) {
    *out_packet = packet;
  }
  return true;
}
