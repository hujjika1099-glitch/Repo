# Fase 10.8 - Evaluacion de Modelo Acoplado Regularizado para sensor_C

Fecha: 2026-03-22

## 1) Objetivo de la fase

Evaluar si el modelo acoplado lineal mejora su robustez y generalizacion interna al imponer regularizacion ridge, sin nuevas capturas y usando exactamente el mismo dataset de la fase acoplada previa.

## 2) Dataset exacto usado

- Fuente fija obligatoria:
  - `reports/analysis_outputs/sensor_C_coupled_model_dataset_20260322_131829.csv`
- Manifest trazable de esta fase:
  - `reports/analysis_outputs/sensor_C_coupled_robust_dataset_20260322_135412.csv`
- Cobertura:
  - 18 corridas, 3 por pose (`pos_x`, `neg_x`, `pos_y`, `neg_y`, `pos_z`, `neg_z`).

## 3) Formulacion del modelo regularizado

Modelo principal:

- `g = A * v + c`
- `v = [mv_x mv_y mv_z]^T`

Ajuste por lambda con ridge/Tikhonov:

- `min_B ||X*B - Y||^2 + lambda * ||W*B||^2`
- `W = diag([1 1 1 0])` (no penaliza intercepto)
- `B` contiene coeficientes de `A` e intercepto `c`.

## 4) Lambdas probados

`[0, 1e-4, 1e-3, 1e-2, 1e-1, 1, 10]`

Artefactos de candidatos:

- `reports/analysis_outputs/sensor_C_coupled_regularized_candidates_20260322_135412.csv`
- `reports/analysis_outputs/sensor_C_coupled_regularized_selection_20260322_135643.csv`

## 5) Criterio de seleccion

Se uso score compuesto priorizando generalizacion y consistencia por pares:

- `score_global = 0.30*cv_pair_axis + 0.20*cv_pair_sign + 0.15*cv_pair_dom + 0.15*cv_err + 0.08*cv_cross + 0.07*fit_err + 0.05*stability`

Donde:

- `cv_pair_axis = cv_pair_axis_match_count / 3`
- `cv_pair_sign = cv_pair_sign_opposition_count / 3`
- `cv_pair_dom = min(cv_avg_pair_dominance_ratio, 2) / 2`
- `cv_err = 1 / (1 + cv_mean_abs_gnorm_err)`
- `cv_cross = 1 / (1 + cv_cross_axis_abs_mean)`
- `fit_err = 1 / (1 + rmse_overall)`
- `stability` deriva de `rcond_A`.

## 6) Ranking resumido de candidatos

Top 3 por `score_global`:

1. `lambda = 1`:
   - `score_global = 0.602186885`
   - `cv_mean_abs_gnorm_err = 0.382783998`
   - `cv_pair_axis_match_count = 1.3333`
   - `cv_pair_sign_opposition_count = 2.0000`
2. `lambda = 0`:
   - `score_global = 0.600969504`
   - `cv_mean_abs_gnorm_err = 0.340061312`
   - `cv_pair_axis_match_count = 1.3333`
   - `cv_pair_sign_opposition_count = 1.6667`
3. `lambda = 1e-4`:
   - `score_global = 0.600965593`
   - `cv_mean_abs_gnorm_err = 0.340065024`
   - `cv_pair_axis_match_count = 1.3333`
   - `cv_pair_sign_opposition_count = 1.6667`

Resultado de seleccion:

- `lambda seleccionado = 1`

## 7) Coeficientes del modelo ganador

Fuente:

- `data/processed/sensor_C_coupled_regularized_model_20260322_135643.csv`

`A_mv`:

```text
[-2.629840e-05  -1.034391e-01   1.027383e-01
 -3.349945e-06   1.037387e-01  -1.007047e-01
  1.065335e-04  -1.188678e-01   1.215343e-01]
```

`c_mv`:

```text
[ 1.037232
 -4.172777
 -3.947912 ]
```

`b_mv` (forma equivalente):

