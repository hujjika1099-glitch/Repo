#include <Arduino.h>

// ADXL335 (analogico) conectado a una ESP32 de referencia:
// X -> GPIO32, Y -> GPIO33, Z -> GPIO34.
namespace {
constexpr int PIN_X = 32;
constexpr int PIN_Y = 33;
constexpr int PIN_Z = 34;

constexpr uint32_t SERIAL_BAUD = 115200;
constexpr uint32_t SAMPLE_HZ = 100;
constexpr uint32_t SAMPLE_PERIOD_US = 1000000UL / SAMPLE_HZ;

uint32_t sequence = 0;
uint32_t next_sample_us = 0;

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

void print_startup_metadata() {
  Serial.println("# adxl335_single_node_baseline");
  Serial.println("# board=esp32dev");
  Serial.println("# pins:x=GPIO32,y=GPIO33,z=GPIO34");
  Serial.println("# sample_hz=100");
  Serial.println("seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z");
}
}  // namespace

void setup() {
  Serial.begin(SERIAL_BAUD);
  delay(300);

  configure_adc();
  print_startup_metadata();
  next_sample_us = micros();
}

void loop() {
  const uint32_t now = micros();
  if ((int32_t)(now - next_sample_us) < 0) {
    return;
  }

  next_sample_us += SAMPLE_PERIOD_US;
  if ((int32_t)(now - next_sample_us) >= 0) {
    next_sample_us = now + SAMPLE_PERIOD_US;
  }

  const int raw_x = analogRead(PIN_X);
  const int raw_y = analogRead(PIN_Y);
  const int raw_z = analogRead(PIN_Z);

  const uint32_t mv_x = analogReadMilliVolts(PIN_X);
  const uint32_t mv_y = analogReadMilliVolts(PIN_Y);
  const uint32_t mv_z = analogReadMilliVolts(PIN_Z);

  const uint32_t t_us = micros();
  Serial.print(sequence);
  Serial.print(',');
  Serial.print(t_us);
  Serial.print(',');
  Serial.print(raw_x);
  Serial.print(',');
  Serial.print(raw_y);
  Serial.print(',');
  Serial.print(raw_z);
  Serial.print(',');
  Serial.print(mv_x);
  Serial.print(',');
  Serial.print(mv_y);
  Serial.print(',');
  Serial.println(mv_z);

  sequence++;
}
