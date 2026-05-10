# TICKET 018 - Rediseno visual profesional y responsive de GUI KX134/ADXL

## Objetivo

Redisenar la interfaz grafica para que el sistema KX134/ADXL sea mas profesional, usable y adaptable en pantallas comunes de Windows antes del empaquetado final.

## Alcance

- Tema visual compartido.
- Componentes Tkinter reutilizables.
- GUI KX134 responsive con pestañas.
- Launcher principal para abrir KX134 o ADXL335 historico.
- Smoke test visual sin hardware.
- Documentacion, reporte, backlog y change log.

## Restricciones

- Firmware no modificado.
- Calibraciones no modificadas.
- Empaquetado no modificado.
- No se genera `.exe`.
- Data historica no modificada.
- Exportacion KX134 endurecida preservada.
- ADXL335 se conserva como modulo historico; no se cambia su core.

## Cambios implementados

- `gui/ui_theme.py`: estilos, constantes visuales y DPI awareness best effort.
- `gui/ui_components.py`: `ScrollableFrame`, `StatusCard`, `KeyValuePanel`, `FileArtifactPanel`.
- `gui/kx134_live_gui.py`: ventana redisenada con tabs para conexion, captura, sensores, diagnostico y exportacion.
- `gui/app_launcher.py`: entrada principal con acceso a KX134 y ADXL335 historico.
- `tools/kx134/gui_smoke_test.py`: validacion visual automatizada sin hardware.

## Pruebas

- Compilacion Python de GUI/core/herramientas.
- `unittest` KX134.
- `unittest` app launcher.
- Smoke visual Tkinter con cierre automatico.
- Ejecucion smoke directa con `python -m gui.kx134_live_gui`.
- Ejecucion smoke directa con `python -m gui.app_launcher`.

## Criterios de aceptacion

- KX134 GUI abre sin excepciones.
- Launcher abre sin excepciones.
- KX134 usa tamano inicial razonable y minimo no mayor a `980x640`.
- Hay pestañas/secciones claras.
- Hay scroll donde aplica.
- No se usa `place` absoluto en KX134.
- Se preservan puerto, baudrate, duracion manual, frecuencias 100/200/400/800, estado de sensores y exportacion.

## Decision final

`READY_FOR_WINDOWS_PACKAGING_PREP=YES`
