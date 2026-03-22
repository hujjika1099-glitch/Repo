# Fase 10.6 - Desambiguacion Fisica de Mapeo/Signo para sensor_C

Fecha: 2026-03-22

## 1) Objetivo de la fase

Desambiguar software-only el mapeo/signo de `sensor_C` usando el dataset historico ya capturado, con un scoring fisico mas estricto que la fase anterior y sin nuevas capturas.

## 2) Dataset exacto usado

- Dataset base (misma seleccion de Fase 10.5):
  - `reports/analysis_outputs/sensor_C_axis_mapping_search_dataset_20260322_121904.csv`
- Manifest trazable de esta fase:
  - `reports/analysis_outputs/sensor_C_axis_mapping_disambiguation_dataset_20260322_125115.csv`
- Cobertura:
  - 18 corridas (3 por pose) en `pos_x, neg_x, pos_y, neg_y, pos_z, neg_z`.

## 3) Resumen del problema heredado (Fase 10.5)

- `mapping_ambiguous`
- `score_gap = 0`
- empate entre varias hipotesis lideres
- `exact_pose_match_count = 3/6`
- errores de norma altos

## 4) Nuevo enfoque de scoring fisico

Script:
- `matlab/analysis/disambiguate_sensorC_axis_mapping_physical.m`

Espacio de busqueda:
- 48 hipotesis (6 permutaciones x 8 signos)
- colapso adicional por familias (6 permutaciones)

Metricas reforzadas:
- por pose: alineacion de eje/signo esperado, error de norma, contaminacion cruzada
- por par (`x_pair`, `y_pair`, `z_pair`): dominancia por eje esperado, oposicion de signo, ratio de separacion
- crudas en mV por par: signo de delta esperado y ratio de dominancia antes de normalizar a g

Score base:

`base = 100*(0.08*norm_mean + 0.05*norm_max + 0.10*pose_axis + 0.07*pose_exact + 0.14*pair_axis + 0.14*pair_sign + 0.11*pair_dom_avg + 0.10*pair_dom_worst + 0.07*expected_axis + 0.06*cross_axis + 0.05*raw_pair_sign + 0.02*raw_pair_dom + 0.01*seq_term)`

Score final:

`score_global = base + 6*family_rank_metric + 3*family_gap_bonus - 4*family_tie_penalty`

Referencia nula:
- aleatorizacion de labels de pose (`400` iteraciones) usando la mejor hipotesis como plantilla para medir mejora real vs estructura no informativa.

## 5) Top 10 hipotesis

Fuente:
- `reports/analysis_outputs/sensor_C_axis_mapping_disambiguation_20260322_130308_top10.csv`

| Rank | hypothesis_id | mapping | signs | base_score | score_global | pair_axis_match_count | pair_sign_opposition_count | avg_pair_dominance_ratio | exact_pose_match_count |
|---|---:|---|---|---:|---:|---:|---:|---:|---:|
| 1 | 39 | `phys_x<=mv_x,phys_y<=mv_z,phys_z<=mv_y` | `[-1,+1,+1]` | 50.1693 | 57.1693 | 1 | 3 | 2.1197 | 3 |
| 2 | 47 | `phys_x<=mv_x,phys_y<=mv_y,phys_z<=mv_z` | `[-1,+1,+1]` | 50.0692 | 55.8692 | 1 | 3 | 2.1056 | 3 |
| 3 | 35 | `phys_x<=mv_x,phys_y<=mv_z,phys_z<=mv_y` | `[-1,+1,-1]` | 48.5026 | 55.5026 | 1 | 3 | 2.1197 | 3 |
| 4 | 37 | `phys_x<=mv_x,phys_y<=mv_z,phys_z<=mv_y` | `[-1,-1,+1]` | 48.5026 | 55.5026 | 1 | 3 | 2.1197 | 3 |
| 5 | 40 | `phys_x<=mv_x,phys_y<=mv_z,phys_z<=mv_y` | `[+1,+1,+1]` | 48.5026 | 55.5026 | 1 | 3 | 2.1197 | 3 |
| 6 | 43 | `phys_x<=mv_x,phys_y<=mv_y,phys_z<=mv_z` | `[-1,+1,-1]` | 48.4025 | 54.2025 | 1 | 3 | 2.1056 | 3 |
| 7 | 45 | `phys_x<=mv_x,phys_y<=mv_y,phys_z<=mv_z` | `[-1,-1,+1]` | 48.4025 | 54.2025 | 1 | 3 | 2.1056 | 3 |
| 8 | 48 | `phys_x<=mv_x,phys_y<=mv_y,phys_z<=mv_z` | `[+1,+1,+1]` | 48.4025 | 54.2025 | 1 | 3 | 2.1056 | 3 |
| 9 | 33 | `phys_x<=mv_x,phys_y<=mv_z,phys_z<=mv_y` | `[-1,-1,-1]` | 46.8359 | 53.8359 | 1 | 3 | 2.1197 | 3 |
| 10 | 36 | `phys_x<=mv_x,phys_y<=mv_z,phys_z<=mv_y` | `[+1,+1,-1]` | 46.8359 | 53.8359 | 1 | 3 | 2.1197 | 3 |

