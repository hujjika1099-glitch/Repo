# Reevaluacion de Repetibilidad Reforzada: sensor_A / z_plus_static

Fecha: 2026-03-20

## Contexto y objetivo
Esta fase repite la validacion de repetibilidad en la misma pose `z_plus_static` con control fisico reforzado (misma ESP32, mismo sensor_A, mismo COM5, sin mover cableado durante corrida) antes de permitir multipose.

## Corridas nuevas agregadas en esta fase
1. `data/raw/sensor_A/sensor_A_z_plus_static_20260320_165156.csv`
2. `data/raw/sensor_A/sensor_A_z_plus_static_20260320_165401.csv`

## Total de corridas consideradas
`6` corridas de `sensor_A / z_plus_static`:
1. `sensor_A_z_plus_static_20260320_132709.csv`
2. `sensor_A_z_plus_static_20260320_135921.csv`
3. `sensor_A_z_plus_static_20260320_140052.csv`
4. `sensor_A_z_plus_static_20260320_141206.csv`
5. `sensor_A_z_plus_static_20260320_165156.csv`
6. `sensor_A_z_plus_static_20260320_165401.csv`

## Resumen operativo de las 2 corridas nuevas
| run_file | samples_captured | real_duration_wall_s | estimated_frequency_hz | seq_jumps |
|---|---:|---:|---:|---:|
| sensor_A_z_plus_static_20260320_165156.csv | 1203 | 12.005 | 100.007 | 0 |
| sensor_A_z_plus_static_20260320_165401.csv | 1192 | 12.000 | 100.007 | 0 |

## Salida del reanalisis (todas las corridas)
- Script: `matlab/analysis/analyze_repeatability_same_pose.m`
- Artefactos:
  - `reports/analysis_outputs/sensor_A_z_plus_static_repeatability_20260320_165502.csv`
  - `reports/analysis_outputs/sensor_A_z_plus_static_repeatability_20260320_165502.txt`
- `runs_found`: `6`
- `raw_z_mean_range`: `895.999638`
- `mv_z_mean_range`: `740.370266`

## Metricas por corrida (extracto)
| run_file | freq_hz | seq_jumps | raw_z_mean | mv_z_mean |
|---|---:|---:|---:|---:|
| sensor_A_z_plus_static_20260320_132709.csv | 100.007263 | 0 | 1040.186822 | 1000.610509 |
| sensor_A_z_plus_static_20260320_135921.csv | 100.007257 | 0 | 1293.188333 | 1210.143333 |
| sensor_A_z_plus_static_20260320_140052.csv | 100.007275 | 0 | 655.467836 | 683.307435 |
| sensor_A_z_plus_static_20260320_141206.csv | 100.007283 | 0 | 628.119465 | 660.794486 |
| sensor_A_z_plus_static_20260320_165156.csv | 100.007238 | 0 | 397.188695 | 469.773067 |
| sensor_A_z_plus_static_20260320_165401.csv | 100.007314 | 0 | 397.592282 | 470.269295 |

## Comparacion explicita contra la evaluacion anterior
- Evaluacion anterior (`reports/sensor_A_repeatability_assessment.md`):
  - `runs_found`: `3`
  - `raw_z_mean_range`: `637.720497`
  - `mv_z_mean_range`: `526.835898`
- Reevaluacion reforzada (actual):
  - `runs_found`: `6`
  - `raw_z_mean_range`: `895.999638`
  - `mv_z_mean_range`: `740.370266`

Resultado comparativo: la dispersion entre corridas en eje Z no disminuyo; aumento frente al corte anterior.

## Observaciones
- La cadena digital sigue estable (frecuencia ~100 Hz y `seq_jumps = 0` en todas las corridas).
- El problema dominante permanece en la repetibilidad fisica/mecanica de la condicion de prueba.
- Se requiere mayor control de montaje y de referencia angular antes de habilitar multipose.

## Decision final
- `repeatability_issue_persists`

