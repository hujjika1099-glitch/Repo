# Fase 6: MATLAB Capture Baseline (Single Sensor)

Fecha: 2026-03-20

## Parametros de sesion
- port: `COM5`
- baud: `115200`
- sensor_id: `sensor_A`
- pose_label: `z_plus_static`
- duracion solicitada: `12.0 s`

## Resultado de ejecucion
- Intento 1:
  - bloqueado por compatibilidad de `array2table` (nombres de variables).
  - correccion minima aplicada y reintento unico.
- Intento 2:
  - `CAPTURE_OK`.

## Archivos generados
- CSV:
  - `data/raw/sensor_A/sensor_A_z_plus_static_20260320_132709.csv`
- Metadatos de sesion:
  - `data/raw/sensor_A/sensor_A_z_plus_static_20260320_132709_session.txt`

## Resumen de captura real
- duracion real (wall): `12.005 s`
- duracion real (stream): `11.979 s`
- muestras capturadas: `1199`
- frecuencia estimada: `100.007 Hz`
- seq_jumps: `0`
- invalid_lines_ignored: `0`
- metadata detectada: `true` (`# adxl335_single_node_baseline`, `# board=esp32dev`, `# pins=...`, `# sample_hz=100`)

## Verificacion de formato
- Header esperado y observado:
  - `seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z`
- Filas de muestra reales capturadas y parseadas correctamente.

## Decision operativa
- `matlab_capture_ok`
