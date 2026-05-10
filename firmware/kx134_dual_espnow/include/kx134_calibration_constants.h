#pragma once

#include <stdint.h>

struct Kx134Calibration {
  uint8_t sensor_id;
  const char* calibration_id;
  float offset_x_g;
  float offset_y_g;
  float offset_z_g;
  float scale_x;
  float scale_y;
  float scale_z;
};

constexpr Kx134Calibration kSensor1Calibration = {
    1,
    "kx134_sensor_1_20260508_234831",
    0.001829774f,
    0.014980432f,
    0.023315356f,
    1.000818311f,
    1.011697845f,
    0.998249154f};

constexpr Kx134Calibration kSensor2Calibration = {
    2,
    "kx134_sensor_2_20260509_180839",
    -0.006147645f,
    0.042897817f,
    0.013735654f,
    0.993155216f,
    1.004679685f,
    0.997042002f};

inline const Kx134Calibration* calibrationForSensor(uint8_t sensor_id) {
  if (sensor_id == 1) {
    return &kSensor1Calibration;
  }
  if (sensor_id == 2) {
    return &kSensor2Calibration;
  }
  return nullptr;
}

inline float rawToUncalibratedG(int16_t raw_value, uint8_t range_g) {
  return static_cast<float>(raw_value) * static_cast<float>(range_g) / 32768.0f;
}

inline float calibrateAxisG(float uncalibrated_g, float offset_g, float scale) {
  return (uncalibrated_g - offset_g) * scale;
}

inline float calibratedXG(int16_t raw_value, uint8_t range_g, const Kx134Calibration& calibration) {
  return calibrateAxisG(rawToUncalibratedG(raw_value, range_g), calibration.offset_x_g, calibration.scale_x);
}

inline float calibratedYG(int16_t raw_value, uint8_t range_g, const Kx134Calibration& calibration) {
  return calibrateAxisG(rawToUncalibratedG(raw_value, range_g), calibration.offset_y_g, calibration.scale_y);
}

inline float calibratedZG(int16_t raw_value, uint8_t range_g, const Kx134Calibration& calibration) {
  return calibrateAxisG(rawToUncalibratedG(raw_value, range_g), calibration.offset_z_g, calibration.scale_z);
}
