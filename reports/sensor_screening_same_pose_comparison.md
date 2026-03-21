# Screening Comparativo ADXL335 (Misma Pose)

Fecha: 2026-03-21

## Protocolo aplicado
- Misma ESP32 de referencia.
- Mismo puerto: `COM5`.
- Misma pose: `z_plus_static`.
- Firmware baseline sin cambios durante la fase.
- `5` corridas por sensor (`sensor_A`, `sensor_B`, `sensor_C`).
- Estabilizacion minima real de `20 s` antes de cada corrida.

## Corridas usadas (5 por sensor)

### sensor_A
1. `data/raw/sensor_A/sensor_A_z_plus_static_20260320_171159.csv`
2. `data/raw/sensor_A/sensor_A_z_plus_static_20260320_171348.csv`
3. `data/raw/sensor_A/sensor_A_z_plus_static_20260320_171521.csv`
4. `data/raw/sensor_A/sensor_A_z_plus_static_20260320_171654.csv`
5. `data/raw/sensor_A/sensor_A_z_plus_static_20260320_171823.csv`

### sensor_B
1. `data/raw/sensor_B/sensor_B_z_plus_static_20260320_180404.csv`
2. `data/raw/sensor_B/sensor_B_z_plus_static_20260320_180533.csv`
3. `data/raw/sensor_B/sensor_B_z_plus_static_20260320_180705.csv`
4. `data/raw/sensor_B/sensor_B_z_plus_static_20260320_180838.csv`
5. `data/raw/sensor_B/sensor_B_z_plus_static_20260320_181012.csv`

### sensor_C
1. `data/raw/sensor_C/sensor_C_z_plus_static_20260321_092728.csv`
2. `data/raw/sensor_C/sensor_C_z_plus_static_20260321_093024.csv`
3. `data/raw/sensor_C/sensor_C_z_plus_static_20260321_093223.csv`
4. `data/raw/sensor_C/sensor_C_z_plus_static_20260321_093423.csv`
5. `data/raw/sensor_C/sensor_C_z_plus_static_20260321_093618.csv`

## Artefactos de analisis
- Repetibilidad por sensor (ultimas 5 corridas):
  - `reports/analysis_outputs/sensor_A_z_plus_static_repeatability_20260321_094627.csv`
  - `reports/analysis_outputs/sensor_B_z_plus_static_repeatability_20260321_094813.csv`
  - `reports/analysis_outputs/sensor_C_z_plus_static_repeatability_20260321_094921.csv`
- Screening consolidado:
  - `reports/analysis_outputs/sensor_screening_z_plus_static_20260321_095249_runs.csv`
  - `reports/analysis_outputs/sensor_screening_z_plus_static_20260321_095249_summary.csv`
  - `reports/analysis_outputs/sensor_screening_z_plus_static_20260321_095249.txt`

## Resumen comparativo por sensor
| sensor_id | runs_found | freq_mean_hz | seq_jumps_total | raw_z_mean_range | mv_z_mean_range | raw_z_std_mean | mv_z_std_mean | etiqueta |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| sensor_A | 5 | 100.007294 | 0 | 193.004295 | 158.754512 | 22.017807 | 18.255856 | sensor_suspect |
| sensor_B | 5 | 100.007296 | 0 | 223.533501 | 185.666667 | 15.991129 | 13.189778 | sensor_suspect |
| sensor_C | 5 | 100.005830 | 0 | 0.887757 | 1.099573 | 15.367367 | 13.264946 | sensor_ok |

## Metricas por corrida (freq_hz, seq_jumps, raw_z_mean, mv_z_mean)

### sensor_A
| run_file | freq_hz | seq_jumps | raw_z_mean | mv_z_mean |
|---|---:|---:|---:|---:|
| sensor_A_z_plus_static_20260320_171159.csv | 100.007299 | 0 | 553.066220 | 598.321039 |
| sensor_A_z_plus_static_20260320_171348.csv | 100.007293 | 0 | 415.469012 | 484.791457 |
| sensor_A_z_plus_static_20260320_171521.csv | 100.007287 | 0 | 360.061925 | 439.566527 |
| sensor_A_z_plus_static_20260320_171654.csv | 100.007287 | 0 | 412.390795 | 482.954812 |
| sensor_A_z_plus_static_20260320_171823.csv | 100.007305 | 0 | 398.031879 | 470.047819 |

### sensor_B
| run_file | freq_hz | seq_jumps | raw_z_mean | mv_z_mean |
|---|---:|---:|---:|---:|
| sensor_B_z_plus_static_20260320_180404.csv | 100.007299 | 0 | 1909.616094 | 1719.162615 |
| sensor_B_z_plus_static_20260320_180533.csv | 100.007299 | 0 | 1911.331936 | 1721.488684 |
| sensor_B_z_plus_static_20260320_180705.csv | 100.007301 | 0 | 1917.389447 | 1725.918760 |
| sensor_B_z_plus_static_20260320_180838.csv | 100.007287 | 0 | 1898.435983 | 1711.231799 |
| sensor_B_z_plus_static_20260320_181012.csv | 100.007293 | 0 | 1693.855946 | 1540.252094 |

### sensor_C
| run_file | freq_hz | seq_jumps | raw_z_mean | mv_z_mean |
|---|---:|---:|---:|---:|
| sensor_C_z_plus_static_20260321_092728.csv | 100.000000 | 0 | 2253.423841 | 2002.757450 |
| sensor_C_z_plus_static_20260321_093024.csv | 100.007289 | 0 | 2253.352007 | 2003.721572 |
| sensor_C_z_plus_static_20260321_093223.csv | 100.007281 | 0 | 2254.009197 | 2003.857023 |
| sensor_C_z_plus_static_20260321_093423.csv | 100.007287 | 0 | 2253.460251 | 2003.684519 |
| sensor_C_z_plus_static_20260321_093618.csv | 100.007293 | 0 | 2253.121441 | 2003.776382 |

## Interpretacion tecnica
- El canal digital se mantuvo estable para los tres sensores (frecuencia ~100 Hz y `seq_jumps_total = 0`).
- `sensor_C` presenta dispersion muy baja en medias de eje Z (`raw_z_mean_range` y `mv_z_mean_range`), lo que indica mejor repetibilidad en esta condicion.
- `sensor_A` y `sensor_B` muestran dispersion alta y consistente entre corridas para la misma pose, por encima de `sensor_C`.
- Con dos sensores mostrando dispersion alta bajo el mismo protocolo, se mantiene alerta de condicion de montaje (`fixture_issue`) durante intercambio de sensores.

## Decision final operativa (etiquetas)
- `sensor_A = sensor_suspect`
- `sensor_B = sensor_suspect`
- `sensor_C = sensor_ok`
- `sensor_C = candidate_preferred_sensor`
- `system = fixture_issue`
- `system = ready_for_multipose_with_selected_sensor (sensor_C)`
