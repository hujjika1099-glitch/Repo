# Fase 14C - Dual Sensor ESP-NOW Multiplex

Fecha: 2026-03-31

## Objetivo
Extender el relay ESP-NOW para soportar dos ESP32 transmisoras con dos ADXL335 distintos, manteniendo trazabilidad por sensor y permitiendo que MATLAB capture ambos streams en una sola sesion.

## Cambio de contrato
- El payload ahora incluye identidad explicita por sensor:
  - `sensor_id_u8`
  - `version_u8`
  - `reserved_u16`
  - `seq_u32`
  - `t_us_u32`
  - `raw_x_u16`
  - `raw_y_u16`
  - `raw_z_u16`
  - `mv_x_u16`
  - `mv_y_u16`
  - `mv_z_u16`
- El receptor USB ahora imprime:
  - `sensor_id,seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z`
- MATLAB se actualiza para aceptar el stream nuevo y separar internamente por `sensor_id`.

## Identidad adoptada
- `sensor_id = 1` -> `sensor_B` (principal)
- `sensor_id = 2` -> `sensor_A` (segundo sensor a evaluar)

## Archivos modificados
- Firmware base:
  - `firmware/dual_node_espnow/include/transport_config.h`
  - `firmware/dual_node_espnow/include/transport_packet.h`
  - `firmware/dual_node_espnow/src/sensor_node_main.cpp`
  - `firmware/dual_node_espnow/src/receiver_node_main.cpp`
- Arduino IDE:
  - `firmware/dual_node_espnow/arduino_ide/sensor_node_espnow/sensor_node_espnow.ino`
  - `firmware/dual_node_espnow/arduino_ide/receiver_node_espnow/receiver_node_espnow.ino`
  - `firmware/dual_node_espnow/arduino_ide/README.md`
- MATLAB:
  - `matlab/live/parse_adxl335_stream_line.m`
  - `matlab/common/resolve_adxl_serial_port.m`
  - `matlab/live/run_sensorB_live_session.m`
  - `live_session_hub/sensorB_live_prompt_session.m`

## Operacion esperada
1. Primer transmisor: cargar firmware con `kSensorId = 1` y `kSensorLabel = "sensor_B"`.
2. Segundo transmisor: cargar la misma logica, pero con `kSensorId = 2` y `kSensorLabel = "sensor_A"`.
3. Receptor USB: cargar `receiver_node`.
4. MATLAB: ejecutar `run('live_session_hub/sensorB_live_prompt_session.m')`.
5. El resumen de sesion debe incluir estado basico del segundo sensor:
   - `pass`
   - `suspect`
   - `fail`

## Verificacion logica del segundo sensor
El script live ahora calcula una verificacion minima de coherencia por sensor usando:
- numero de muestras
- saltos de secuencia
- saturacion ADC
- mediana de `|g|`
- amplitud minima de señal en mV

Esto no reemplaza la validacion fisica por sensor individual, pero sirve como filtro rapido para detectar un segundo sensor manifiestamente incoherente antes de avanzar.
