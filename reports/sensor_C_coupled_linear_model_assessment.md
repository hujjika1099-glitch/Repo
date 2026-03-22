# Fase 10.7 - Evaluacion de Modelo Lineal Acoplado para sensor_C

Fecha: 2026-03-22

## 1) Objetivo de la fase

Evaluar si un modelo lineal acoplado en dominio mV explica mejor las 6 poses estaticas de `sensor_C` que:

1. el modelo simple por eje (calibracion base),
2. y cualquier hipotesis simple de permutacion+signo de Fase 10.6.

Sin nuevas capturas y usando exclusivamente dataset ya existente.

## 2) Dataset exacto usado

- Dataset fijo base:
  - `reports/analysis_outputs/sensor_C_axis_mapping_search_dataset_20260322_121904.csv`
- Manifest trazable de esta fase:
  - `reports/analysis_outputs/sensor_C_coupled_model_dataset_20260322_131311.csv`
- Manifest final registrado en fit:
  - `reports/analysis_outputs/sensor_C_coupled_model_dataset_20260322_131829.csv`
- Cobertura:
  - 18 corridas (3 por pose): `pos_x`, `neg_x`, `pos_y`, `neg_y`, `pos_z`, `neg_z`.

## 3) Formulacion matematica

Modelo principal (mV):

`g_est = A * v + c`

donde:
- `v = [mv_x, mv_y, mv_z]^T`
- `A` es 3x3
- `c` es 3x1

Forma equivalente:

`g_est = M * (v - b)`

con:
- `M = A`
- `b = -A^{-1} c` (en esta fase fue invertible y se uso `inverse`).

## 4) Coeficientes finales (modelo mV)

Fuente:
- `data/processed/sensor_C_coupled_linear_model_20260322_131829.csv`

`A_mv`:

```text
[ -2.4923e-05  -1.1855e-01   1.1782e-01
  -4.7142e-06   1.1872e-01  -1.1566e-01
   1.0814e-04  -1.3648e-01   1.3912e-01 ]
```

`c_mv`:

```text
[  1.072284
  -4.207539
  -3.907049 ]
```

`b_mv` (forma equivalente):

```text
[ 2621.215546
  1377.254871
  1377.224628 ]
```

Estabilidad numerica:
- `is_invertible = true`
- `cond_A = 5393.790652`
- `rcond_A = 0.000177428`

## 5) Calidad de ajuste interno (fit)

Fuente:
- `reports/analysis_outputs/sensor_C_coupled_linear_model_20260322_131829.txt`

- `rmse_x = 0.563454779`
- `rmse_y = 0.418587612`
- `rmse_z = 0.402393228`
- `rmse_overall = 0.467124961`
- `total_seq_jumps = 0`

## 6) Validacion por pose (modelo acoplado)

Fuente:
- `data/processed/sensor_C_coupled_linear_validation_20260322_132133_poses.csv`

| Pose | mean_gnorm | mean_error_gnorm | dominant_axis | axis_match | sign_match | exact_match |
|---|---:|---:|---|---:|---:|---:|
| pos_x | 0.443700 | 0.556300 | y | 0 | 0 | 0 |
| neg_x | 0.127026 | 0.872974 | z | 0 | 0 | 0 |
| pos_y | 0.660889 | 0.339111 | y | 1 | 1 | 1 |
| neg_y | 0.652800 | 0.347200 | y | 1 | 1 | 1 |
| pos_z | 0.854225 | 0.145775 | z | 1 | 1 | 1 |
| neg_z | 0.505407 | 0.494593 | z | 1 | 1 | 1 |

Resumen:
- `coupled_exact_pose_count = 4/6`
- mejoria fuerte en `pos_z` y `neg_z`
- `pos_x` y `neg_x` siguen flojas.

## 7) Validacion por pares (modelo acoplado)

Fuente:
- `reports/analysis_outputs/sensor_C_coupled_linear_validation_20260322_132133_pairs.csv`

| Pair | dominant_pair_axis | pair_axis_match | pair_sign_opposition_ok | pair_dominance_ratio |
|---|---|---:|---:|---:|
| x_pair | y | 0 | 0 | 0.420853 |
| y_pair | y | 1 | 1 | 1.136072 |
| z_pair | z | 1 | 1 | 1.231598 |

Resumen:
- `pair_axis_match_count = 2/3`
- `pair_sign_opposition_count = 2/3`
- `avg_pair_dominance_ratio = 0.929508` (todavia por debajo de 1 en promedio por debilidad de `x_pair`).

## 8) Comparacion contra modelo simple (baseline Fase 10)

Referencias:
- Modelo simple: `data/processed/sensor_C_static_calibration_20260321_140044.mat`
- Comparacion por pose: `reports/analysis_outputs/sensor_C_coupled_linear_validation_20260322_132133_comparison_vs_simple.csv`

Global:
- `simple global mean |g| err = 2.411084848`
- `coupled global mean |g| err = 0.459325738`
- mejora global (`simple - coupled`) = `+1.951759110`

Poses mas problematicas del simple (mejoradas con coupled):
- `pos_z`: `delta_mean_abs_gnorm_err = -3.173396060`
- `neg_z`: `delta_mean_abs_gnorm_err = -2.802091328`

Interpretacion:
- El modelo acoplado reduce de forma importante error de norma y cross-axis frente al simple, pero no corrige completamente el par X.

## 9) Comparacion conceptual contra mejor modelo simple de Fase 10.6

Referencias:
- `reports/analysis_outputs/sensor_C_axis_mapping_disambiguation_20260322_130308.txt`
- `reports/analysis_outputs/sensor_C_axis_mapping_disambiguation_20260322_130308_hypotheses.csv`

Mejor simple (Fase 10.6):
- `best_hypothesis_id = 39`
- `score_gap = 1.300068`
- `best_vs_null_p95 = -1.624956`
- `pair_axis_match_count = 1`
- decision de fase simple: `mapping_not_supported`

Comparacion:
- modelo acoplado supera claramente al simple en error global y en pares (`2/3` vs `1/3` en eje dominante correcto),
- pero no alcanza solidez suficiente para considerarlo baseline productivo robusto.

## 10) Decision final operativa

- `coupled_model_weak`

## 11) Recomendacion inmediata

- Si se usa, que sea como **capa de interpretacion exploratoria**, no como baseline productivo final.
- Aun no conviene promover `sensor_C` a `pass`.
- Mantener estado `suspect` hasta resolver debilidad estructural en `x_pair`.

## 12) Artefactos generados en esta fase

- Fit:
  - `data/processed/sensor_C_coupled_linear_model_20260322_131829.csv`
  - `data/processed/sensor_C_coupled_linear_model_20260322_131829.mat`
  - `reports/analysis_outputs/sensor_C_coupled_model_dataset_20260322_131829.csv`
  - `reports/analysis_outputs/sensor_C_coupled_linear_model_20260322_131829_runs.csv`
  - `reports/analysis_outputs/sensor_C_coupled_linear_model_20260322_131829_poses.csv`
  - `reports/analysis_outputs/sensor_C_coupled_linear_model_20260322_131829.txt`
- Validacion:
  - `data/processed/sensor_C_coupled_linear_validation_20260322_132133.csv`
  - `data/processed/sensor_C_coupled_linear_validation_20260322_132133_poses.csv`
  - `reports/analysis_outputs/sensor_C_coupled_linear_validation_20260322_132133_comparison_vs_simple.csv`
  - `reports/analysis_outputs/sensor_C_coupled_linear_validation_20260322_132133_pairs.csv`
  - `reports/analysis_outputs/sensor_C_coupled_linear_validation_20260322_132133.txt`