```text
[2621.215546
 1377.254871
 1377.224628]
```

## 8) Ajuste interno

- `rmse_overall = 0.467331136`
- `cond_A = 4704.865627`
- `rcond_A = 0.000203390`
- `seq_jumps_total = 0`

## 9) Validacion por pose (modelo regularizado)

Fuente:

- `data/processed/sensor_C_coupled_regularized_validation_20260322_135643_poses.csv`

| Pose | mean_error_gnorm | dominant_axis | axis_match | sign_match | exact_match |
|---|---:|---|---:|---:|---:|
| pos_x | 0.584117 | y | 0 | 0 | 0 |
| neg_x | 0.881279 | z | 0 | 0 | 0 |
| pos_y | 0.340384 | y | 1 | 1 | 1 |
| neg_y | 0.353428 | y | 1 | 1 | 1 |
| pos_z | 0.150792 | z | 1 | 1 | 1 |
| neg_z | 0.498709 | z | 1 | 1 | 1 |

## 10) Validacion por pares

Fuente:

- `reports/analysis_outputs/sensor_C_coupled_regularized_validation_20260322_135643_pairs.csv`

| Pair | pair_axis_match | pair_sign_opposition_ok | pair_dominance_ratio |
|---|---:|---:|---:|
| x_pair | 0 | 0 | 0.399138 |
| y_pair | 1 | 1 | 1.113981 |
| z_pair | 1 | 1 | 1.204826 |

Resumen:

- `pair_axis_match_count = 2/3`
- `pair_sign_opposition_count = 2/3`
- `avg_pair_dominance_ratio = 0.905982`

## 11) Generalizacion interna (CV)

Desde la fila seleccionada (`lambda=1`):

- `cv_n_folds = 3`
- `cv_mean_abs_gnorm_err = 0.382783998`
- `cv_max_abs_gnorm_err = 0.857487977`
- `cv_pair_axis_match_count = 1.3333`
- `cv_pair_sign_opposition_count = 2.0000`
- `cv_avg_pair_dominance_ratio = 1.093699`

## 12) Comparacion vs acoplado actual (Fase 10.7)

Fuente:

- `reports/analysis_outputs/sensor_C_coupled_regularized_validation_20260322_135643_comparison_vs_current_coupled.csv`

Cambios clave (regularizado - actual):

- `global_mean_abs_gnorm_err`: `+0.008793` (empeora)
- `global_max_abs_gnorm_err`: `+0.006460` (empeora)
- `exact_pose_match_count`: `0` (sin mejora)
- `pair_axis_match_count`: `0` (sin mejora)
- `pair_sign_opposition_count`: `0` (sin mejora)
- `avg_pair_dominance_ratio`: `-0.023526` (empeora)
- `mean_expected_axis`: `-0.004526` (empeora)
- `mean_cross_axis_abs`: `-0.001874` (mejora leve)
- estabilidad numerica (`cond_A`, `rcond_A`): mejora leve.

## 13) Comparacion vs simple

Fuente:

- `reports/analysis_outputs/sensor_C_coupled_regularized_validation_20260322_135643_comparison_vs_simple.csv`

Fila global:

- `simple_mean_abs_gnorm_err = 0.097113`
- `coupled_current_mean_abs_gnorm_err = 0.459326`
- `coupled_regularized_mean_abs_gnorm_err = 0.468118`

Comparacion regularizado vs simple:

- `delta_mean_abs_gnorm_err_reg_vs_simple = +0.371005` (peor)

Comparacion regularizado vs acoplado actual:

- `delta_mean_abs_gnorm_err_reg_vs_current = +0.008793` (peor)

## 14) Decision final operativa

- `coupled_model_not_supported`

## 15) Recomendacion inmediata

- No promover el modelo acoplado regularizado como baseline.
- Mantener `sensor_C` en estado `suspect` para interpretacion software-only.
- Si se continua en software, el siguiente paso debe ser un modelo no lineal o estrategia fisica/metrologica distinta; no hay evidencia de mejora robusta con regularizacion lineal.

