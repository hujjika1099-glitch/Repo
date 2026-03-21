# Validacion Multipose Estatica de sensor_C

Fecha: 2026-03-21

## Alcance y condiciones de prueba
- Sensor evaluado: `sensor_C` (unico sensor en esta fase).
- Misma ESP32 de referencia.
- Mismo firmware baseline de captura serial.
- Mismo puerto: `COM5`.
- Poses evaluadas: `pos_x`, `neg_x`, `pos_y`, `neg_y`, `pos_z`, `neg_z`.
- Corridas por pose: `3` (todas reales).
- Estabilizacion minima aplicada antes de cada corrida: `20 s`.
- Duracion por corrida: `12 s` (sin cambios).

## Corridas registradas por pose

### pos_x
1. `data/raw/sensor_C/sensor_C_pos_x_20260321_103048.csv`
2. `data/raw/sensor_C/sensor_C_pos_x_20260321_103224.csv`
3. `data/raw/sensor_C/sensor_C_pos_x_20260321_103405.csv`

### neg_x
1. `data/raw/sensor_C/sensor_C_neg_x_20260321_104116.csv`
2. `data/raw/sensor_C/sensor_C_neg_x_20260321_104255.csv`
3. `data/raw/sensor_C/sensor_C_neg_x_20260321_104434.csv`

### pos_y
1. `data/raw/sensor_C/sensor_C_pos_y_20260321_105150.csv`
2. `data/raw/sensor_C/sensor_C_pos_y_20260321_105330.csv`
3. `data/raw/sensor_C/sensor_C_pos_y_20260321_105508.csv`

### neg_y
1. `data/raw/sensor_C/sensor_C_neg_y_20260321_110157.csv`
2. `data/raw/sensor_C/sensor_C_neg_y_20260321_110339.csv`
3. `data/raw/sensor_C/sensor_C_neg_y_20260321_110521.csv`

### pos_z
1. `data/raw/sensor_C/sensor_C_pos_z_20260321_113706.csv`
2. `data/raw/sensor_C/sensor_C_pos_z_20260321_113900.csv`
3. `data/raw/sensor_C/sensor_C_pos_z_20260321_114043.csv`

### neg_z
1. `data/raw/sensor_C/sensor_C_neg_z_20260321_115129.csv`
2. `data/raw/sensor_C/sensor_C_neg_z_20260321_115319.csv`
3. `data/raw/sensor_C/sensor_C_neg_z_20260321_115457.csv`

## Artefactos de analisis
- Analisis por pose (repetibilidad, ultimas 3 corridas):
  - `reports/analysis_outputs/sensor_C_pos_x_repeatability_20260321_115708.csv`
  - `reports/analysis_outputs/sensor_C_neg_x_repeatability_20260321_115744.csv`
  - `reports/analysis_outputs/sensor_C_pos_y_repeatability_20260321_115814.csv`
  - `reports/analysis_outputs/sensor_C_neg_y_repeatability_20260321_115844.csv`
  - `reports/analysis_outputs/sensor_C_pos_z_repeatability_20260321_115919.csv`
  - `reports/analysis_outputs/sensor_C_neg_z_repeatability_20260321_115949.csv`
- Consolidado multipose:
  - `reports/analysis_outputs/sensor_C_multipose_static_20260321_120320_runs.csv`
  - `reports/analysis_outputs/sensor_C_multipose_static_20260321_120320_poses.csv`
  - `reports/analysis_outputs/sensor_C_multipose_static_20260321_120320_pairs.csv`
  - `reports/analysis_outputs/sensor_C_multipose_static_20260321_120320.txt`

## Metricas clave por pose (promedios y dispersion de medias)
| pose | runs_found | freq_mean_hz | seq_jumps_total | mv_x_pose_mean | mv_y_pose_mean | mv_z_pose_mean | mv_x_mean_range | mv_y_mean_range | mv_z_mean_range |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| pos_x | 3 | 100.007298 | 0 | 1369.799798 | 1654.220804 | 1660.402550 | 7.941723 | 2.839278 | 0.874875 |
| neg_x | 3 | 100.007303 | 0 | 2028.354008 | 1652.837800 | 1676.366689 | 0.280099 | 2.591481 | 3.532199 |
| pos_y | 3 | 100.007294 | 0 | 1685.611627 | 1306.992621 | 1658.208503 | 0.884883 | 1.350473 | 0.821739 |
| neg_y | 3 | 100.007288 | 0 | 1716.792601 | 1899.737621 | 1793.076398 | 1.302136 | 3.263335 | 3.270926 |
| pos_z | 3 | 100.007297 | 0 | 1700.986379 | 1786.481116 | 1863.790576 | 4.430637 | 5.109880 | 5.566195 |
| neg_z | 3 | 100.007525 | 0 | 3107.090492 | 1600.881514 | 1484.680167 | 132.587881 | 5.302313 | 0.902945 |

## Comparacion pos vs neg por eje esperado
| pair | eje esperado | delta_mv_x (pos-neg) | delta_mv_y (pos-neg) | delta_mv_z (pos-neg) | eje dominante | dominance_ratio | pair_coherent |
|---|---|---:|---:|---:|---|---:|---|
| x_pair | x | -658.554210 | 1.383004 | -15.964139 | x | 41.252097 | true |
| y_pair | y | -31.180974 | -592.745000 | -134.867895 | y | 4.395004 | true |
| z_pair | z | -1406.104113 | 185.599602 | 379.110409 | x | 0.269618 | false |

## Interpretacion tecnica
- Flujo digital estable: frecuencia ~100 Hz en todas las poses y `seq_jumps_total = 0`.
- Coherencia fisica satisfactoria en pares `x_pair` y `y_pair`.
- Inconsistencia relevante en `z_pair`: el cambio dominante ocurre en eje `x` en vez de `z`.
- En `neg_z`, `mv_x_pose_mean` queda muy elevado y con dispersion grande (`mv_x_mean_range = 132.587881`), indicando sesgo de orientacion/montaje para esa pose.

## Decision final
- `multipose_inconsistent`

## Estado de seleccion de sensor
- `sensor_C` se mantiene como `candidate_preferred_sensor` frente a `sensor_A` y `sensor_B` (screening previo).
- Aun **no** queda `ready_for_final_calibration` hasta corregir y repetir validacion de la pose/par `z` bajo mejor control mecanico.
