# Fase 10.3 - Diagnostico de Convencion de Ejes/Signos para sensor_C

Fecha: 2026-03-22

## Convencion fisica declarada por operador

- `axis+`: el eje positivo del modulo apunta contra la gravedad.
- `axis-`: el eje positivo del modulo apunta a favor de la gravedad.
- Poses usadas: `pos_x`, `neg_x`, `pos_y`, `neg_y`, `pos_z`, `neg_z`.

## Protocolo ejecutado

- Sensor: `sensor_C` (misma ESP32 de referencia, mismo firmware baseline, mismo `COM5`).
- Corridas por pose: 2.
- Duracion por corrida: 8 s.
- Estabilizacion previa por corrida: 15 s reales.
- Integridad de stream: `seq_jumps = 0` en las 12 corridas.

## Corridas nuevas usadas en el diagnostico

Dataset reproducible:
- `reports/analysis_outputs/sensor_C_axis_convention_dataset_phase103.csv`

Nota de control:
- Se excluyeron explicitamente estas corridas `neg_x` por movimiento detectado del sensor:
  - `sensor_C_neg_x_20260322_101532.csv`
  - `sensor_C_neg_x_20260322_101703.csv`

## Artefactos del analisis

- `reports/analysis_outputs/sensor_C_axis_convention_diagnosis_20260322_105051_runs.csv`
- `reports/analysis_outputs/sensor_C_axis_convention_diagnosis_20260322_105051_poses.csv`
- `reports/analysis_outputs/sensor_C_axis_convention_diagnosis_20260322_105051_inference.csv`
- `reports/analysis_outputs/sensor_C_axis_convention_diagnosis_20260322_105051_axis_pairs.csv`
- `reports/analysis_outputs/sensor_C_axis_convention_diagnosis_20260322_105051.txt`

## Tabla de medias por pose (mV)

| Pose | runs_found | mv_x_mean | mv_y_mean | mv_z_mean | canal_dominante | signo_obs | ratio_dom | estado |
|---|---:|---:|---:|---:|---|---:|---:|---|
| pos_x | 2 | 2037.091 | 490.307 | 488.391 | x | +1 | 4.155 | ok |
| neg_x | 2 | 1437.638 | 1060.198 | 1059.741 | x | +1 | 1.356 | sign_inverted |
| pos_y | 2 | 2319.030 | 1453.456 | 1451.822 | x | +1 | 1.596 | axis_permuted |
| neg_y | 2 | 3154.864 | 1289.644 | 1290.230 | x | +1 | 2.445 | axis_permuted |
| pos_z | 2 | 3152.384 | 1618.401 | 1618.037 | x | +1 | 1.948 | axis_permuted |
| neg_z | 2 | 3152.952 | 1210.812 | 1210.941 | x | +1 | 2.604 | axis_permuted |

## Matriz de inferencia de mapeo

| pose_fisica | canal_dominante_observado | signo_observado | canal_esperado | signo_esperado | estado |
|---|---|---:|---|---:|---|
| pos_x | x | +1 | x | +1 | ok |
| neg_x | x | +1 | x | -1 | sign_inverted |
| pos_y | x | +1 | y | +1 | axis_permuted |
| neg_y | x | +1 | y | -1 | axis_permuted |
| pos_z | x | +1 | z | +1 | axis_permuted |
| neg_z | x | +1 | z | -1 | axis_permuted |

## Diagnostico por pares de ejes (delta pos-neg)

| Eje evaluado | delta_mv_x | delta_mv_y | delta_mv_z | canal_dominante | signo_delta | ratio_dom | estado |
|---|---:|---:|---:|---|---:|---:|---|
| x_pair | +599.453 | -569.890 | -571.350 | x | +1 | 1.049 | ambiguous |
| y_pair | -835.834 | +163.811 | +161.591 | x | -1 | 5.102 | axis_permuted |
| z_pair | -0.568 | +407.589 | +407.096 | y | +1 | 1.001 | ambiguous |

## Comparacion explicita contra hipotesis de Fase 10 y 10.2

Hipotesis usada antes:
- Scripts de calibracion/validacion asumian mapeo fijo por nombre de pose (`pos_* -> +1`, `neg_* -> -1` en su eje).
- Esa hipotesis alimentaba directamente `expected_from_pose` y el modelo simple por eje.

Evidencia nueva de Fase 10.3:
- En las 6 poses, el canal dominante observado fue `x` y positivo.
- `neg_x` no invierte signo (permanece positivo), indicando conflicto de signo para ese eje.
- `pos_y`, `neg_y`, `pos_z`, `neg_z` no dominan en sus canales esperados (`y`/`z`), sino en `x`.
- En pares, `y_pair` apunta a permutacion clara hacia `x`, mientras `x_pair` y `z_pair` quedan ambiguos por dominancia insuficiente (ratios ~1.0).

Interpretacion causal sustentada:
1. Existe evidencia fuerte de problema de mapeo/convencion (no solo ruido).
2. Hay componente de inversion de signo al menos en el comportamiento esperado de `neg_x`.
3. Hay ambiguedad mecanica residual (fixture/angulo) en `x_pair` y `z_pair`.
4. El problema de `neg_y` y `pos_z` de Fase 10.2 es consistente con combinacion de:
   - permutacion de ejes o etiquetado de pose no alineado con canales
   - mas ambiguedad de montaje.

## Conclusiones

- High-level del script: `inconclusive`.
- Decision final operativa de esta fase: `mapping_inconclusive`.

## Recomendacion (siguiente fase, una sola)

- Repetir captura diagnostica corta con fixture fisico mas restrictivo (topes a 90 grados y referencia visual fija del eje del modulo) antes de aplicar correccion de signos/remapeo en scripts de calibracion.
