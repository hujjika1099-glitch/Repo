# Proyecto de Maestria: ADXL335 + ESP32 (Flujo Operativo)

## Estado operativo actual
- `sensor_B`: fuente operativa primaria.
- `sensor_A`: backup operativo.
- `sensor_C`: referencia historica/provisional.
- `sensor_D`: descartado.

## Objetivo vigente
Pasar de validacion de sensor a uso funcional real en vivo:
1. Captura live MATLAB desde serial.
2. Ingesta operativa.
3. Bloque funcional post-ingesta (features + segmentos de movimiento).
4. Preparacion de migracion a transporte ESP-NOW sin romper el parser MATLAB.

## Scripts clave (MATLAB)
- Captura baseline serial:
  - `matlab/calibration/capture_single_sensor_baseline.m`
- Sesion live MATLAB (Fase 14A):
  - `matlab/live/run_sensorB_live_session.m`
  - `matlab/live/parse_adxl335_stream_line.m`
  - `matlab/live/estimate_sensorB_accel_g.m`
- Ingesta operativa:
  - `matlab/analysis/run_sensorB_operational_ingest.m`
- Bloque funcional post-ingesta:
  - `matlab/analysis/run_sensorB_operational_feature_block.m`

## Scripts clave (PowerShell)
- Captura operativa corta:
  - `scripts/run_sensorB_operational_capture.ps1`
- Sesion live (sin abrir configuracion manual):
  - `scripts/run_sensorB_live_session.ps1`

## Modo recomendado para pruebas repetidas (sin abrir muchas instancias)
1. Abrir una sola ventana de MATLAB.
2. Ejecutar:
   - `run('live_session_hub/sensorB_live_prompt_session.m')`
3. En consola MATLAB indicar:
   - duracion,
   - nombre de sesion,
   - prefijo,
   - carpeta de salida,
   - si guardar CSV/MAT.

## Carpeta de apoyo live
- `live_session_hub/`
  - `sensorB_live_prompt_session.m` (launcher interactivo en MATLAB)
  - `matlab_live_session_code.txt` (codigo MATLAB de prueba)
  - `arduino_esp32_firmware_code.txt` (codigo Arduino flasheado actual)

## Contrato 14B (preparacion ESP-NOW)
- `firmware/dual_node_espnow/phase14b_transport_contract.json`
- Regla principal:
  - El receptor por USB debe emitir el mismo CSV:
    - `seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z`
  - Asi MATLAB reutiliza el mismo parser.

## Toolchain
- PlatformIO local:
  - `${env:USERPROFILE}\\.platformio\\penv\\Scripts\\pio.exe`
- Entorno de firmware actual:
  - `firmware/single_node_calibration`
