# ADXL335 Standard Wiring (Fase 12 Fast Bring-Up)

## Objetivo
Estandarizar el cableado para nuevos modulos ADXL335 y evitar retrabajo en cada incorporacion.

## Mapa fijo ADXL335 -> ESP32
| ADXL335 pin | ESP32 pin | Funcion | Nota |
|---|---|---|---|
| VCC | 3V3 | Alimentacion | No usar 5V |
| GND | GND | Referencia comun | Obligatorio |
| X-OUT | GPIO32 (ADC1_CH4) | Analog X | ADC1, compatible con Wi-Fi/ESP-NOW |
| Y-OUT | GPIO33 (ADC1_CH5) | Analog Y | ADC1, compatible con Wi-Fi/ESP-NOW |
| Z-OUT | GPIO34 (ADC1_CH6) | Analog Z | GPIO34 es input-only, valido para ADC |
| ST (pad lateral) | GPIO23 | Control self-test | ST no esta en el header principal |

## Reglas operativas
1. X/Y/Z solo en ADC1.
2. No usar ADC2 para salidas analogicas del ADXL335.
3. ST no debe conectarse a GPIO34-39 (input-only).
4. Firmware debe arrancar con ST en LOW (ST_OFF).
5. En quick bring-up, mantener orientacion fija durante la captura corta.
