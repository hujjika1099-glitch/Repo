# TICKET 017 - Endurecer exportacion KX134, metadata y validadores de sesion

## Objetivo

Endurecer la exportacion KX134 para que cada captura de GUI produzca un bundle auditable:

- CSV raw KX134 v3 con encabezado exacto.
- JSON de sesion con metadata completa.
- Summary MD legible.
- Validador de bundle exportado.
- Rutas relativas portables.
- Estado de sistema actualizado en `config/kx134_node_map.json`.

## Precondiciones

- TICKET 016 aprobado.
- GUI KX134 validada con hardware real.
- `READY_FOR_GUI_EXPORT_HARDENING=YES`.
- Artefactos reales TICKET 016 disponibles para prueba de compatibilidad.

## Cambios

- Se endurecio `export_kx134_session()` en `gui/kx134_live_core.py`.
- Se agregaron constantes de sesion/topologia al contrato Python KX134.
- Se creo `tools/kx134/validate_kx134_export_bundle.py`.
- Se agregaron pruebas de esquema de metadata.
- Se genero un bundle endurecido controlado a partir de la captura real TICKET 016.
- Se valido tambien el bundle TICKET 016 como artefacto legacy.

## Criterios de aceptacion

- El bundle nuevo pasa `validate_kx134_export_bundle.py`.
- El CSV nuevo conserva el contrato KX134 v3 y no contiene campos ADXL335/mV.
- El JSON nuevo contiene identidad de sesion, nodos, configuracion, arquitectura, resumen y rutas relativas.
- El summary nuevo menciona Sensor 1, Sensor 2, artefactos y decision.
- El TICKET 016 no se modifica si falla por metadata legacy.
- `config/kx134_node_map.json` queda coherente con GUI validada y export hardening.

## Restricciones verificadas

- Firmware no modificado.
- Calibraciones no modificadas.
- Firmware ADXL335 no modificado.
- Empaquetado no modificado.
- Data historica no modificada.
- GUI visual no redisenada.
- No se implementa envio de sample_rate al firmware.

## Decision final esperada

`READY_FOR_GUI_VISUAL_REDESIGN=YES` si el bundle endurecido pasa validacion y no hay regresiones Python.
