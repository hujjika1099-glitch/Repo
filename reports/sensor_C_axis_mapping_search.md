# Fase 10.5 - Busqueda Exhaustiva de Hipotesis de Mapeo/Signo para sensor_C

Fecha: 2026-03-22

## Objetivo

Identificar automaticamente el mejor mapeo canal-eje y combinacion de signos para `sensor_C` usando solo datasets historicos ya capturados, sin nuevas adquisiciones.

## Dataset exacto usado

- Manifest de esta fase:
  - `reports/analysis_outputs/sensor_C_axis_mapping_search_dataset_20260322_121904.csv`
- Origen del manifest:
  - copia trazable del dataset reforzado de Fase 10.4 (18 corridas, 3 por pose).
- Poses incluidas:
  - `pos_x`, `neg_x`, `pos_y`, `neg_y`, `pos_z`, `neg_z`

## Convencion fisica aplicada

- `axis+`: eje positivo del modulo en sentido contrario a gravedad.
- `axis-`: eje positivo del modulo en el mismo sentido de gravedad.
- Targets fisicos ideales:
  - `pos_x -> [+1, 0, 0]`, `neg_x -> [-1, 0, 0]`
  - `pos_y -> [0, +1, 0]`, `neg_y -> [0, -1, 0]`
  - `pos_z -> [0, 0, +1]`, `neg_z -> [0, 0, -1]`

## Espacio de busqueda

- Permutaciones de ejes: 6
- Combinaciones de signo: 8
- Total de hipotesis evaluadas: `48`

Script principal:
- `matlab/analysis/search_sensorC_axis_mapping_hypotheses.m`

## Metricas y score global

Por hipotesis se calcula:

- Error de norma (`overall_mean_abs_gnorm_err`, `overall_max_abs_gnorm_err`)
- Integridad de secuencia (`total_seq_jumps`)
- Coherencia por pose (`pose_axis_match_count`, `pose_sign_match_count`, `exact_pose_match_count`)
- Fuerza de eje esperado (`average_expected_axis_strength`)
- Contaminacion cruzada (`average_cross_axis_abs`)

Formula implementada:

`score = 100*(0.23*norm_mean + 0.10*norm_max + 0.15*expected_axis_strength + 0.10*cross_axis_term + 0.14*axis_match + 0.10*sign_match + 0.10*exact_match + 0.04*seq_term + 0.04*sens_term)`

Donde:

- `norm_mean = 1/(1+overall_mean_abs_gnorm_err)`
- `norm_max = 1/(1+overall_max_abs_gnorm_err)`
- `expected_axis_strength = clamp((avg_expected_axis_strength+1)/2,0,1)`
- `cross_axis_term = 1/(1+avg_cross_axis_abs)`
- `axis_match = pose_axis_match_count/6`
- `sign_match = pose_sign_match_count/6`
- `exact_match = exact_pose_match_count/6`
- `seq_term = 1/(1+total_seq_jumps)`
- `sens_term = 1/(1+invalid_sensitivity_count)`

## Top 10 hipotesis

Artefacto fuente:
- `reports/analysis_outputs/sensor_C_axis_mapping_search_20260322_122519_top10.csv`

