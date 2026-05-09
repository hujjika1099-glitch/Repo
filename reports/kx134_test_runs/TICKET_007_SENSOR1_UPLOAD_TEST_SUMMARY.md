# TICKET 007 - Sensor 1 KX134 upload and serial validation

## Fecha

2026-05-09

## Rama

feature/kx134-dual-capture

## Hardware probado

- ESP32 sensora 1.
- SEN-17589 / KX134 por I2C/Qwiic.
- Puerto serial: COM5.
- MAC ESP32 detectada: D4:E9:F4:E9:8E:1C.

## Firmware probado

- Proyecto: firmware/kx134_single_node_i2c.
- Firmware version: kx134_single_node_i2c.0.1.0.
- sensor_id: 1.
- sample_rate_hz: 100.
- odr_hz: 100.
- range_g: 8.
- Serial baud final: 921600.

## Resultado de upload

- Build: SUCCESS.
- Upload asistido con BOOT manual: SUCCESS.
- Chip detectado: ESP32-D0WD-V3 revision v3.1.
- MAC reportada por esptool: d4:e9:f4:e9:8e:1c.

## Resultado I2C

- i2c_probe_0x1F: present.
- i2c_probe_0x1E: missing.
- Direccion detectada por firmware: 0x1F.
- KX134 inicializado correctamente: si.

## Validacion del stream 921600

Archivo de evidencia:

- reports/kx134_test_runs/TICKET_007_sensor1_visible_monitor_921600_20260508_215245.txt

Resultados validados sobre el bloque limpio posterior al header CSV:

- Filas CSV validas: 1436.
- seq inicial: 0.
- seq final: 1435.
- Saltos de seq: 0.
- Timestamps no crecientes: 0.
- Promedio delta sensor_t_us: 9999.96 us.
- Frecuencia efectiva estimada: 100.00 Hz.
- g_norm promedio: 1.0258.
- g_norm minimo: 0.9699.
- g_norm maximo: 1.0784.
- Campos prohibidos ADXL335 detectados: 0.
- Warnings sampling_resync_after_severe_lag en 921600: 0.

## Campos verificados

- protocol_version = kx134.v3.
- session_id = NODE_PROTOTYPE.
- sensor_id = 1.
- physical_label = KX134_SENSOR_1.
- node_id = sensor_node_1.
- node_mac = D4:E9:F4:E9:8E:1C.
- x_raw/y_raw/z_raw presentes.
- x_g/y_g/z_g presentes.
- sample_rate_hz = 100.
- odr_hz = 100.
- range_g = 8.
- calibration_id = UNCALIBRATED_SENSOR_1.
- calibration_applied = false.
- packet_status = CALIBRATION_MISSING.
- packet_error_code = CALIBRATION_MISSING.

## Cambios correctivos aplicados

El firmware single-node se ajusto para mejorar diagnostico de bring-up:

- imprime boot_marker despues de Serial.begin;
- imprime probe I2C en 0x1F y 0x1E;
- conserva diagnostico persistente si el KX134 no inicializa;
- reintenta inicializacion sin quedar silencioso;
- verifica retorno de softwareReset, setRange, setOutputDataRate, enableDataEngine y enableAccel.

## Decision

LISTO_PARA_CALIBRACION_SENSOR_1: si.

Motivo:

- Upload exitoso.
- KX134 detectado por I2C en 0x1F.
- Header CSV correcto.
- sensor_id correcto.
- node_mac valido.
- seq incrementa sin saltos.
- sensor_t_us incrementa.
- Datos crudos y conversion basica a g presentes.
- Frecuencia efectiva validada en 100 Hz a 921600 baudios.
- No hay campos ADXL335 prohibidos.
- Estado CALIBRATION_MISSING es esperado antes de calibrar.

## Advertencias

- La prueba a 115200 baudios fue util para diagnostico visual, pero no soporta el stream completo a 100 Hz y produce retrasos.
- Para pruebas y calibracion KX134 se debe usar 921600 baudios.
- La calibracion de seis posiciones aun no se ha implementado ni ejecutado.
