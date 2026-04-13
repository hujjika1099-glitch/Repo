# Pinout de Referencia: ADXL335 sensor_C con ESP32

## Modulo exacto usado
- Header principal de 5 pines:
  1. `VCC`
  2. `X-OUT`
  3. `Y-OUT`
  4. `Z-OUT`
  5. `GND`
- Pad lateral separado:
  6. `ST`

Nota: `ST` no viene en el header principal. Para control desde ESP32 requiere cable dedicado al pad lateral.

## Mapeo obligatorio (Fase 11.1)
- `VCC` -> `3V3`
- `GND` -> `GND`
- `X-OUT` -> `GPIO32` (`ADC1_CH4`)
- `Y-OUT` -> `GPIO33` (`ADC1_CH5`)
- `Z-OUT` -> `GPIO34` (`ADC1_CH6`, input-only valido para ADC)
- `ST` (pad lateral) -> `GPIO23` (salida digital dedicada)

## Restricciones tecnicas por Wi-Fi / ESP-NOW futuro
- `X/Y/Z` deben quedar en `ADC1` exclusivamente.
- No usar `ADC2` para salidas analogicas del ADXL335.
- No usar `GPIO34-39` para `ST` porque son input-only.

## Pines ADC2 explicitamente evitados para X/Y/Z
- `GPIO0, GPIO2, GPIO4, GPIO12, GPIO13, GPIO14, GPIO15, GPIO25, GPIO26, GPIO27`

## Logica ST
- `LOW` = `ST_OFF`
- `HIGH` = `ST_ON`
- Firmware debe iniciar con `ST_OFF` al arranque.
