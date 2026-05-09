# Procedimiento General de Calibracion KX134

## Proposito

Definir el flujo comun para calibrar cada SEN-17589/KX134 por separado usando seis
posiciones estaticas y el contrato Serial KX134 v3.

## Sensores

- Sensor 1: `sensor_id=1`, `KX134_SENSOR_1`, `sensor_node_1`, MAC `D4:E9:F4:E9:8E:1C`, archivo `config/calibrations/kx134_sensor_1.json`.
- Sensor 2: `sensor_id=2`, `KX134_SENSOR_2`, `sensor_node_2`, MAC `D4:E9:F4:C3:37:14`, archivo `config/calibrations/kx134_sensor_2.json`.

Cada sensor conserva coeficientes propios. No compartir calibraciones entre sensores ni
inferir identidad por posicion fisica del cable.

## Configuracion

- Baudrate Serial: `921600`.
- sample_rate_hz: `100`.
- odr_hz: `100`.
- range_g: `8`.
- Firmware esperado: KX134 single-node I2C.

La calibracion solo es valida para esta configuracion. Si cambia `range_g`, repetir la
calibracion.

## Seis Posiciones

Orden obligatorio:

1. `X_POS`: eje +X hacia arriba.
2. `X_NEG`: eje -X hacia arriba.
3. `Y_POS`: eje +Y hacia arriba.
4. `Y_NEG`: eje -Y hacia arriba.
5. `Z_POS`: eje +Z hacia arriba.
6. `Z_NEG`: eje -Z hacia arriba.

El signo medido debe coincidir con la posicion. Si aparece invertido, revisar la
orientacion fisica y repetir; no corregir por software.

## Criterios de Aceptacion

- Minimo 1500 muestras por posicion.
- Identidad completa: `sensor_id`, `physical_label`, `node_id` y `node_mac`.
- `sample_rate_hz=100`, `odr_hz=100`, `range_g=8`.
- `protocol_version=kx134.v3` y `contract_version=kx134.v3`.
- Secuencia preferiblemente sin saltos.
- Frecuencia efectiva entre 98 y 102 Hz para pass.
- `g_norm_mean` entre 0.85 y 1.15.
- `g_norm_std <= 0.05` para pass.
- Sin campos ADXL335/mV.

Si no aparece encabezado pero las filas tienen 27 campos del contrato KX134 v3, se usa
fallback de encabezado y queda registrado en el reporte.

## Formula

Para cada eje:

```text
axis_g_calibrated = (axis_g_uncalibrated - offset_axis_g) * scale_axis
```

Tambien se reportan offset raw y sensibilidad raw en counts/g contra el valor teorico
`4096 counts/g` para rango 8 g.

## Archivos

- Capturas: `reports/kx134_calibration/sensor_<N>/<session_id>/captures/*.csv`
- Resultado: `reports/kx134_calibration/sensor_<N>/<session_id>/calibration_result.json`
- Resumen: `reports/kx134_calibration/sensor_<N>/<session_id>/calibration_summary.md`
- Calibracion final: `config/calibrations/kx134_sensor_<N>.json`
- Mapa actualizado: `config/kx134_node_map.json`

Los datos crudos se preservan en `reports/kx134_calibration/`.
