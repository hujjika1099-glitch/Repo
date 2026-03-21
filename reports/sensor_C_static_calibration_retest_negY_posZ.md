# Recalibracion Focalizada neg_y y pos_z - sensor_C (Fase 10.2)

Fecha: 2026-03-21

## Alcance

- Sensor: `sensor_C`
- Misma ESP32 de referencia
- Mismo firmware baseline
- Puerto: `COM5`
- Poses recapturadas: `neg_y` y `pos_z`
- Corridas nuevas: `5` por pose
- Estabilizacion previa aplicada: `20 s` por corrida
- Duracion por corrida: `12 s`

## Corridas nuevas capturadas

### neg_y
1. `data/raw/sensor_C/sensor_C_neg_y_20260321_144910.csv`
2. `data/raw/sensor_C/sensor_C_neg_y_20260321_145114.csv`
3. `data/raw/sensor_C/sensor_C_neg_y_20260321_145304.csv`
4. `data/raw/sensor_C/sensor_C_neg_y_20260321_145514.csv`
5. `data/raw/sensor_C/sensor_C_neg_y_20260321_145742.csv`

### pos_z
1. `data/raw/sensor_C/sensor_C_pos_z_20260321_150204.csv`
2. `data/raw/sensor_C/sensor_C_pos_z_20260321_150522.csv`
3. `data/raw/sensor_C/sensor_C_pos_z_20260321_150752.csv`
4. `data/raw/sensor_C/sensor_C_pos_z_20260321_150926.csv`
5. `data/raw/sensor_C/sensor_C_pos_z_20260321_151113.csv`

## Dataset final exacto usado para recalibracion

Se conservaron de Fase 10:
- `pos_x` (3 corridas)
- `neg_x` (3 corridas)
- `pos_y` (3 corridas)
- `neg_z` (5 corridas)

Se reemplazaron:
- `neg_y` por las 5 corridas nuevas
- `pos_z` por las 5 corridas nuevas

Manifest reproducible final:
- `reports/analysis_outputs/sensor_C_static_calibration_20260321_151516_dataset.csv`

## Coeficientes nuevos (modelo simple por eje)

Fuente:
- `data/processed/sensor_C_static_calibration_20260321_151516.csv`

| Eje | offset_raw | sens_raw_per_g | offset_mv | sens_mv_per_g |
|---|---:|---:|---:|---:|
| x | 1884.366872 | -398.674275 | 1699.076903 | -329.277105 |
| y | 1776.843011 | -367.287347 | 1610.333744 | -303.341122 |
| z | 1838.458387 | 246.539160 | 1660.912394 | 203.269237 |

## Validacion cruzada del modelo recalculado

Artefactos:
- `data/processed/sensor_C_static_validation_20260321_151629.csv`
- `data/processed/sensor_C_static_validation_20260321_151629_poses.csv`

Resumen por pose:

| Pose | mean_gx | mean_gy | mean_gz | mean_|g| | mean_error_|g| | max_error_|g| | mean_expected_axis | mean_cross_axis_abs |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| pos_x | 1.000000 | -0.144679 | -0.002508 | 1.014532 | 0.031116 | 0.375254 | 1.000000 | 0.089223 |
| neg_x | -1.000000 | -0.140120 | 0.076029 | 1.016546 | 0.030849 | 0.397851 | 1.000000 | 0.115049 |
| pos_y | 0.040893 | 1.000000 | -0.013302 | 1.004272 | 0.029430 | 0.490100 | 1.000000 | 0.042297 |
| neg_y | -4.421574 | -1.000000 | 0.418410 | 4.553868 | 3.553868 | 3.706367 | 1.000000 | 2.420080 |
| pos_z | -4.421574 | -0.554880 | 1.000000 | 4.568329 | 3.568329 | 3.747595 | 1.000000 | 2.488227 |
| neg_z | -0.301159 | 0.139812 | -1.000000 | 1.058660 | 0.078474 | 0.545893 | 1.000000 | 0.222731 |

## Comparacion contra Fase 10 (modelo simple original)

Fuente:
- Baseline: `data/processed/sensor_C_static_validation_20260321_140524_poses.csv`
- Retesteo: `data/processed/sensor_C_static_validation_20260321_151629_poses.csv`
- Comparacion: `reports/analysis_outputs/sensor_C_static_validation_retest_negY_posZ_20260321_151740_comparison_vs_phase10.csv`

Resultados clave:
- `seq_jumps_total = 0` (ok)
- `neg_y_improved = false`
- `pos_z_improved = false`
- `global_simple_mean_abs_err = 0.097112843`
- `global_retest_mean_abs_err = 1.215344240` (empeora fuertemente)

## Decision final

- `calibrated_but_review_needed`
- `ready_for_next_stage = no`

## Recomendacion operativa

1. No promover esta recalibracion de Fase 10.2 como baseline.
2. Mantener como modelo principal el de Fase 10 (`data/processed/sensor_C_static_calibration_20260321_140044.mat`).
3. Tratar este retesteo como evidencia de inconsistencia de montaje/orientacion en `neg_y` y `pos_z`.
