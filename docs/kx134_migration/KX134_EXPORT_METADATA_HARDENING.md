# KX134 export metadata hardening

## Objetivo

El modo KX134 de la GUI exporta sesiones auditables para la arquitectura:

- Sensor 1 KX134 -> ESP-NOW -> receptor ESP32.
- Sensor 2 KX134 -> ESP-NOW -> receptor ESP32.
- Receptor ESP32 -> USB Serial -> GUI Python.

Este endurecimiento no cambia el CSV KX134 v3. El cambio principal está en el JSON de sesión y en el summary MD, que ahora incluyen metadata suficiente para validar y transportar un bundle fuera de la máquina original.

## Bundle KX134

Una sesión KX134 queda formada por tres artefactos:

- `data/raw/kx134_dual_live/*_raw.csv`
- `data/processed/kx134_dual_live/*_session.json`
- `reports/analysis_outputs/kx134_dual_live/*_summary.md`

El CSV raw conserva exactamente el encabezado KX134 v3 y no agrega métricas internas como `g_norm`.

## CSV raw

El CSV debe contener 27 campos:

`protocol_version, session_id, sensor_id, physical_label, node_id, node_mac, seq, sensor_t_us, receiver_t_us, pc_wall_s, sync_group_id, pair_seq, x_raw, y_raw, z_raw, x_g, y_g, z_g, sample_rate_hz, odr_hz, range_g, calibration_id, calibration_applied, packet_status, packet_error_code, firmware_version, contract_version`

Campos ADXL335/mV prohibidos:

- `mv_x`, `mv_y`, `mv_z`
- `gx_est`, `gy_est`, `gz_est`, `g_norm_est`
- `g_norm`
- `voltage`, `millivolts`

## Session JSON

La metadata endurecida incluye:

- Identidad de sesión: `session_id`, `session_name`, `session_type`, `protocol_version`, `contract_version`.
- Tiempos: `created_at_iso`, `started_at_iso`, `ended_at_iso`, duración solicitada y duración real.
- Configuración: puerto, baudrate, frecuencia esperada, rango esperado, ODR esperado y warmup serial.
- Arquitectura: versión de topología, tres ESP32 requeridas y transporte ESP-NOW/USB Serial.
- Identidad esperada de Sensor 1, Sensor 2 y receptor.
- Resumen de muestras, gaps, timestamps, duplicados, estados de paquete y campos prohibidos.
- Rutas absolutas por conveniencia y rutas relativas a la carpeta raíz de sesión para portabilidad.

La GUI todavía no envía configuración de frecuencia al firmware. Por eso el JSON fija:

- `firmware_configuration_sent = false`
- `firmware_configuration_note = "GUI does not configure firmware sample rate yet."`

## Summary MD

El summary incluye:

- tabla por sensor;
- filas por sensor;
- frecuencia efectiva;
- `seq_gaps`;
- errores de timestamp;
- duplicados;
- `invalid_lines`;
- conteos `packet_status` y `packet_error_code`;
- artefactos relativos;
- decisión de validez de sesión.

## Validación

Comando principal:

```powershell
python tools\kx134\validate_kx134_export_bundle.py --session-json "<SESSION_JSON>" --raw-csv "<RAW_CSV>" --summary-md "<SUMMARY_MD>" --output reports\kx134_gui_validation\TICKET_017_export_bundle_validation_output.json --expected-sample-rate 100 --expected-range-g 8 --min-rows-per-sensor 500
```

Criterios clave:

- `pass=true`
- encabezado CSV exacto KX134 v3;
- ambos sensores con filas suficientes;
- frecuencia efectiva compatible con 100 Hz;
- `pc_wall_s` positivo;
- `receiver_t_us` positivo;
- metadata schema pass;
- rutas relativas presentes;
- sin campos ADXL335/mV prohibidos.

## Limitaciones

- El firmware no se configura desde la GUI todavía.
- El rediseño visual profesional queda pendiente.
- El empaquetado Windows queda pendiente.
- Los bundles previos al endurecimiento pueden validar el CSV, pero fallar por metadata legacy.
