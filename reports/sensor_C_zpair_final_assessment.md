# Evaluacion Final del Par Z - sensor_C (Fase 9.2)

Fecha: 2026-03-21

## Alcance de la fase
- Retesteo definitivo focalizado solo en `pos_z` y `neg_z`.
- Sensor: `sensor_C`.
- Misma ESP32 de referencia.
- Mismo firmware baseline.
- Puerto fijo: `COM5`.
- Corridas nuevas: `5` por pose.
- Estabilizacion minima real aplicada: `20 s` por corrida.
- Duracion de corrida: `12 s` (sin cambios).

## Corridas nuevas de esta fase

### pos_z (5)
1. `data/raw/sensor_C/sensor_C_pos_z_20260321_131713.csv`
2. `data/raw/sensor_C/sensor_C_pos_z_20260321_131840.csv`
3. `data/raw/sensor_C/sensor_C_pos_z_20260321_132019.csv`
4. `data/raw/sensor_C/sensor_C_pos_z_20260321_132204.csv`
5. `data/raw/sensor_C/sensor_C_pos_z_20260321_132349.csv`

### neg_z (5)
1. `data/raw/sensor_C/sensor_C_neg_z_20260321_132804.csv`
2. `data/raw/sensor_C/sensor_C_neg_z_20260321_132949.csv`
3. `data/raw/sensor_C/sensor_C_neg_z_20260321_133129.csv`
4. `data/raw/sensor_C/sensor_C_neg_z_20260321_133305.csv`
5. `data/raw/sensor_C/sensor_C_neg_z_20260321_133454.csv`

Total de corridas usadas en esta fase: `10`.

## Artefactos de analisis
- Repetibilidad por pose (ultimas 5 corridas):
  - `reports/analysis_outputs/sensor_C_pos_z_repeatability_20260321_133652.csv`
  - `reports/analysis_outputs/sensor_C_pos_z_repeatability_20260321_133652.txt`
  - `reports/analysis_outputs/sensor_C_neg_z_repeatability_20260321_133740.csv`
  - `reports/analysis_outputs/sensor_C_neg_z_repeatability_20260321_133740.txt`
- Consolidado comparativo Fase 9 vs 9.1 vs 9.2:
  - `reports/analysis_outputs/sensor_C_zpair_retest_20260321_133945_runs.csv`
  - `reports/analysis_outputs/sensor_C_zpair_retest_20260321_133945_poses.csv`
  - `reports/analysis_outputs/sensor_C_zpair_retest_20260321_133945_comparison.csv`
  - `reports/analysis_outputs/sensor_C_zpair_retest_20260321_133945.txt`

## Metricas por corrida (Fase 9.2)

### pos_z
| run_file | freq_hz | seq_jumps | mv_x_mean | mv_y_mean | mv_z_mean |
|---|---:|---:|---:|---:|---:|
| sensor_C_pos_z_20260321_131713.csv | 100.007287 | 0 | 1793.889540 | 1784.524686 | 1860.784100 |
| sensor_C_pos_z_20260321_131840.csv | 100.007303 | 0 | 1792.716205 | 1784.701931 | 1861.345928 |
| sensor_C_pos_z_20260321_132019.csv | 100.007230 | 0 | 1791.547797 | 1782.335827 | 1863.018288 |
| sensor_C_pos_z_20260321_132204.csv | 100.007295 | 0 | 1791.951464 | 1781.671967 | 1864.158159 |
| sensor_C_pos_z_20260321_132349.csv | 100.007305 | 0 | 1793.356544 | 1780.442953 | 1866.031040 |

### neg_z
| run_file | freq_hz | seq_jumps | mv_x_mean | mv_y_mean | mv_z_mean |
|---|---:|---:|---:|---:|---:|
| sensor_C_neg_z_20260321_132804.csv | 100.007266 | 0 | 1812.672515 | 1559.017544 | 1474.272348 |
| sensor_C_neg_z_20260321_132949.csv | 100.007299 | 0 | 1816.787091 | 1562.270746 | 1466.779547 |
| sensor_C_neg_z_20260321_133129.csv | 100.007318 | 0 | 1804.999160 | 1569.136134 | 1452.952101 |
| sensor_C_neg_z_20260321_133305.csv | 100.007287 | 0 | 1779.705439 | 1573.020921 | 1449.182427 |
| sensor_C_neg_z_20260321_133454.csv | 100.007314 | 0 | 1777.043624 | 1576.169463 | 1445.029362 |

## Metricas agregadas por pose (Fase 9.2)
| pose | runs_found | freq_mean_hz | seq_jumps_total | mv_x_pose_mean | mv_y_pose_mean | mv_z_pose_mean | mv_x_mean_range | mv_y_mean_range | mv_z_mean_range |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| pos_z | 5 | 100.007284 | 0 | 1792.692310 | 1782.735473 | 1863.067503 | 2.341743 | 4.258978 | 5.246940 |
| neg_z | 5 | 100.007297 | 0 | 1798.241566 | 1567.922962 | 1457.643157 | 39.743467 | 17.151919 | 29.242985 |

## Comparacion explicita: Fase 9 vs 9.1 vs 9.2 (par Z)
| metrica | Fase 9 | Fase 9.1 | Fase 9.2 |
|---|---:|---:|---:|
| dominant_axis | x | x | z |
| delta_mv_x (pos-neg) | -1406.104113 | 406.896534 | -5.549256 |
| delta_mv_y (pos-neg) | 185.599602 | 211.745462 | 214.812511 |
| delta_mv_z (pos-neg) | 379.110409 | 390.129135 | 405.424346 |
| dominance_ratio | 0.269618 | 0.958792 | 1.887340 |
| pair_coherent | false | false | true |

## Evaluacion contra criterio de aprobacion obligatorio
1. `dominant_axis = z`: **cumple** (`z`)
2. `dominance_ratio >= 1.2`: **cumple** (`1.887340`)
3. `abs(delta_mv_z) >= 50`: **cumple** (`405.424346`)
4. `seq_jumps_total = 0` en `pos_z` y `neg_z`: **cumple** (`0` y `0`)

Resultado de criterios: **4/4 cumplidos**.

## Decision final
- `z_pair_fixed`
- `ready_for_final_calibration = yes`

## Observaciones tecnicas
- La contaminacion por eje X disminuyo de forma suficiente para dejar de dominar el par Z.
- La separacion en Z se mantiene robusta y ahora domina frente a ejes cruzados.
- El par Z queda alineado con el comportamiento fisico esperado para avanzar a calibracion final.
