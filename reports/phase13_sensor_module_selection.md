# Fase 13 - Seleccion Operativa de Modulos ADXL335

Fecha: 2026-03-22

## Decision final (cerrada)
- `sensor_B`: `primary_operational_ready`
- `sensor_A`: `backup_operational_ready`
- `sensor_C`: `historical_reference_provisional`
- `sensor_D`: `rejected_module`

## Evidencia usada (sin reabrir Fase 11)
- `sensor_B`:
  - `reports/analysis_outputs/sensor_B_phase12_fast_bringup_20260322_184733.txt`
  - `reports/analysis_outputs/sensor_B_phase12_quickcheck_20260322_184733.txt`
  - Resultado: `ready_for_operational_use`, `max_sat_pct=0`, `seq_jumps=0`.
- `sensor_A`:
  - `reports/analysis_outputs/sensor_A_phase12_fast_bringup_20260322_185043.txt`
  - `reports/analysis_outputs/sensor_A_phase12_quickcheck_20260322_185043.txt`
  - Resultado: `ready_for_operational_use`, `max_sat_pct=0`, `seq_jumps=0`.
- `sensor_C`:
  - `reports/analysis_outputs/sensor_C_phase11_axis_identity_and_convention_20260322_175610.txt`
  - Resultado: `operationally_usable_provisional_identity` (referencia historica, no lider).
- `sensor_D`:
  - `reports/analysis_outputs/sensor_D_phase12_fast_bringup_20260322_184138.txt`
  - `reports/analysis_outputs/sensor_D_phase12_quickcheck_20260322_184137.txt`
  - Resultado: `rejected_module` por saturacion dura.

## Estado operativo para desarrollo
1. Operar por defecto con `sensor_B`.
2. Conmutar a `sensor_A` solo si `sensor_B` falla chequeo corto de sanidad.
3. No usar `sensor_D`.
4. No usar `sensor_C` como modulo lider de hardware.
