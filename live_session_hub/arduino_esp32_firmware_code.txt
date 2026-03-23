#include <Arduino.h>
#include <ctype.h>
#include <string.h>

// ADXL335 (analogico) conectado a una ESP32 de referencia:
// X-OUT -> GPIO32 (ADC1_CH4)
// Y-OUT -> GPIO33 (ADC1_CH5)
// Z-OUT -> GPIO34 (ADC1_CH6, input-only ADC)
// ST pad lateral -> GPIO23 (salida digital dedicada)
namespace {
constexpr int PIN_X = 32;
constexpr int PIN_Y = 33;
constexpr int PIN_Z = 34;
constexpr int PIN_ST = 23;

constexpr uint32_t SERIAL_BAUD = 115200;
constexpr uint32_t SAMPLE_HZ = 100;
constexpr uint32_t SAMPLE_PERIOD_US = 1000000UL / SAMPLE_HZ;

uint32_t sequence = 0;
uint32_t next_sample_us = 0;
bool st_enabled = false;

char cmd_buffer[32];
size_t cmd_len = 0;

void set_st_state(const bool enabled) {
  st_enabled = enabled;
  digitalWrite(PIN_ST, enabled ? HIGH : LOW);
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

void print_status() {
  Serial.print("# status st=");
  Serial.print(st_enabled ? "ON" : "OFF");
  Serial.print(" seq=");
  Serial.println(sequence);
}

void process_command(const char* raw_cmd) {
  char cmd[32];
  size_t j = 0;

  for (size_t i = 0; raw_cmd[i] != '\0' && j < sizeof(cmd) - 1; ++i) {
    const char c = raw_cmd[i];
    if (c == ' ' || c == '\t') {
      continue;
    }
    cmd[j++] = static_cast<char>(toupper(static_cast<unsigned char>(c)));
  }
  cmd[j] = '\0';

  if (j == 0) {
    return;
  }

  if (strcmp(cmd, "ST_ON") == 0) {
    set_st_state(true);
    Serial.println("# cmd=ST_ON ack=ok st=ON");
  } else if (strcmp(cmd, "ST_OFF") == 0) {
    set_st_state(false);
    Serial.println("# cmd=ST_OFF ack=ok st=OFF");
  } else if (strcmp(cmd, "STATUS") == 0) {
    print_status();
  } else if (strcmp(cmd, "HELP") == 0) {
    Serial.println("# cmd=HELP ack=ok options=ST_ON,ST_OFF,STATUS,HELP");
  } else {
    Serial.println("# cmd=UNKNOWN ack=error options=ST_ON,ST_OFF,STATUS,HELP");
  }
}

void handle_serial_commands() {
  while (Serial.available() > 0) {
    const char c = static_cast<char>(Serial.read());

    if (c == '\r' || c == '\n') {
      if (cmd_len > 0) {
        cmd_buffer[cmd_len] = '\0';
        process_command(cmd_buffer);
        cmd_len = 0;
      }
      continue;
    }

    if (cmd_len < sizeof(cmd_buffer) - 1) {
      cmd_buffer[cmd_len++] = c;
    } else {
      cmd_len = 0;
      Serial.println("# cmd=OVERFLOW ack=error");
    }
  }
}

void print_startup_metadata() {
  Serial.println("# adxl335_single_node_baseline");
  Serial.println("# board=esp32dev");
  Serial.println("# pins:x=GPIO32,y=GPIO33,z=GPIO34,st=GPIO23");
  Serial.println("# adc_domain:x=ADC1_CH4,y=ADC1_CH5,z=ADC1_CH6");
  Serial.println("# wifi_note:adc2_not_used_for_sensor_outputs");
  Serial.println("# st_logic:LOW=ST_OFF,HIGH=ST_ON");
  Serial.println("# sample_hz=100");
  Serial.println("seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z");
}
}  // namespace

void setup() {
  Serial.begin(SERIAL_BAUD);
  delay(300);

  pinMode(PIN_ST, OUTPUT);
  set_st_state(false);  // Arranque seguro: ST_OFF.
  configure_adc();
  print_startup_metadata();
  print_status();
  next_sample_us = micros();
}

void loop() {
  handle_serial_commands();

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
