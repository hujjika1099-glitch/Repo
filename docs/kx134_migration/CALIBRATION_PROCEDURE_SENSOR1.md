# Procedimiento de calibracion KX134 Sensor 1

## Proposito

Este procedimiento calibra el Sensor 1 KX134/SEN-17589 con seis posiciones
estaticas. La salida es un archivo JSON de coeficientes para uso futuro; la
calibracion no se aplica dentro del firmware en este ticket.

## Sensor calibrado

- sensor_id: `1`
- physical_label: `KX134_SENSOR_1`
- node_id: `sensor_node_1`
- MAC ESP32: `D4:E9:F4:E9:8E:1C`
- Direccion I2C validada: `0x1F`

## Configuracion

- Serial baud: `921600`
- sample_rate_hz: `100`
- odr_hz: `100`
- range_g: `8`
- contrato: `kx134.v3`

## Seis posiciones

1. `X_POS`: eje +X hacia arriba.
2. `X_NEG`: eje -X hacia arriba.
3. `Y_POS`: eje +Y hacia arriba.
4. `Y_NEG`: eje -Y hacia arriba.
5. `Z_POS`: eje +Z hacia arriba.
6. `Z_NEG`: eje -Z hacia arriba.

En cada posicion el modulo debe permanecer quieto durante la estabilizacion y
la captura.

## Criterios de aceptacion

- Al menos 1500 muestras por posicion.
- `sensor_id=1`, `physical_label=KX134_SENSOR_1`, `node_id=sensor_node_1`.
- `node_mac=D4:E9:F4:E9:8E:1C`.
- `sample_rate_hz=100`, `odr_hz=100`, `range_g=8`.
- `protocol_version=kx134.v3` y `contract_version=kx134.v3`.
- Frecuencia efectiva entre 98 y 102 Hz para pass, entre 95 y 105 Hz con advertencia.
- `seq` sin saltos para pass; 1 a 3 saltos con advertencia; mas de 3 falla.
- `sensor_t_us` siempre creciente.
- Sin `SENSOR_INIT_ERROR`, sin `SENSOR_READ_ERROR` repetitivo y sin `UNKNOWN_ERROR`.
- `g_norm_mean` entre 0.85 y 1.15.
- `g_norm_std <= 0.05` para pass, hasta 0.10 con advertencia.
- El eje dominante debe coincidir con la posicion y tener el signo esperado.
- No deben aparecer campos ADXL335/mV: `mv_x`, `mv_y`, `mv_z`, `gx_est`,
  `gy_est`, `gz_est`, `g_norm_est` ni variantes de voltage/millivolts.

## Formula de calibracion

Para cada eje:

```text
axis_g_calibrated = (axis_g_uncalibrated - offset_axis_g) * scale_axis
```

Los coeficientes se calculan con:

```text
offset_x_g = (mean_x_g_X_POS + mean_x_g_X_NEG) / 2
scale_x = 2 / (mean_x_g_X_POS - mean_x_g_X_NEG)
```

El mismo patron aplica para `y` y `z`.

Tambien se reportan `offset_*_raw` y `sensitivity_*_counts_per_g`. A rango 8 g,
el valor teorico aproximado es `4096 counts/g`.

## Archivos generados

- `config/calibrations/kx134_sensor_1.json`
- `config/kx134_node_map.json`
- `reports/kx134_calibration/sensor_1/<session_id>/calibration_summary.md`
- `reports/kx134_calibration/sensor_1/<session_id>/calibration_result.json`
- `reports/kx134_calibration/sensor_1/<session_id>/captures/*.csv`

## Limitacion

Esta calibracion solo es valida para `range_g=8`, `sample_rate_hz=100`,
`odr_hz=100` y el montaje fisico usado en la captura. Si cambia el rango, el
firmware de lectura o la placa fisica, se debe repetir el procedimiento.

## Siguiente paso

Cuando el firmware y stream del Sensor 2 esten validados, repetir este mismo
flujo para `sensor_id=2`.