## 6) Ranking por familias de permutacion

Fuente:
- `reports/analysis_outputs/sensor_C_axis_mapping_disambiguation_20260322_130308_families.csv`

| Rank | Family (perm) | family_best_hypothesis_id | family_best_sign | family_best_score | family_second_best_score | family_score_gap | family_tie_count_eps |
|---|---|---:|---|---:|---:|---:|---:|
| 1 | `phys_x<=mv_x,phys_y<=mv_z,phys_z<=mv_y` | 39 | `[-1,+1,+1]` | 57.1693 | 55.5026 | 1.6667 | 1 |
| 2 | `phys_x<=mv_x,phys_y<=mv_y,phys_z<=mv_z` | 47 | `[-1,+1,+1]` | 55.8692 | 54.2025 | 1.6667 | 1 |
| 3 | `phys_x<=mv_y,phys_y<=mv_z,phys_z<=mv_x` | 23 | `[-1,+1,+1]` | 44.2109 | 42.5442 | 1.6667 | 1 |
| 4 | `phys_x<=mv_z,phys_y<=mv_y,phys_z<=mv_x` | 7 | `[-1,+1,+1]` | 42.9905 | 41.3238 | 1.6667 | 1 |
| 5 | `phys_x<=mv_y,phys_y<=mv_x,phys_z<=mv_z` | 31 | `[-1,+1,+1]` | 35.2960 | 33.6293 | 1.6667 | 1 |
| 6 | `phys_x<=mv_z,phys_y<=mv_x,phys_z<=mv_y` | 15 | `[-1,+1,+1]` | 34.0935 | 32.4268 | 1.6667 | 1 |

## 7) Mejor hipotesis individual

- `hypothesis_id = 39`
- `mapping = phys_x<=mv_x, phys_y<=mv_z, phys_z<=mv_y`
- `signs = [-1,+1,+1]`
- `base_score = 50.1693`
- `score_global = 57.1693`

## 8) Mejor familia

- `perm_index = 5`
- Family winner:
  - `phys_x<=mv_x,phys_y<=mv_z,phys_z<=mv_y`
- `family_best_score = 57.1693`
- `family_score_gap vs #2 = 1.3001` (margen bajo).

## 9) Resultado por pares (mejor hipotesis)

Fuente:
- `reports/analysis_outputs/sensor_C_axis_mapping_disambiguation_20260322_130308_best_pairs.csv`

| Pair | dominant_pair_axis | pair_axis_match | pair_sign_opposition_ok | pair_dominance_ratio | raw_pair_sign_ok |
|---|---|---:|---:|---:|---:|
| x_pair | x | 1 | 1 | 5.4689 | 1 |
| y_pair | x | 0 | 1 | 0.6041 | 1 |
| z_pair | x | 0 | 1 | 0.2860 | 1 |

Lectura tecnica:
- solo `1/3` pares con eje dominante correcto (`pair_axis_match_count = 1`),
- `y_pair` y `z_pair` siguen dominados por `x`, por eso no hay soporte fisico suficiente para aceptar un mapeo simple.

## 10) Comparacion explicita contra Fase 10.5

- Fase 10.5: empate total (`score_gap=0`) y `mapping_ambiguous`.
- Fase 10.6: se rompe parcialmente el empate y aparece ranking por familias, pero:
  - `score_gap` sigue bajo (`1.3001`),
  - `pair_axis_match_count` permanece bajo (`1/3`),
  - contra baseline nulo:
    - `best_base_score = 50.1693`
    - `null_score_p95 = 51.7942`
    - `best_vs_null_p95 = -1.6250` (no supera referencia nula exigente).

## 11) Decision final operativa

- `mapping_not_supported`

## 12) Recomendacion inmediata

- **No conviene** modificar aun scripts de calibracion para fijar remapeo/signo definitivo.
- Mantener `sensor_C` en estado `calibrated_review_needed / suspect` mientras no exista evidencia de soporte fisico superior a la referencia nula.

