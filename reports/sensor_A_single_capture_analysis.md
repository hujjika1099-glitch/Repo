# Analisis Basico de Captura Individual: sensor_A / z_plus_static

Fecha: 2026-03-20

## Archivos analizados
- CSV:
  - `data/raw/sensor_A/sensor_A_z_plus_static_20260320_132709.csv`
- Sesion asociada:
  - `data/raw/sensor_A/sensor_A_z_plus_static_20260320_132709_session.txt`
- Resumen reproducible generado por script:
  - `reports/analysis_outputs/sensor_A_z_plus_static_20260320_132709_analysis_summary.txt`
- Figuras:
  - `reports/analysis_outputs/sensor_A_z_plus_static_20260320_132709_analysis_20260320_134502_raw.png`
  - `reports/analysis_outputs/sensor_A_z_plus_static_20260320_132709_analysis_20260320_134502_mv.png`

## Metricas principales
- muestras: `1199`
- duracion (t_us): `11.979130 s`
- frecuencia estimada: `100.007263 Hz`
- saltos de secuencia: `0`

## Estadisticas por canal

### RAW (ADC)
- `raw_x`: mean `1809.707256`, std `16.205799`, min `1727`, max `1953`
- `raw_y`: mean `1729.783153`, std `18.341265`, min `1639`, max `1872`
- `raw_z`: mean `1040.186822`, std `31.072243`, min `945`, max `1187`

### mV
- `mv_x`: mean `1637.225188`, std `14.951206`, min `1565`, max `1754`
- `mv_y`: mean `1570.344454`, std `14.409662`, min `1494`, max `1689`
- `mv_z`: mean `1000.610509`, std `26.604679`, min `920`, max `1133`

## Observaciones de estabilidad basica
- El stream es consistente en estructura y continuidad (`seq_jumps = 0`).
- La frecuencia observada coincide con el objetivo del firmware (~100 Hz).
- No se observan fallas estructurales en esta corrida individual.

## Decision operativa
- `stable_for_repeatability_check`
