# Plan Operativo Inmediato: Repetibilidad Misma Pose

Fecha: 2026-03-20

## Objetivo de la siguiente operacion
Validar repetibilidad para `sensor_A` en la misma pose `z_plus_static` antes de iniciar protocolo completo de multiples posiciones.

## Condiciones a mantener
- Misma ESP32 de referencia.
- Mismo `sensor_A`.
- Misma pose: `z_plus_static`.
- Mismo puerto: `COM5`.
- Mismo firmware baseline cargado y activo.

## Corridas a realizar (fase siguiente)
- Realizar `2` o `3` capturas adicionales.
- Cada corrida debe generar archivos nuevos con timestamp unico.
- No sobrescribir `data/raw/sensor_A/*.csv` existentes.

## Estructura esperada de nuevos archivos
- `data/raw/sensor_A/sensor_A_z_plus_static_YYYYMMDD_HHMMSS.csv`
- `data/raw/sensor_A/sensor_A_z_plus_static_YYYYMMDD_HHMMSS_session.txt`

## Analisis previsto
- Script individual:
  - `matlab/analysis/analyze_single_capture_baseline.m`
- Script comparativo preparado:
  - `matlab/analysis/analyze_repeatability_same_pose.m`
- Salida inicial de preparacion (con 1 corrida actual):
  - `reports/analysis_outputs/sensor_A_z_plus_static_repeatability_20260320_135043.csv`
  - `reports/analysis_outputs/sensor_A_z_plus_static_repeatability_20260320_135043.txt`
  - estado actual: `ready_for_comparison = false` (faltan corridas adicionales)

## Criterio de avance
- Si las corridas adicionales mantienen continuidad de `seq`, frecuencia cercana a 100 Hz y dispersion razonable entre medias por canal, avanzar a etapa previa de protocolo multipose.
