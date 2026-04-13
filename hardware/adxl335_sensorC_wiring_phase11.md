# ADXL335 sensor_C Wiring (Phase 11.1)

Fecha: 2026-03-22

## Objetivo
Dejar cableado explicito y compatible con Fase 11.1 (ST minimamente operativo) y futuro Wi-Fi / ESP-NOW.

## Pinout del modulo ADXL335 usado
Header principal:
1. VCC
2. X-OUT
3. Y-OUT
4. Z-OUT
5. GND

Pad lateral separado:
6. ST

## Cableado final recomendado
- VCC -> ESP32 3V3
- GND -> ESP32 GND
- X-OUT -> ESP32 GPIO32 (ADC1_CH4)
- Y-OUT -> ESP32 GPIO33 (ADC1_CH5)
- Z-OUT -> ESP32 GPIO34 (ADC1_CH6)
- ST (pad lateral) -> ESP32 GPIO23 (digital output)

## Justificacion tecnica
1. X/Y/Z quedan en ADC1 para evitar conflicto con Wi-Fi/ESP-NOW (ADC2 no se usa).
2. GPIO34 es input-only pero valido para lectura ADC de Z-OUT.
3. GPIO23 es salida digital estable para conmutar ST por firmware.
4. ST requiere cable dedicado al pad lateral (no esta en header principal).

## Logica de control ST
- ST_OFF: GPIO23 en LOW
- ST_ON: GPIO23 en HIGH
- Arranque seguro: firmware inicializa ST en LOW

## Checklist rapido de operador
1. Confirmar 6 conexiones fisicas.
2. Confirmar que ST llega al pad lateral (no al header principal).
3. Cargar firmware baseline con control ST habilitado.
4. Ejecutar captura ST_OFF/ST_ON con scripts de Fase 11.1.
