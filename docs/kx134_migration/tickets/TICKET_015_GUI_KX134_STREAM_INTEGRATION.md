# TICKET 015 - Integracion GUI KX134 stream Serial v3

## Objetivo

Integrar el stream Serial KX134 v3 en la aplicacion Python mediante un modo
separado, sin alterar el flujo historico ADXL335.

## Precondiciones

- TICKET 014 aprobado.
- `READY_FOR_GUI_KX134_STREAM_INTEGRATION = YES`.
- Receptor KX134 validado en `COM4` a 921600 baudios.
- Logs reales disponibles en `reports/kx134_test_runs/`.

## Alcance

- Crear contrato Python KX134 v3.
- Crear parser/core KX134 separado.
- Crear modulo GUI KX134 separado.
- Exportar CSV/JSON/resumen propios para KX134.
- Validar parser y exportacion con `unittest`.
- Ejecutar replay sobre el log estatico final de TICKET 014.

## Restricciones

- No modificar firmware.
- No modificar calibraciones.
- No modificar empaquetado.
- No modificar data historica.
- No redisenar completamente la GUI.
- No cambiar nombres de ejecutable.

## Archivos modificados o creados

- `gui/kx134_stream_contract.py`
- `gui/kx134_live_core.py`
- `gui/kx134_live_gui.py`
- `tests/test_kx134_stream_parser.py`
- `tests/test_kx134_capture_export.py`
- `tools/kx134/replay_kx134_log_to_core.py`
- `docs/kx134_migration/GUI_KX134_STREAM_INTEGRATION.md`
- `reports/kx134_gui_validation/TICKET_015_replay_validation_output.json`
- `reports/kx134_gui_validation/TICKET_015_GUI_KX134_VALIDATION_SUMMARY.md`

## Pruebas

Comandos esperados:

```powershell
python -m py_compile gui/kx134_stream_contract.py
python -m py_compile gui/kx134_live_core.py
python -m py_compile gui/kx134_live_gui.py
python -m py_compile tools/kx134/replay_kx134_log_to_core.py
python -m unittest discover -s tests -p "test_kx134*.py"
python tools/kx134/replay_kx134_log_to_core.py --log reports/kx134_test_runs/TICKET_014_static_receiver_monitor_20260510_112712.txt --output-root reports/kx134_gui_validation --session-name ticket015_static_replay --expected-sample-rate 100
```

## Criterios de aceptacion

- Encabezado KX134 exacto reconocido.
- Filas Sensor 1 y Sensor 2 parseadas.
- Filas ADXL335 de 8/9 campos rechazadas en modo KX134.
- `sample_rate_hz` 100/200/400/800 aceptado.
- `sample_rate_hz` 500/1000 rechazado.
- `sensor_id` faltante rechazado.
- Campos `mv_*` y `gx_est/gy_est/gz_est/g_norm_est` rechazados.
- Replay TICKET 014 detecta ambos sensores con mas de 1000 filas cada uno.
- Export CSV contiene encabezado KX134 exacto y no contiene campos prohibidos.

## Decision final esperada

`READY_FOR_GUI_HARDWARE_VALIDATION = YES` si las pruebas unitarias y el replay
con log real pasan.
