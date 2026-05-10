# Referencia de archivos exportados KX134

## CSV raw KX134 v3

El CSV raw conserva el contrato KX134 v3. Columnas principales:

- `sensor_id`: 1 o 2.
- `node_mac`: MAC del nodo sensor.
- `seq`: contador de secuencia.
- `sensor_t_us`: timestamp del nodo sensor.
- `receiver_t_us`: timestamp del Receptor.
- `pc_wall_s`: tiempo relativo en el PC.
- `x_raw/y_raw/z_raw`: lecturas crudas.
- `x_g/y_g/z_g`: aceleracion calibrada en g.
- `sample_rate_hz`: frecuencia reportada por firmware.
- `odr_hz`: ODR del sensor.
- `range_g`: rango configurado, validado en `8 g`.
- `calibration_id`: identidad de calibracion aplicada.
- `calibration_applied`: true si se aplico calibracion.
- `packet_status`: debe ser OK.
- `packet_error_code`: debe ser OK.

## Session JSON

El JSON de sesion contiene:

- Identidad de sesion.
- Configuracion de captura: puerto, `921600`, `100 Hz`, `8 g`.
- Nodos esperados: Sensor 1, Sensor 2 y Receptor.
- Resumen de captura.
- Conteos por sensor.
- Rutas de artefactos.
- Estado de validacion.

## Summary MD

El summary MD es una version legible para revision rapida:

- Tabla por Sensor 1 y Sensor 2.
- Frecuencia efectiva.
- `seq_gaps`.
- `invalid_lines`.
- `duplicate_keys`.
- `packet_status`.
- `packet_error_code`.
- Rutas de CSV, JSON y summary.

## Campos prohibidos en CSV KX134

El CSV KX134 no debe incluir:

- `mv_*`.
- Voltajes o millivolts.
- `gx_est/gy_est/gz_est`.
- `g_norm` como columna.
- `g_norm_est`.

`|g|` puede usarse solo como ayuda visual o metrica interna de resumen, nunca como columna CSV de datos crudos.

## Advertencias de interpretacion

- El prototipo fue validado a `100 Hz`, `921600` y `8 g`.
- Si cambia `range_g`, recalibrar.
- `PCB_DESIGN_AUTHORIZED = NO`; la PCB no autorizada no afecta la lectura de estos archivos, pero bloquea baquelada final.
