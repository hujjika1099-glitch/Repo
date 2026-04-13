#pragma once

#include <stdint.h>

namespace phase14b {

// Bring-up minimo: broadcast evita editar MACs para la primera prueba 1 sensor + 1 relay.
// Cuando pasemos a endurecimiento o a multiples sensores, cambiar a false y definir una MAC
// unicast especifica del receptor.
constexpr bool kUseBroadcastPeer = true;
constexpr uint8_t kPeerMac[6] = {0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

// Identidad explicita por sensor fisico. Para el segundo transmisor usar kSensorId=2 y
// kSensorLabel="sensor_A" en la copia que vayas a subir a esa ESP32.
constexpr uint8_t kSensorId = 1;
constexpr char kSensorLabel[] = "sensor_B";
constexpr uint8_t kPrimarySensorId = 1;
constexpr uint8_t kSecondarySensorId = 2;
constexpr uint8_t kTransportVersion = 2;

constexpr uint32_t kStatusPrintIntervalMs = 5000;
constexpr size_t kReceiverQueueCapacity = 64;

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

}  // namespace phase14b
