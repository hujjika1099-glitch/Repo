# TICKET 010 - KX134 Sensor 2 Upload y Validacion Serial

Fecha/hora: 2026-05-09 17:41 America/Bogota
Rama: `feature/kx134-dual-capture`
Puerto usado: `COM5`
Baudrate: `921600`
Firmware: `kx134_single_node_i2c.0.1.0`

## Resultado

`READY_FOR_SENSOR_2_CALIBRATION = YES`

Sensor 2 quedo con firmware diferenciado por entorno PlatformIO `kx134_sensor_2`, salida Serial KX134 v3 valida y estado `bringup_validated_pending_calibration` en `config/kx134_node_map.json`.

## Identidad Validada

- sensor_id: `2`
- physical_label: `KX134_SENSOR_2`
- node_id: `sensor_node_2`
- node_mac: `D4:E9:F4:C3:37:14`
- direccion I2C detectada: no capturada en el log final porque el monitor entro con el firmware ya transmitiendo muestras; el stream de datos es valido.
- sample_rate_hz: `100`
- odr_hz: `100`
- range_g: `8`
- calibration_id: `UNCALIBRATED_SENSOR_2`
- calibration_applied: `false`
- packet_status: `CALIBRATION_MISSING`
- packet_error_code: `CALIBRATION_MISSING`
- contract_version: `kx134.v3`

## Evidencia Serial

Archivo principal:

`reports/kx134_test_runs/TICKET_010_sensor2_visible_monitor_20260509_174138.txt`

La captura contiene filas CSV limpias de 27 campos compatibles con el contrato KX134 v3. El encabezado textual no quedo en esta ventana de captura porque el monitor empezo cuando el firmware ya estaba emitiendo datos.

Encabezado esperado por contrato:

```text
protocol_version,session_id,sensor_id,physical_label,node_id,node_mac,seq,sensor_t_us,receiver_t_us,pc_wall_s,sync_group_id,pair_seq,x_raw,y_raw,z_raw,x_g,y_g,z_g,sample_rate_hz,odr_hz,range_g,calibration_id,calibration_applied,packet_status,packet_error_code,firmware_version,contract_version
```

Primeras muestras limpias:

```text
kx134.v3,NODE_PROTOTYPE,2,KX134_SENSOR_2,sensor_node_2,D4:E9:F4:C3:37:14,27125,271776915,0,0,NA,0,299,-210,4188,0.072998,-0.051270,1.022461,100,100,8,UNCALIBRATED_SENSOR_2,false,CALIBRATION_MISSING,CALIBRATION_MISSING,kx134_single_node_i2c.0.1.0,kx134.v3
kx134.v3,NODE_PROTOTYPE,2,KX134_SENSOR_2,sensor_node_2,D4:E9:F4:C3:37:14,27126,271786915,0,0,NA,0,266,-211,4182,0.064941,-0.051514,1.020996,100,100,8,UNCALIBRATED_SENSOR_2,false,CALIBRATION_MISSING,CALIBRATION_MISSING,kx134_single_node_i2c.0.1.0,kx134.v3
kx134.v3,NODE_PROTOTYPE,2,KX134_SENSOR_2,sensor_node_2,D4:E9:F4:C3:37:14,27127,271796915,0,0,NA,0,275,-219,4148,0.067139,-0.053467,1.012695,100,100,8,UNCALIBRATED_SENSOR_2,false,CALIBRATION_MISSING,CALIBRATION_MISSING,kx134_single_node_i2c.0.1.0,kx134.v3
```

## Metricas

- filas CSV limpias: `1902`
- filas mal formadas: `0`
- seq inicial: `27125`
- seq final: `29026`
- seq_gaps: `0`
- timestamp_errors: `0`
- frecuencia efectiva: `100.000 Hz`
- g_norm promedio: `1.021050`
- g_norm minimo: `0.935406`
- g_norm maximo: `1.109147`
- mean_x_g: `0.068351`
- mean_y_g: `-0.054607`
- mean_z_g: `1.017113`
- campos prohibidos detectados: `false`
- errores repetitivos detectados: `false`

## Validacion

- Identidad Sensor 2: pass.
- Configuracion 100 Hz / 8 g: pass.
- Secuencia sin saltos: pass.
- Timestamps crecientes: pass.
- Frecuencia efectiva 98-102 Hz: pass.
- Norma en reposo 0.85-1.15 g: pass.
- Campos ADXL335/mV prohibidos: pass.

Advertencia operativa:

- El primer intento de monitor no mostro datos por un problema de invocacion/captura de consola, no por fallo de cableado.
- El log final no contiene diagnostico de arranque ni encabezado textual; se valido por filas de datos completas y consistentes con el contrato KX134 v3.

## Restricciones Verificadas

- No se calibro Sensor 2.
- No se creo `config/calibrations/kx134_sensor_2.json`.
- No se modifico `config/calibrations/kx134_sensor_1.json`.
- No se modificaron reportes de calibracion de Sensor 1.
- No se modifico GUI.
- No se modifico empaquetado.
- No se modifico data historica.
- No se aplico calibracion en firmware.
