# TICKET 018 - GUI visual redesign summary

## Fecha

2026-05-10

## Commit base

`10af364` - `gui: harden KX134 export metadata`

## Auditoria visual actual

- Ventana KX134 anterior: `980x700`, minimo `860x620`.
- Usaba `place` para el titulo principal.
- Layout principal con dos columnas y labels largos para rutas.
- No tenia pestañas ni panel dedicado para exportacion.
- Riesgo en pantallas 1366x768 y escalado 125/150%: rutas largas y zona de estado podian competir por espacio visible.
- ADXL335 historico ya tenia una interfaz mas rica, pero se preservo sin cambios de core/exportacion.

## Cambios visuales implementados

- Launcher principal `gui/app_launcher.py`.
- Tema compartido `gui/ui_theme.py`.
- Componentes responsive `gui/ui_components.py`.
- GUI KX134 redisenada con pestañas:
  - Conexion.
  - Captura.
  - Sensores.
  - Diagnostico.
  - Exportacion.

## Layout

- Tamano inicial: `1180x760`.
- Tamano minimo: `980x640`.
- Estrategia responsive: `grid` con pesos, tabs, `ScrollableFrame`, entradas readonly para rutas largas.
- DPI awareness: best effort por `ctypes`; no falla fuera de Windows.
- Se evita `place` absoluto en la GUI KX134.

## Launcher

- Titulo: `Sistema de Captura de Acelerometria`.
- Acceso principal: `Abrir KX134 Dual Capture`.
- Acceso secundario: `Abrir ADXL335 historico`.
- ADXL335 queda preservado como modulo historico.

## Smoke tests

- Output: `reports/kx134_gui_validation/TICKET_018_gui_smoke_output.json`.
- Pass: `true`.
- KX134 title: `Sistema de Captura Dual KX134`.
- KX134 tabs: `Conexion`, `Captura`, `Sensores`, `Diagnostico`, `Exportacion`.
- KX134 minsize: `980x640`.
- Launcher minsize: `720x460`.
- Hardware requerido para smoke: `false`.

## Unit tests

- `python -m unittest discover -s tests -p "test_kx134*.py"`: OK.
- `python -m unittest discover -s tests -p "test_app_launcher*.py"`: OK.

## Node map

- status global: `gui_visual_redesign_validated_pending_windows_packaging`.
- last_gui_visual_redesign_report: `reports/kx134_gui_validation/TICKET_018_GUI_VISUAL_REDESIGN_SUMMARY.md`.

## Limitaciones

- No se genero `.exe`.
- Validacion manual en otro PC queda pendiente.
- Empaquetado profesional queda pendiente.
- Envio de configuracion `sample_rate_hz` al firmware sigue pendiente.

## Decision

`READY_FOR_WINDOWS_PACKAGING_PREP=YES`
