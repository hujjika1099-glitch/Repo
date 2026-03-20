# Pinout de Referencia: ADXL335 con ESP32

## Conexion base
- Sensor: ADXL335
- VCC -> 3V3
- GND -> GND
- X -> GPIO32
- Y -> GPIO33
- Z -> GPIO34

## Restricciones tecnicas
- No usar ADC2 para esta fase.
- Usar una sola ESP32 de referencia durante la validacion individual por sensor.
