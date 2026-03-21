# Calibracion Refinada Estatica sensor_C (Fase 10.1)

Fecha: 2026-03-21

## Dataset exacto reutilizado

Se reutilizo exactamente el dataset de Fase 10 (22 corridas), sin nuevas capturas:

- `pos_x`: `sensor_C_pos_x_20260321_103048.csv`, `sensor_C_pos_x_20260321_103224.csv`, `sensor_C_pos_x_20260321_103405.csv`
- `neg_x`: `sensor_C_neg_x_20260321_104116.csv`, `sensor_C_neg_x_20260321_104255.csv`, `sensor_C_neg_x_20260321_104434.csv`
- `pos_y`: `sensor_C_pos_y_20260321_105150.csv`, `sensor_C_pos_y_20260321_105330.csv`, `sensor_C_pos_y_20260321_105508.csv`
- `neg_y`: `sensor_C_neg_y_20260321_110157.csv`, `sensor_C_neg_y_20260321_110339.csv`, `sensor_C_neg_y_20260321_110521.csv`
- `pos_z`: `sensor_C_pos_z_20260321_131713.csv`, `sensor_C_pos_z_20260321_131840.csv`, `sensor_C_pos_z_20260321_132019.csv`, `sensor_C_pos_z_20260321_132204.csv`, `sensor_C_pos_z_20260321_132349.csv`
- `neg_z`: `sensor_C_neg_z_20260321_132804.csv`, `sensor_C_neg_z_20260321_132949.csv`, `sensor_C_neg_z_20260321_133129.csv`, `sensor_C_neg_z_20260321_133305.csv`, `sensor_C_neg_z_20260321_133454.csv`

Manifest reproducible:
- `reports/analysis_outputs/sensor_C_static_affine_3x3_20260321_142515_dataset.csv`

## Formulacion del modelo refinado

Modelo principal en mV:

- `g_est_mv = M_mv * (v_mv - b_mv)`
- `v_mv = [mv_x mv_y mv_z]^T`

Modelo complementario en raw:

- `g_est_raw = M_raw * (v_raw - b_raw)`

Metodo de ajuste:
1. Se calculan medias por corrida (22 observaciones).
2. Se asigna target ideal por pose:
   - `pos_x -> [1,0,0]`, `neg_x -> [-1,0,0]`
   - `pos_y -> [0,1,0]`, `neg_y -> [0,-1,0]`
   - `pos_z -> [0,0,1]`, `neg_z -> [0,0,-1]`
3. Se resuelve por minimos cuadrados una forma affine:
   - `g = A*v + c`
4. Se reexpresa como:
   - `M = A`
   - `b = -M^{-1} c` (o pseudoinversa si aplica)
   - `g = M*(v-b)`

## Coeficientes finales (modelo principal mV)

Fuente: `data/processed/sensor_C_static_affine_3x3_20260321_142515.csv`

Bias vector:
- `b_mv = [1743.470158209, 1649.757214315, 1680.350714441]^T`

Matriz 3x3:

|     | c1 | c2 | c3 |
|---|---:|---:|---:|
| r1 | -0.002837173608 | 0.000395737540 | -0.000390709107 |
| r2 | 0.000098195711 | -0.003417809288 | 0.001504462903 |
| r3 | 0.000023248722 | -0.000786065725 | 0.004991479349 |

Ecuacion final principal:
- `g_est_mv = M_mv * ([mv_x mv_y mv_z]^T - b_mv)`

## Validacion refinada (mismo dataset)

Archivos:
- `data/processed/sensor_C_static_affine_3x3_validation_20260321_142847.csv`
- `data/processed/sensor_C_static_affine_3x3_validation_20260321_142847_poses.csv`
- `reports/analysis_outputs/sensor_C_static_affine_3x3_validation_20260321_142847_comparison_vs_simple.csv`
- `reports/analysis_outputs/sensor_C_static_affine_3x3_validation_20260321_142847.txt`

Resumen por pose (modelo affine):

| Pose | mean_gx | mean_gy | mean_gz | mean_|g| | mean_error_|g| | max_error_|g| | expected_axis_mean | cross_axes_abs_mean |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| pos_x | 1.069728 | -0.081960 | -0.111767 | 1.082930 | 0.088247 | 0.370884 | 1.069728 | 0.105865 |
| neg_x | -0.805489 | 0.011452 | -0.015685 | 0.811264 | 0.189903 | 0.397155 | 0.805489 | 0.038627 |
| pos_y | 0.037161 | 1.132510 | 0.157568 | 1.146748 | 0.152931 | 0.534919 | 1.132510 | 0.103682 |
| neg_y | 0.130573 | -0.687413 | 0.365547 | 0.796746 | 0.205678 | 0.462491 | 0.687413 | 0.250230 |
| pos_z | -0.158416 | -0.174770 | 0.808642 | 0.846522 | 0.160482 | 0.493420 | 0.808642 | 0.167615 |
| neg_z | -0.100767 | -0.049983 | -1.046040 | 1.057243 | 0.087343 | 0.591621 | 1.046040 | 0.085648 |

## Comparacion explicita contra Fase 10 (modelo simple)

Metrica global:
- `overall_mean_error_|g|` simple: `0.097112843`
- `overall_mean_error_|g|` affine: `0.147430669`
- Resultado global: **empeora** con affine.

Foco solicitado:
- `neg_y`: `mean_error_|g|` simple `0.201351` -> affine `0.205678` (**no mejora**)
- `pos_z`: `mean_error_|g|` simple `0.206731` -> affine `0.160482` (**si mejora**)

Hallazgo principal:
- La mejora parcial en `pos_z` no compensa el deterioro en otras poses (`neg_x`, `pos_y`, `neg_y`).

## Observaciones tecnicas

- La formulacion affine 3x3 ajustada sobre medias por corrida no mejora el comportamiento global frente al modelo simple por eje.
- `seq_jumps_total` se mantiene en 0 (sin problema de integridad digital).
- La decision de fase no justifica promocion a `ready_for_next_stage`.

## Decision final

- `calibrated_but_review_needed`
- `ready_for_next_stage = no`

## Recomendacion de modelo principal

- Conservar **modelo simple por eje de Fase 10** como principal por ahora.
- Conservar modelo affine 3x3 como artefacto de investigacion/comparacion, no como baseline operativo.
