# Calibracion Final Estatica de sensor_C (Fase 10)

Fecha: 2026-03-21

## Dataset exacto usado

### pos_x (3, Fase 9)
1. `data/raw/sensor_C/sensor_C_pos_x_20260321_103048.csv`
2. `data/raw/sensor_C/sensor_C_pos_x_20260321_103224.csv`
3. `data/raw/sensor_C/sensor_C_pos_x_20260321_103405.csv`

### neg_x (3, Fase 9)
1. `data/raw/sensor_C/sensor_C_neg_x_20260321_104116.csv`
2. `data/raw/sensor_C/sensor_C_neg_x_20260321_104255.csv`
3. `data/raw/sensor_C/sensor_C_neg_x_20260321_104434.csv`

### pos_y (3, Fase 9)
1. `data/raw/sensor_C/sensor_C_pos_y_20260321_105150.csv`
2. `data/raw/sensor_C/sensor_C_pos_y_20260321_105330.csv`
3. `data/raw/sensor_C/sensor_C_pos_y_20260321_105508.csv`

### neg_y (3, Fase 9)
1. `data/raw/sensor_C/sensor_C_neg_y_20260321_110157.csv`
2. `data/raw/sensor_C/sensor_C_neg_y_20260321_110339.csv`
3. `data/raw/sensor_C/sensor_C_neg_y_20260321_110521.csv`

### pos_z (5, Fase 9.2)
1. `data/raw/sensor_C/sensor_C_pos_z_20260321_131713.csv`
2. `data/raw/sensor_C/sensor_C_pos_z_20260321_131840.csv`
3. `data/raw/sensor_C/sensor_C_pos_z_20260321_132019.csv`
4. `data/raw/sensor_C/sensor_C_pos_z_20260321_132204.csv`
5. `data/raw/sensor_C/sensor_C_pos_z_20260321_132349.csv`

### neg_z (5, Fase 9.2)
1. `data/raw/sensor_C/sensor_C_neg_z_20260321_132804.csv`
2. `data/raw/sensor_C/sensor_C_neg_z_20260321_132949.csv`
3. `data/raw/sensor_C/sensor_C_neg_z_20260321_133129.csv`
4. `data/raw/sensor_C/sensor_C_neg_z_20260321_133305.csv`
5. `data/raw/sensor_C/sensor_C_neg_z_20260321_133454.csv`

Total de corridas en calibracion: 22.

## Metodo de calculo aplicado

Se uso calibracion estatica por eje con midpoint/delta entre pose positiva y negativa:

- `offset_axis = (mean_pos_axis + mean_neg_axis) / 2`
- `sens_axis_per_g = (mean_pos_axis - mean_neg_axis) / 2`

Aplicado en dos dominios:
- `raw ADC`
- `mV`

## Coeficientes finales

Fuente: `data/processed/sensor_C_static_calibration_20260321_140044.csv`

| Eje | offset_raw | sens_raw_per_g | offset_mv | sens_mv_per_g |
|---|---:|---:|---:|---:|
| x | 1884.366872 | -398.674275 | 1699.076903 | -329.277105 |
| y | 1768.889444 | -359.333779 | 1603.365121 | -296.372500 |
| z | 1837.731552 | 245.812325 | 1660.355330 | 202.712173 |

Nota: las sensibilidades de `x` y `y` quedan negativas por la convencion de orientacion/cableado usada en las corridas de referencia.

## Ecuaciones finales de conversion

Modelo recomendado (mV):
- `g_x = (mv_x - 1699.076902581) / (-329.277104964)`
- `g_y = (mv_y - 1603.365121373) / (-296.372500046)`
- `g_z = (mv_z - 1660.355330002) / (202.712173016)`

Modelo alterno (raw):
- `g_x = (raw_x - 1884.366872073) / (-398.674274875)`
- `g_y = (raw_y - 1768.889443543) / (-359.333779229)`
- `g_z = (raw_z - 1837.731552018) / (245.812325252)`

## Validacion cruzada

Artefactos:
- `data/processed/sensor_C_static_validation_20260321_140524.csv` (por corrida)
- `data/processed/sensor_C_static_validation_20260321_140524_poses.csv` (resumen por pose)
- `reports/analysis_outputs/sensor_C_static_validation_20260321_140524.txt`

Resumen por pose (modelo en mV):

| Pose | runs_found | mean_gx | mean_gy | mean_gz | mean_|g| | mean_error_|g| | max_error_|g| | seq_jumps_total |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| pos_x | 3 | 1.000000 | -0.171594 | 0.000233 | 1.018807 | 0.033719 | 0.367897 | 0 |
| neg_x | 3 | -1.000000 | -0.166927 | 0.078986 | 1.020893 | 0.033625 | 0.402362 | 0 |
| pos_y | 3 | 0.040893 | 1.000000 | -0.010591 | 1.004251 | 0.030053 | 0.501694 | 0 |
| neg_y | 3 | -0.053802 | -1.000000 | 0.654727 | 1.200240 | 0.201351 | 0.635688 | 0 |
| pos_z | 5 | -0.284306 | -0.605219 | 1.000000 | 1.205531 | 0.206731 | 0.702882 | 0 |
| neg_z | 5 | -0.301159 | 0.119587 | -1.000000 | 1.056233 | 0.077199 | 0.553136 | 0 |

## Observaciones tecnicas

- Integridad de stream satisfactoria en todo el set (`seq_jumps_total = 0` en las 6 poses).
- El eje esperado por pose queda consistente (alineacion de signo y dominancia por eje objetivo).
- La norma `|g|` presenta sesgo en `neg_y` y `pos_z`, indicando acoplamiento entre ejes que no queda totalmente corregido con modelo lineal por eje independiente.

## Decision final

- `calibrated_but_review_needed`
- `ready_for_next_stage = no` (se recomienda revision mecanica/metodologica antes de cerrar como calibracion definitiva de produccion).

## Recomendacion de uso del modelo

- Usar **modelo en mV** como principal para analisis y conversion a `g`.
- Conservar el modelo en `raw` como respaldo tecnico/comparativo.
