# Firmware dual ESP-NOW KX134

## Proposito

Este firmware implementa el primer prototipo KX134 con dos ESP32 sensoras y una ESP32 receptora USB. Los sensores leen SEN-17589/KX134 por I2C, aplican calibracion individual y transmiten paquetes binarios por ESP-NOW. La receptora valida identidad y emite Serial CSV bajo el contrato KX134 v3.

## Nodos

| Nodo | Rol | MAC | Firmware env |
|---|---|---|---|
| `sensor_node_1` | Sensor 1 | `D4:E9:F4:E9:8E:1C` | `kx134_sensor_1_espnow` |
| `sensor_node_2` | Sensor 2 | `D4:E9:F4:C3:37:14` | `kx134_sensor_2_espnow` |
| `receiver_esp32` | Receptor Serial USB | `00:4B:12:96:9A:80` | `kx134_receiver_espnow` |

## Configuracion

- `sample_rate_hz=100`
- `odr_hz=100`
- `range_g=8`
- `Serial=921600`
- `ESP-NOW channel=1`
- I2C sensor: SDA `GPIO21`, SCL `GPIO22`, frecuencia `400000 Hz`.

## Paquete ESP-NOW

El paquete esta definido en `firmware/kx134_dual_espnow/include/kx134_espnow_packet.h`. Incluye `magic`, version, tamano, `sensor_id`, MAC del nodo, `seq`, `sensor_t_us`, raw digital, aceleracion calibrada en g, configuracion, `calibration_id`, version de firmware, version de contrato y checksum.

No incluye campos ADXL335, voltajes, milivoltios ni `g_norm`.

## Calibracion aplicada

Los coeficientes de Sensor 1 y Sensor 2 se embeben en `firmware/kx134_dual_espnow/include/kx134_calibration_constants.h`.

Formula:

```text
axis_g_uncalibrated = axis_raw * range_g / 32768.0
axis_g_calibrated = (axis_g_uncalibrated - offset_axis_g) * scale_axis
```

Los valores `x_raw/y_raw/z_raw` se preservan sin alterar.

## Contrato Serial

El receptor emite el encabezado KX134 v3 exacto y una fila por paquete valido. `receiver_t_us` se captura con `micros()` al recibir el paquete. `pc_wall_s` queda en `0` hasta que la GUI KX134 lo complete.

Paquetes invalidos no se convierten en datos: se reportan como lineas `#INVALID`.

## Validacion esperada

Para aprobar el bring-up dual:

- Sensor 1 y Sensor 2 deben aparecer en el stream.
- Las MAC deben coincidir con el node map.
- `seq` debe crecer por sensor.
- `sensor_t_us` debe crecer por sensor.
- `receiver_t_us` debe ser distinto de cero y creciente.
- La frecuencia efectiva por sensor debe estar cerca de 100 Hz.
- `packet_status=OK`, `packet_error_code=OK`, `calibration_applied=true`.
- No deben aparecer campos prohibidos de ADXL335.

La herramienta `tools/kx134/analyze_dual_espnow_log.py` ignora diagnosticos `#`, usa el encabezado KX134 v3 cuando esta presente, descarta 2 s de warm-up posterior al arranque del receptor y reporta duplicados exactos por sensor sin agregarlos al stream original.

## Limitaciones

- No implementa sincronizacion definitiva.
- `pair_seq` es contador de recepcion.
- No modifica la GUI.
- No modifica empaquetado.
- No modifica calibraciones JSON.

## Siguiente paso

TICKET 014 debe ejecutar precheck de sincronizacion dual y prueba de evento comun.
