# Fase 10.4 - Confirmacion Reforzada de Convencion/Ejes para sensor_C

Fecha: 2026-03-22

## Convencion fisica declarada por operador

- `axis+` = eje positivo del modulo en sentido contrario a gravedad.
- `axis-` = eje positivo del modulo en el mismo sentido de gravedad.
- Poses evaluadas: `pos_x`, `neg_x`, `pos_y`, `neg_y`, `pos_z`, `neg_z`.

## Protocolo ejecutado (reforzado)

- Sensor: `sensor_C` (misma ESP32 de referencia, mismo firmware baseline, `COM5`).
- Corridas por pose: 3.
- Duracion por corrida: 8 s.
- Estabilizacion previa: 20 s reales antes de cada corrida.
- Integridad digital: `seq_jumps = 0` en las 18 corridas usadas.
- Dataset reproducible:
  - `reports/analysis_outputs/sensor_C_axis_convention_dataset_phase104.csv`

## Corridas nuevas usadas

### pos_x
1. `data/raw/sensor_C/sensor_C_pos_x_20260322_111504.csv`
2. `data/raw/sensor_C/sensor_C_pos_x_20260322_111643.csv`
3. `data/raw/sensor_C/sensor_C_pos_x_20260322_111810.csv`

### neg_x
1. `data/raw/sensor_C/sensor_C_neg_x_20260322_112213.csv`
2. `data/raw/sensor_C/sensor_C_neg_x_20260322_112342.csv`
3. `data/raw/sensor_C/sensor_C_neg_x_20260322_112521.csv`

### pos_y
1. `data/raw/sensor_C/sensor_C_pos_y_20260322_112844.csv`
2. `data/raw/sensor_C/sensor_C_pos_y_20260322_113009.csv`
3. `data/raw/sensor_C/sensor_C_pos_y_20260322_113138.csv`

### neg_y
1. `data/raw/sensor_C/sensor_C_neg_y_20260322_113521.csv`
2. `data/raw/sensor_C/sensor_C_neg_y_20260322_113710.csv`
3. `data/raw/sensor_C/sensor_C_neg_y_20260322_113839.csv`

### pos_z
1. `data/raw/sensor_C/sensor_C_pos_z_20260322_114145.csv`
2. `data/raw/sensor_C/sensor_C_pos_z_20260322_114310.csv`
3. `data/raw/sensor_C/sensor_C_pos_z_20260322_114438.csv`

### neg_z
1. `data/raw/sensor_C/sensor_C_neg_z_20260322_114932.csv`
2. `data/raw/sensor_C/sensor_C_neg_z_20260322_115059.csv`
3. `data/raw/sensor_C/sensor_C_neg_z_20260322_115227.csv`

## Corridas excluidas

- Ninguna corrida excluida en Fase 10.4.

## Artefactos de analisis

- `reports/analysis_outputs/sensor_C_axis_convention_phase104_20260322_115411_runs.csv`
- `reports/analysis_outputs/sensor_C_axis_convention_phase104_20260322_115411_poses.csv`
- `reports/analysis_outputs/sensor_C_axis_convention_phase104_20260322_115411_pairs.csv`
- `reports/analysis_outputs/sensor_C_axis_convention_phase104_20260322_115411_mapping.csv`
- `reports/analysis_outputs/sensor_C_axis_convention_phase104_20260322_115411.txt`

## Resumen por pose (mV)

| Pose | runs | mv_x_mean | mv_y_mean | mv_z_mean | canal_dom | signo | ratio_dom | estado |
|---|---:|---:|---:|---:|---|---:|---:|---|
| pos_x | 3 | 2857.031 | 1298.215 | 1298.326 | x | +1 | 2.201 | ok |
| neg_x | 3 | 2921.828 | 1355.549 | 1355.221 | x | +1 | 2.155 | sign_inverted |
| pos_y | 3 | 2027.623 | 1548.178 | 1548.344 | x | +1 | 1.310 | axis_permuted |
| neg_y | 3 | 1920.362 | 1237.053 | 1237.190 | x | +1 | 1.552 | axis_permuted |
| pos_z | 3 | 3113.491 | 1571.352 | 1571.815 | x | +1 | 1.981 | axis_permuted |
| neg_z | 3 | 2886.958 | 1253.182 | 1252.452 | x | +1 | 2.304 | axis_permuted |

Observacion:
- En todas las poses domina el canal `x` con signo positivo.

## Resumen por par (pos-neg)

| Par | delta_mv_x | delta_mv_y | delta_mv_z | canal_dom | signo_delta | ratio_dom | estado |
|---|---:|---:|---:|---|---:|---:|---|
| x_pair | -64.797 | -57.334 | -56.895 | x | -1 | 1.130 | ambiguous |
| y_pair | +107.261 | +311.125 | +311.153 | z | +1 | 1.000 | ambiguous |
| z_pair | +226.533 | +318.170 | +319.363 | z | +1 | 1.004 | ambiguous |

Interpretacion por pares:
- `x_pair` no cumple dominancia minima del protocolo (ratio < 1.2) y ademas signo opuesto.
- `y_pair` y `z_pair` quedan virtualmente empatados en magnitud dominante (ratio ~1.0), por eso se marcan ambiguos.

## Inferencia global de mapeo (script phase104)

| Eje real | Canal inferido | Signo inferido | ratio | estado |
|---|---|---|---:|---|
| X | x | sign_inverted | 1.130 | ambiguous |
| Y | z | sign_normal | 1.000 | ambiguous |
| Z | z | sign_normal | 1.004 | ambiguous |

No hay base suficiente para cerrar mapeo univoco de los 3 ejes.

## Comparacion contra Fase 10.3

- Fase 10.3: `mapping_inconclusive`.
- Fase 10.4: `mapping_inconclusive` nuevamente.
- Cambio principal:
  - `y_pair` paso de `axis_permuted` a `ambiguous` por empate casi exacto entre canales dominantes.
  - `x_pair` y `z_pair` siguen ambiguos (ratios cercanos a 1).
- Conclusion comparativa:
  - El fixture reforzado mejoro control operativo, pero no entrego separacion metrologica suficiente para cerrar el mapeo de forma robusta.

## Decision final de la fase

- `mapping_inconclusive`

## Impacto sobre scripts (sin modificar aun)

### Si el resultado fuera `mapping_confirmed`
- Mantener asignacion de canales actual.
- Ajustar solo criterios/umbrales de verificacion si fuera necesario.
- `expected_from_pose` puede mantenerse con signos nominales.

### Si el resultado fuera `sign_correction_needed`
- Conservar asignacion de ejes/canales.
- Corregir convencion de signos esperados en validadores (`expected_from_pose` o equivalente).
- No remapear columnas de canal.

### Si el resultado fuera `axis_remap_needed`
- Introducir capa explicita de remapeo de canales (`measured_channel -> physical_axis`) antes de evaluar poses.
- Luego aplicar signos sobre ejes fisicos ya remapeados.
- No recalibrar hasta fijar ese remapeo.

### Estado real tras Fase 10.4
- No es seguro tocar scripts de calibracion todavia.
- Primero se requiere una fase de diagnostico adicional orientada a romper la ambiguedad de pares.

## Recomendacion de siguiente fase

- Ejecutar una fase de aislamiento metrologico por eje con fixture de referencia mas fuerte (tope mecanico dedicado por eje y control de orientacion con plantilla), para forzar separacion clara en `x_pair`, `y_pair`, `z_pair` antes de cualquier recalibracion.
