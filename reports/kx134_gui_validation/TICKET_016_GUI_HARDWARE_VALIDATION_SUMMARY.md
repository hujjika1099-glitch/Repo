# TICKET 016 - GUI KX134 hardware validation summary

## Resultado

`READY_FOR_GUI_EXPORT_HARDENING = YES`

La GUI KX134 fue validada con hardware real en `COM4` a `921600` baudios, duracion configurada de `10 s` y frecuencia esperada de `100 Hz`. La captura final exporto una sesion auditable con ambos sensores presentes, encabezado KX134 v3 exacto, sin campos ADXL335 prohibidos, sin duplicados CSV, sin saltos de secuencia y con `pc_wall_s` positivo.

## Configuracion final

- Fecha: `2026-05-10`
- Puerto: `COM4`
- Baudrate: `921600`
- Duracion configurada: `10 s`
- Frecuencia esperada: `100 Hz`
- Rango esperado: `8 g`
- Carpeta de salida final: `reports/kx134_gui_validation/TICKET_016_hw_capture_20260510_124537/`
- Comando GUI:

```powershell
python -m gui.kx134_live_gui --repo-root "reports\kx134_gui_validation\TICKET_016_hw_capture_20260510_124537" --port COM4 --baud 921600 --duration-s 10 --expected-sample-rate 100 --session-name ticket016_hw_gui
```

## Artefactos finales

- CSV raw: `reports/kx134_gui_validation/TICKET_016_hw_capture_20260510_124537/data/raw/kx134_dual_live/kx134_dual_live_ticket016_hw_gui_20260510_124627_raw.csv`
- Metadata JSON: `reports/kx134_gui_validation/TICKET_016_hw_capture_20260510_124537/data/processed/kx134_dual_live/kx134_dual_live_ticket016_hw_gui_20260510_124627_session.json`
- Summary MD: `reports/kx134_gui_validation/TICKET_016_hw_capture_20260510_124537/reports/analysis_outputs/kx134_dual_live/kx134_dual_live_ticket016_hw_gui_20260510_124627_summary.md`
- Validation JSON: `reports/kx134_gui_validation/TICKET_016_gui_hardware_validation_output.json`

## Metricas finales

- Rows Sensor 1: `1001`
- Rows Sensor 2: `999`
- Effective Hz Sensor 1: `100.0`
- Effective Hz Sensor 2: `100.00002004008418`
- Seq gaps Sensor 1: `0`
- Seq gaps Sensor 2: `0`
- Timestamp errors Sensor 1: `0`
- Timestamp errors Sensor 2: `0`
- Receiver timestamp errors Sensor 1: `0`
- Receiver timestamp errors Sensor 2: `0`
- Receiver_t_us valido: `true`
- Pc_wall_s positivo: `true`
- Invalid lines: `0`
- Duplicate keys Sensor 1: `0`
- Duplicate keys Sensor 2: `0`
- Packet status counts: `{"OK": 2000}`
- Packet error code counts: `{"OK": 2000}`
- Campos prohibidos detectados: `false`
- CSV header exacto KX134 v3: `true`

## Validacion de controles

- Duracion `10`: valida.
- Duracion `1567`: valida.
- Frecuencias `100`, `200`, `400`, `800`: validas.
- Frecuencias `500`, `1000`: rechazadas.

## Diagnostico durante la prueba

- Primer intento GUI: abrio y exporto artefactos, pero con `0` muestras por sensor.
- Prueba directa posterior: `0` lineas en COM4.
- Solucion operativa: reset fisico del receptor con boton `EN/RST`.
- Prueba directa tras reset: `2341` lineas en `12 s`, con metadata de receptor y CSV KX134 v3.
- Bugfix acotado KX134:
  - se agrego warmup interno de `2 s` al abrir puerto serial para absorber reinicio/arranque del receptor;
  - se cambio el cronometro de captura a `time.perf_counter()` para que `pc_wall_s` no quede aplastado a cero por resolucion de reloj en Windows;
  - se aumento la precision exportada de `pc_wall_s`.

## Restricciones verificadas

- Firmware no modificado.
- Calibraciones no modificadas.
- Firmware ADXL335 no modificado.
- Empaquetado no modificado.
- Data historica no modificada.
- GUI ADXL335 preservada.
- No se hizo analisis profundo de vibracion.
- No se creo ejecutable.

## Pendientes

- Redisenio visual profesional de la GUI.
- Endurecimiento de exportacion KX134 y metadata.
- Empaquetado Windows.
- Envio de configuracion de sample rate al firmware.