| Rank | hypothesis_id | mapping | signs | overall_mean_abs_gnorm_err | average_expected_axis_strength | average_cross_axis_abs | exact_pose_match_count | score_global |
|---|---:|---|---|---:|---:|---:|---:|---:|
| 1 | 41 | `phys_x<=mv_x,phys_y<=mv_y,phys_z<=mv_z` | `[-1,-1,-1]` | 10.540518 | 1.000000 | 5.820154 | 3 | 48.784647 |
| 2 | 42 | `phys_x<=mv_x,phys_y<=mv_y,phys_z<=mv_z` | `[+1,-1,-1]` | 10.540518 | 1.000000 | 5.820154 | 3 | 48.784647 |
| 3 | 43 | `phys_x<=mv_x,phys_y<=mv_y,phys_z<=mv_z` | `[-1,+1,-1]` | 10.540518 | 1.000000 | 5.820154 | 3 | 48.784647 |
| 4 | 44 | `phys_x<=mv_x,phys_y<=mv_y,phys_z<=mv_z` | `[+1,+1,-1]` | 10.540518 | 1.000000 | 5.820154 | 3 | 48.784647 |
| 5 | 45 | `phys_x<=mv_x,phys_y<=mv_y,phys_z<=mv_z` | `[-1,-1,+1]` | 10.540518 | 1.000000 | 5.820154 | 3 | 48.784647 |
| 6 | 46 | `phys_x<=mv_x,phys_y<=mv_y,phys_z<=mv_z` | `[+1,-1,+1]` | 10.540518 | 1.000000 | 5.820154 | 3 | 48.784647 |
| 7 | 47 | `phys_x<=mv_x,phys_y<=mv_y,phys_z<=mv_z` | `[-1,+1,+1]` | 10.540518 | 1.000000 | 5.820154 | 3 | 48.784647 |
| 8 | 48 | `phys_x<=mv_x,phys_y<=mv_y,phys_z<=mv_z` | `[+1,+1,+1]` | 10.540518 | 1.000000 | 5.820154 | 3 | 48.784647 |
| 9 | 33 | `phys_x<=mv_x,phys_y<=mv_z,phys_z<=mv_y` | `[-1,-1,-1]` | 10.540956 | 1.000000 | 5.822004 | 3 | 48.784172 |
| 10 | 34 | `phys_x<=mv_x,phys_y<=mv_z,phys_z<=mv_y` | `[+1,-1,-1]` | 10.540956 | 1.000000 | 5.822004 | 3 | 48.784172 |

## Mejor hipotesis encontrada

- `BEST_HYPOTHESIS_ID: 41`
- Mapping:
  - `phys_x<=mv_x, phys_y<=mv_y, phys_z<=mv_z`
- Signs:
  - `[-1,-1,-1]`
- Score:
  - `48.784647`

Interpretacion tecnica:

- La mejor hipotesis no separa claramente el problema: empata exactamente con 7 variantes de signo sobre el mismo mapping y queda muy cerca de otras hipotesis con permuta parcial.
- El empate (`score_gap = 0`) indica que con este dataset y este scoring la identificacion no es univoca.
- Los errores de norma siguen muy altos (`overall_mean_abs_gnorm_err ~ 10.54`), por lo que el mejor ajuste de mapeo/signo no explica fisicamente bien el conjunto completo.

## Comparacion explicita contra Fase 10.4

- Fase 10.4 concluyo `mapping_inconclusive` con analisis por pose/par.
- Esta fase agrega busqueda exhaustiva global (48 hipotesis), pero el resultado sigue sin separacion robusta:
  - empate en top ranking,
  - solo 3/6 `exact_pose_match_count`,
  - errores de norma elevados.

Conclusion comparativa:

- La ambiguedad observada en Fase 10.4 persiste incluso con busqueda exhaustiva software-only.
- El problema no queda explicado unicamente por una permutacion+signo simple.

## Decision final operativa

- `mapping_ambiguous`

## Recomendacion inmediata

- No actualizar todavia scripts de calibracion/validacion para fijar un remapeo definitivo.
- Mantener el estado de `sensor_C` como `calibrated_review_needed`/`suspect` hasta introducir una fase de desambiguacion analitica adicional (con restricciones fisicas mas fuertes en el scoring y/o criterios de consistencia por eje mas estrictos) antes de recalibrar.

## Artefactos generados en esta fase

- `reports/analysis_outputs/sensor_C_axis_mapping_search_dataset_20260322_121904.csv`
- `reports/analysis_outputs/sensor_C_axis_mapping_search_20260322_122519_hypotheses.csv`
- `reports/analysis_outputs/sensor_C_axis_mapping_search_20260322_122519_top10.csv`
- `reports/analysis_outputs/sensor_C_axis_mapping_search_20260322_122519_best_runs.csv`
- `reports/analysis_outputs/sensor_C_axis_mapping_search_20260322_122519_best_poses.csv`
- `reports/analysis_outputs/sensor_C_axis_mapping_search_20260322_122519.txt`
