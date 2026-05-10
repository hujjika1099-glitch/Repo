# TICKET 019 - Graficas en vivo KX134

## Objetivo

Agregar retroalimentacion grafica en vivo al modo KX134 para observar `x_g`, `y_g`, `z_g`, comparacion entre sensores y `|g|` visual durante la captura.

## Alcance

- Panel de graficas KX134 con Canvas/Tkinter.
- Buffer live por sensor con ventana temporal configurable.
- Eventos de progreso desde el core durante captura.
- Integracion en pestana `Graficas` de la GUI KX134.
- Smoke test sin hardware con muestras sinteticas.
- Validacion de que el contrato CSV KX134 v3 no cambia.

## Restricciones cumplidas

- No se modifica firmware.
- No se modifican calibraciones.
- No se modifica empaquetado.
- No se modifica data historica.
- No se agregan `g_norm`, `g_norm_est`, `mv_*`, voltajes ni milivoltios al CSV.
- ADXL335 queda preservado.

## Cambios implementados

- `gui/kx134_live_plots.py`: componentes de buffer y Canvas.
- `gui/kx134_live_core.py`: eventos `sample_batch` y `capture_progress`.
- `gui/kx134_live_gui.py`: pestana `Graficas` y actualizacion live.
- `tools/kx134/gui_live_plot_smoke_test.py`: smoke visual sintetico.
- Tests de buffer y construccion de GUI sin hardware.

## Criterios de aceptacion

- La GUI KX134 conserva layout responsive.
- La pestana `Graficas` existe.
- Las graficas aceptan muestras de Sensor 1 y Sensor 2.
- `|g|` se calcula solo para visualizacion.
- La exportacion KX134 v3 sigue sin campos prohibidos.
- Las pruebas Python y smoke test pasan.

## Decision esperada

`READY_FOR_WINDOWS_PACKAGING_PREP=YES` cuando el smoke y la validacion operativa sean aceptables.
