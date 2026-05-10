# TICKET 013 - Firmware ESP-NOW KX134 dual

## Objetivo

Crear y validar un firmware KX134 dual con dos nodos sensores por ESP-NOW hacia una ESP32 receptora que retransmite Serial CSV KX134 v3 hacia el PC.

## Rama

`feature/kx134-dual-capture`

## Precondiciones

- Sensor 1 calibrado: `D4:E9:F4:E9:8E:1C`.
- Sensor 2 calibrado: `D4:E9:F4:C3:37:14`.
- Receptor identificado: `00:4B:12:96:9A:80`.
- Ambos sensores configurados a `sample_rate_hz=100`, `odr_hz=100`, `range_g=8`.

## Archivos creados

- `firmware/kx134_dual_espnow/platformio.ini`
- `firmware/kx134_dual_espnow/src/main.cpp`
- `firmware/kx134_dual_espnow/include/kx134_espnow_packet.h`
- `firmware/kx134_dual_espnow/include/kx134_calibration_constants.h`
- `tools/kx134/analyze_dual_espnow_log.py`

## Procedimiento de carga

Compilar los tres entornos:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\pio.ps1 run -d firmware\kx134_dual_espnow -e kx134_sensor_1_espnow
powershell -ExecutionPolicy Bypass -File tools\platformio\pio.ps1 run -d firmware\kx134_dual_espnow -e kx134_sensor_2_espnow
powershell -ExecutionPolicy Bypass -File tools\platformio\pio.ps1 run -d firmware\kx134_dual_espnow -e kx134_receiver_espnow
```

Subir Sensor 1, Sensor 2 y receptor por separado, confirmando el puerto COM antes de cada upload.

## Criterios de aceptacion

- Los tres builds pasan.
- Los tres uploads pasan.
- El receptor emite encabezado CSV KX134 v3.
- El stream contiene `sensor_id=1` y `sensor_id=2`.
- Las MAC de origen coinciden con el node map.
- `seq` y `sensor_t_us` crecen por sensor.
- `receiver_t_us` es distinto de cero.
- Frecuencia efectiva por sensor entre 98 y 102 Hz.
- No aparecen campos ADXL335 prohibidos.
- `READY_FOR_DUAL_SYNC_PRECHECK=YES`.

## Restricciones

- No modificar firmware ADXL335.
- No modificar firmware single-node KX134.
- No modificar calibraciones JSON.
- No modificar GUI.
- No modificar empaquetado.
- No commitear `.pio` ni binarios.

## Resultado esperado

El repositorio queda listo para TICKET 014: precheck de sincronizacion dual KX134 y prueba de evento comun.

## Resultado operativo

- Fecha de validacion: 2026-05-10.
- Sensor 1 upload: COM5, SUCCESS, MAC `D4:E9:F4:E9:8E:1C`.
- Sensor 2 upload: COM5, SUCCESS, MAC `D4:E9:F4:C3:37:14`.
- Receptor upload: COM4, SUCCESS, MAC `00:4B:12:96:9A:80`.
- Log Serial: `reports/kx134_test_runs/TICKET_013_dual_espnow_receiver_monitor_20260510_104746.txt`.
- Analisis: `reports/kx134_test_runs/TICKET_013_dual_espnow_analysis_20260510_105228.json`.
- Decision: `READY_FOR_DUAL_SYNC_PRECHECK=YES`.
- Advertencia registrada: se observaron duplicados exactos ocasionales en el stream Serial; la herramienta los reporta y los deduplica solo para medir continuidad estable.
