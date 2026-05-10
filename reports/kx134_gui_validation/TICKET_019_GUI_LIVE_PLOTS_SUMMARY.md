# TICKET 019 - GUI live plots KX134 summary

## Fecha

2026-05-10

## Commit base

`abe5135` - `gui: redesign KX134 interface for responsive layout`

## Cambios implementados

- Panel `Graficas` en la GUI KX134.
- Buffer visual por sensor con ventana configurable de 10, 20, 30 o 60 segundos.
- Graficas Canvas/Tkinter sin dependencias nuevas.
- Eventos live del core:
  - `sample_batch`
  - `capture_progress`
  - `session_complete`
  - `session_error`
- Smoke test con muestras sinteticas.

## Patron reutilizado

Se audito la GUI ADXL335 historica y se adapto el patron operativo de Canvas + buffers `deque` + refresco periodico con `after()`. No se copiaron etiquetas ni logica ADXL335 de mV.

## Graficas disponibles

- Sensor 1: `x_g`, `y_g`, `z_g`.
- Sensor 2: `x_g`, `y_g`, `z_g`.
- Comparacion visual `|g|` entre Sensor 1 y Sensor 2.
- Comparacion de eje seleccionado `X`, `Y` o `Z` entre Sensor 1 y Sensor 2.

`|g|` es visual solamente. No se exporta en CSV y no se llama `g_norm_est`.

## Rendimiento

- Tasa de refresco UI: aproximadamente cada 220 ms.
- Emision de lotes del core: aproximadamente cada 200 ms.
- Buffer maximo: 6000 puntos por sensor.
- Ventana visible default: 30 s.
- Downsampling visual en Canvas cuando una serie supera ~650 puntos.

## Validacion smoke

- Comando: `python tools\kx134\gui_live_plot_smoke_test.py --output reports\kx134_gui_validation\TICKET_019_live_plot_smoke_output.json`
- Pass: `true`.
- Samples injected Sensor 1: `120`.
- Samples injected Sensor 2: `120`.
- plots_created: `true`.
- g_abs_visual_only: `true`.
- export_fields_unchanged: `true`.
- errors: `[]`.

## Validacion hardware

- Hardware real usado: si.
- Puerto: `COM4`.
- Baudrate: `921600`.
- Duracion configurada: `20 s`.
- Frecuencia esperada: `100 Hz`.
- Observacion de usuario: resultado totalmente satisfactorio.
- Graficas visibles: si.
- Graficas se actualizaron durante captura: si.
- Sensor 1 mostro senal: si.
- Sensor 2 mostro senal: si.
- Taps/eventos observados: si.
- GUI congelada: no.
- Captura completada: si.
- Puntos visibles reportados por GUI: Sensor 1 `2999`, Sensor 2 `3000`.

Primer intento: se detecto un error de callback (`Kx134CaptureWorker.emit() takes 2 positional arguments but 3 were given`). Se corrigio el adaptador de eventos live y la repeticion fue satisfactoria.

## Exportacion preservada

- CSV KX134 v3 exacto: preservado por contrato y validadores.
- `g_norm`/`g_norm_est` en CSV: no.
- `mv_*` en CSV: no.
- voltajes/milivoltios en CSV: no.
- `x_raw/y_raw/z_raw`: no alterados.
- exportacion endurecida: no alterada.

La validacion de exportacion se ejecuto con bundle controlado bajo `reports/kx134_gui_validation/` para evitar commitear artefactos locales generados bajo `data/` del repo root durante la prueba manual.

## Node map

- status global: `gui_live_plots_validated_pending_windows_packaging`.
- last_gui_live_plots_report: `reports/kx134_gui_validation/TICKET_019_GUI_LIVE_PLOTS_SUMMARY.md`.

## Restricciones

- Firmware no modificado.
- Calibraciones no modificadas.
- Empaquetado no modificado.
- Data historica no modificada.
- ADXL335 preservado.
- No se hizo analisis profundo de vibracion.

## Decision

`READY_FOR_WINDOWS_PACKAGING_PREP=YES`
