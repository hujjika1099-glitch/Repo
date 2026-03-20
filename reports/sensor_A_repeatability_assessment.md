# Evaluacion de Repetibilidad: sensor_A / z_plus_static

Fecha: 2026-03-20

## Corridas utilizadas
1. `data/raw/sensor_A/sensor_A_z_plus_static_20260320_132709.csv`
2. `data/raw/sensor_A/sensor_A_z_plus_static_20260320_135921.csv`
3. `data/raw/sensor_A/sensor_A_z_plus_static_20260320_140052.csv`

Cantidad total de corridas: `3`

## Artefactos de analisis
- Overview CSV:
  - `reports/analysis_outputs/sensor_A_z_plus_static_repeatability_20260320_140207.csv`
- Overview TXT:
  - `reports/analysis_outputs/sensor_A_z_plus_static_repeatability_20260320_140207.txt`

## Metricas clave por corrida
| run_file | samples | duration_s | freq_hz | seq_jumps | raw_z_mean | mv_z_mean |
|---|---:|---:|---:|---:|---:|---:|
| sensor_A_z_plus_static_20260320_132709.csv | 1199 | 11.979130 | 100.007263 | 0 | 1040.186822 | 1000.610509 |
| sensor_A_z_plus_static_20260320_135921.csv | 1200 | 11.989130 | 100.007257 | 0 | 1293.188333 | 1210.143333 |
| sensor_A_z_plus_static_20260320_140052.csv | 1197 | 11.959130 | 100.007275 | 0 | 655.467836 | 683.307435 |

## Comparacion entre corridas
- `runs_found`: `3`
- `raw_z_mean_range`: `637.720497`
- `mv_z_mean_range`: `526.835898`
- Frecuencia por corrida: estable (~100.007 Hz en todas).
- `seq_jumps`: `0` en todas (continuidad de stream correcta).

## Observaciones sobre estabilidad
- El canal temporal/serial es estable (sin saltos de secuencia y con frecuencia consistente).
- Las medias en eje Z presentan variacion muy alta entre corridas para la misma pose objetivo, lo que no es esperable como repetibilidad basica.
- Posibles causas operativas: variacion real de pose, perturbacion mecanica durante adquisicion, contacto/cableado variable o asentamiento del sensor.

## Decision final
- `repeatability_issue`

## Recomendacion antes de multipose
- No iniciar multipose aun.
- Repetir corridas en `z_plus_static` bajo control fisico mas estricto (mismo soporte, sin manipular cableado durante captura, ventana de asentamiento previa) hasta reducir dispersion en medias por eje.
