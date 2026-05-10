# Integracion GUI del stream Serial KX134 v3

## Objetivo

Este documento describe la primera integracion del stream Serial KX134 v3 en la
aplicacion Python, sin reemplazar el flujo historico ADXL335.

El alcance de este ticket agrega un modo KX134 separado para:

- reconocer filas KX134 v3 de 27 campos;
- rechazar filas incompletas o con campos ADXL335 prohibidos;
- conservar datos crudos digitales y aceleracion en g tal como llegan del receptor;
- exportar CSV/JSON/resumen propios para KX134;
- validar el core con replay de logs reales de TICKET 014.

## Diferencia ADXL335 vs KX134

ADXL335 es analogico y su flujo historico usa `mv_x`, `mv_y`, `mv_z` y columnas
estimadas `gx_est`, `gy_est`, `gz_est`, `g_norm_est`.

KX134 es digital. El contrato KX134 v3 usa:

- `x_raw`, `y_raw`, `z_raw` como cuentas digitales;
- `x_g`, `y_g`, `z_g` como aceleracion calibrada/reportada;
- identidad explicita `sensor_id`, `node_id`, `node_mac`;
- tiempos `sensor_t_us`, `receiver_t_us`, `pc_wall_s`;
- diagnosticos `packet_status` y `packet_error_code`.

En modo KX134 no se acepta ni se exporta `mv_*`, `gx_est`, `gy_est`, `gz_est` ni
`g_norm_est`. La norma g puede calcularse solo para resumen interno.

## Duracion, frecuencia y baudrate

El modo KX134 permite duracion manual en segundos. Valores como `10` y `1567`
son validos si son positivos.

La frecuencia esperada se selecciona entre:

- 100 Hz;
- 200 Hz;
- 400 Hz;
- 800 Hz.

El valor por defecto es 100 Hz. El baudrate KX134 por defecto es 921600.

Por ahora la GUI/core no envia comandos de configuracion al firmware. Si el
stream reporta una frecuencia diferente a la esperada, la sesion se marca con
advertencia en metadata.

## Parser y reglas de identidad

El parser KX134 vive en `gui/kx134_live_core.py` y usa el contrato de
`gui/kx134_stream_contract.py`.

Reglas principales:

- no inferir `sensor_id`;
- `sensor_id` debe ser 1 o 2;
- `node_mac` debe estar presente;
- el contrato debe ser `kx134.v3`;
- las filas deben tener exactamente 27 campos;
- filas ADXL335 de 8 o 9 campos se rechazan;
- `sample_rate_hz` debe ser 100, 200, 400 u 800;
- `range_g` debe ser 8, 16, 32 o 64.

## Rutas de salida

En captura real, el core exporta por defecto:

- `data/raw/kx134_dual_live/` para CSV KX134 crudo;
- `data/processed/kx134_dual_live/` para metadata JSON;
- `reports/analysis_outputs/kx134_dual_live/` para resumen.

Las pruebas de replay usan artefactos temporales fuera del repo para no
commitear capturas derivadas innecesarias. El resultado de validacion queda en:

- `reports/kx134_gui_validation/TICKET_015_replay_validation_output.json`;
- `reports/kx134_gui_validation/TICKET_015_GUI_KX134_VALIDATION_SUMMARY.md`.

## Replay sin hardware

La herramienta:

```powershell
python tools/kx134/replay_kx134_log_to_core.py --log reports/kx134_test_runs/TICKET_014_static_receiver_monitor_20260510_112712.txt --output-root reports/kx134_gui_validation --session-name ticket015_static_replay --expected-sample-rate 100
```

lee un log real, ejecuta el parser KX134, exporta una sesion simulada en un
directorio temporal y deja el JSON/resumen de validacion en `reports/`.

## Limitaciones

- No se envia configuracion de frecuencia al firmware todavia.
- La validacion con hardware real desde la GUI queda para el siguiente ticket.
- La GUI profesional adaptable queda para un ticket posterior.
- El empaquetado Windows queda pendiente.
- `pc_wall_s` se calcula en el core durante captura real; en replay se conserva
  el valor del log porque no hay reloj de captura PC en vivo.
