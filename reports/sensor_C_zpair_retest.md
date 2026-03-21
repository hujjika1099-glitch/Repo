# Retesteo Focalizado del Par Z - sensor_C

Fecha: 2026-03-21

## Objetivo y condiciones
- Retesteo exclusivo de `pos_z` y `neg_z` (sin repetir multipose completo).
- Sensor: `sensor_C` (mismo sensor de fase previa).
- Misma ESP32 de referencia.
- Mismo firmware baseline.
- Mismo puerto: `COM5`.
- Corridas nuevas por pose: `5`.
- Estabilizacion minima real por corrida: `20 s`.
- Duracion por corrida: `12 s` (sin cambios).

## Corridas nuevas generadas

### pos_z (5)
1. `data/raw/sensor_C/sensor_C_pos_z_20260321_121702.csv`
2. `data/raw/sensor_C/sensor_C_pos_z_20260321_121858.csv`
3. `data/raw/sensor_C/sensor_C_pos_z_20260321_122054.csv`
4. `data/raw/sensor_C/sensor_C_pos_z_20260321_122232.csv`
5. `data/raw/sensor_C/sensor_C_pos_z_20260321_122418.csv`

### neg_z (5)
1. `data/raw/sensor_C/sensor_C_neg_z_20260321_124530.csv`
2. `data/raw/sensor_C/sensor_C_neg_z_20260321_124710.csv`
3. `data/raw/sensor_C/sensor_C_neg_z_20260321_124856.csv`
4. `data/raw/sensor_C/sensor_C_neg_z_20260321_125038.csv`
5. `data/raw/sensor_C/sensor_C_neg_z_20260321_125210.csv`

Total de corridas usadas en retesteo: `10` (5 + 5).

## Artefactos de analisis
- Repetibilidad por pose (ultimas 5 corridas):
  - `reports/analysis_outputs/sensor_C_pos_z_repeatability_20260321_125420.csv`
  - `reports/analysis_outputs/sensor_C_pos_z_repeatability_20260321_125420.txt`
  - `reports/analysis_outputs/sensor_C_neg_z_repeatability_20260321_125459.csv`
  - `reports/analysis_outputs/sensor_C_neg_z_repeatability_20260321_125459.txt`
- Consolidado focalizado Z:
  - `reports/analysis_outputs/sensor_C_zpair_retest_20260321_125701_runs.csv`
  - `reports/analysis_outputs/sensor_C_zpair_retest_20260321_125701_poses.csv`
  - `reports/analysis_outputs/sensor_C_zpair_retest_20260321_125701_comparison.csv`
  - `reports/analysis_outputs/sensor_C_zpair_retest_20260321_125701.txt`

## Metricas por corrida (resumen)

### pos_z
| run_file | freq_hz | seq_jumps | mv_x_mean | mv_y_mean | mv_z_mean |
|---|---:|---:|---:|---:|---:|
| sensor_C_pos_z_20260321_121702.csv | 100.007503 | 0 | 2809.108040 | 1792.175879 | 1867.365997 |
| sensor_C_pos_z_20260321_121858.csv | 100.007511 | 0 | 2800.207012 | 1792.138564 | 1871.219533 |
| sensor_C_pos_z_20260321_122054.csv | 100.007488 | 0 | 2973.150628 | 1793.189958 | 1875.738075 |
| sensor_C_pos_z_20260321_122232.csv | 100.007465 | 0 | 2927.098333 | 1791.092500 | 1875.194167 |
| sensor_C_pos_z_20260321_122418.csv | 100.007534 | 0 | 3050.113998 | 1791.705784 | 1877.363789 |

### neg_z
| run_file | freq_hz | seq_jumps | mv_x_mean | mv_y_mean | mv_z_mean |
|---|---:|---:|---:|---:|---:|
| sensor_C_neg_z_20260321_124530.csv | 100.007522 | 0 | 3011.865659 | 1577.864819 | 1487.205709 |
| sensor_C_neg_z_20260321_124710.csv | 100.007530 | 0 | 2958.392947 | 1583.460957 | 1488.340890 |
| sensor_C_neg_z_20260321_124856.csv | 100.007501 | 0 | 2989.067058 | 1585.846605 | 1488.003353 |
| sensor_C_neg_z_20260321_125038.csv | 100.007311 | 0 | 1788.656591 | 1575.367758 | 1476.633921 |
| sensor_C_neg_z_20260321_125210.csv | 100.007297 | 0 | 1777.213087 | 1579.035235 | 1476.052013 |

## Metricas agregadas por pose (retesteo)
| pose | runs_found | freq_mean_hz | seq_jumps_total | mv_x_pose_mean | mv_y_pose_mean | mv_z_pose_mean | mv_x_mean_range | mv_y_mean_range | mv_z_mean_range |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| pos_z | 5 | 100.007500 | 0 | 2911.935602 | 1792.060537 | 1873.376312 | 249.906987 | 2.097458 | 9.997792 |
| neg_z | 5 | 100.007432 | 0 | 2505.039068 | 1580.315075 | 1483.247177 | 1234.652572 | 10.478847 | 12.288877 |

## Comparacion explicita contra Fase 9 (z_pair)
| metrica | Fase 9 | Retesteo Z |
|---|---:|---:|
| dominant_axis | x | x |
| delta_mv_x (pos-neg) | -1406.104113 | 406.896534 |
| delta_mv_y (pos-neg) | 185.599602 | 211.745462 |
| delta_mv_z (pos-neg) | 379.110409 | 390.129135 |
| dominance_ratio (eje Z vs max otros) | 0.269618 | 0.958792 |
| z_pair_coherent | false | false |

## Observaciones tecnicas
- El retesteo reduce fuertemente la contaminacion extrema previa en X, pero no lo suficiente para que Z sea dominante.
- La separacion en `mv_z` entre `pos_z` y `neg_z` es clara, pero el eje dominante sigue siendo `x` por margen estrecho.
- `neg_z` mantiene dispersion alta en `mv_x_mean_range`, indicando que la orientacion mecanica del bloque Z sigue siendo sensible.

## Decision final
- `z_pair_still_inconsistent`
- `ready_for_final_calibration`: **no**

