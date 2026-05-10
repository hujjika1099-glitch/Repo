# TICKET 017 - KX134 export metadata hardening summary

## Fecha

2026-05-10

## Commit base

`05a88f7` - `test: validate KX134 GUI hardware capture`

## Cambios aplicados

- Metadata KX134 endurecida en `gui/kx134_live_core.py`.
- Constantes de sesion/topologia agregadas en `gui/kx134_stream_contract.py`.
- Validador nuevo: `tools/kx134/validate_kx134_export_bundle.py`.
- Pruebas de metadata: `tests/test_kx134_export_metadata_schema.py`.
- `config/kx134_node_map.json` actualizado a export hardening validado.

## Bundle generado

- Carpeta: `reports/kx134_gui_validation/TICKET_017_export_hardening_20260510_130454/`
- Raw CSV: `reports/kx134_gui_validation/TICKET_017_export_hardening_20260510_130454/data/raw/kx134_dual_live/kx134_dual_live_ticket017_export_hardening_20260510_130507_raw.csv`
- Session JSON: `reports/kx134_gui_validation/TICKET_017_export_hardening_20260510_130454/data/processed/kx134_dual_live/kx134_dual_live_ticket017_export_hardening_20260510_130507_session.json`
- Summary MD: `reports/kx134_gui_validation/TICKET_017_export_hardening_20260510_130454/reports/analysis_outputs/kx134_dual_live/kx134_dual_live_ticket017_export_hardening_20260510_130507_summary.md`

El bundle se genero a partir del CSV real validado en TICKET 016 para conservar `pc_wall_s` positivo de captura GUI real.

## Validacion del bundle nuevo

- Output: `reports/kx134_gui_validation/TICKET_017_export_bundle_validation_output.json`
- Pass: `true`
- Rows Sensor 1: `1001`
- Rows Sensor 2: `999`
- Effective Hz Sensor 1: `100.0`
- Effective Hz Sensor 2: `100.00002004008418`
- Seq gaps Sensor 1: `0`
- Seq gaps Sensor 2: `0`
- Invalid lines: `0`
- Duplicate keys Sensor 1: `0`
- Duplicate keys Sensor 2: `0`
- `pc_wall_s` positivo: `true`
- `receiver_t_us` valido: `true`
- Metadata schema pass: `true`
- Relative artifacts pass: `true`
- Forbidden fields detected: `false`

## Validacion del bundle TICKET 016

- Output: `reports/kx134_gui_validation/TICKET_017_ticket016_bundle_validation_output.json`
- Pass: `false`
- Causa: metadata legacy previa al endurecimiento. El CSV TICKET 016 sigue valido, pero el JSON antiguo no contiene el esquema completo ni rutas relativas endurecidas.
- Artefacto historico TICKET 016 modificado: `no`

## Node map

- status global: `gui_hardware_capture_validated_export_hardened_pending_visual_redesign`
- sensor_node_1 status: `validated_for_gui_export`
- sensor_node_2 status: `validated_for_gui_export`
- receiver_esp32 status: `validated_for_gui_export`

## Decision

`READY_FOR_GUI_VISUAL_REDESIGN=YES`

El sistema KX134 ya tiene captura GUI real validada y exportacion endurecida/validable. El siguiente paso natural es redisenar visualmente la GUI sin cambiar todavia firmware ni empaquetado.
