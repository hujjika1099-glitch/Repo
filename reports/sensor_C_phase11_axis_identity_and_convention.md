# Fase 11 - Axis Identity and Operational Convention Layer (sensor_C)

Fecha: 2026-03-22

## Objetivo
Destrabar el proyecto cerrando la identidad de ejes/canales y la convencion operativa, sin reabrir campanas largas de captura y preservando como baseline la calibracion simple de Fase 10:

- `data/processed/sensor_C_static_calibration_20260321_140044.mat`

## Diagnostico consolidado
1. La cadena digital esta validada (firmware, captura, parser, timestamps, secuencias).
2. El cuello de botella actual es interpretacion fisica/conversion (ejes, signos, mapeo), no adquisicion.
3. El baseline simple de Fase 10 sigue siendo el punto operativo mas defendible.
4. Modelos affine/coupled/regularized no cerraron robustamente el problema de identidad.
5. La siguiente ganancia de retorno alto es desacoplar adquisicion de interpretacion con una capa explicita de convencion.

## Decision de ingenieria
### Dejar de hacer
- Repetir campanas largas multipose para "forzar" cierre por volumen.
- Promover modelos affine/coupled/regularized como baseline por defecto.

### Empezar a hacer
- Introducir una capa de software explicita para:
  - channel -> chip axis identity
  - chip axis -> operacional mapping
  - sign convention operacional
- Usar ST del ADXL335 como verificacion corta dominante para identidad de canales.
- Mantener la calibracion Fase 10 intacta y componer sobre ella.

## Arquitectura operativa (Fase 11)
```text
raw CSV
  -> mV
  -> calibracion simple Fase 10 (por canal)
  -> apply_sensor_axis_convention (channel->chip->operational + signo)
  -> salida operativa (g_oper_x, g_oper_y, g_oper_z)
```

## Scripts y archivos nuevos
- `config/sensor_C_axis_convention_phase11.json`
- `matlab/analysis/apply_sensor_axis_convention.m`
- `matlab/analysis/run_sensorC_selftest_identity_check.m`
- `matlab/analysis/run_sensorC_phase11_operational_interpretation.m`
- `matlab/analysis/run_sensorC_phase11_axis_identity_and_convention.m`

## Logica implementada
### 1) Self-test identity check
Entrada:
- 1 corrida `st_off`
- 1 corrida `st_on`

Heuristica ST:
- exactamente un canal con delta negativo fuerte -> eje chip X
- dos canales con delta positivo fuerte -> ejes chip Y y Z
- el positivo mayor se propone como Z (si ratio Z/Y >= umbral)

Salida:
- decision: `identity_closed` o `identity_not_closed`
- confianza cuantificada
- JSON de identidad:
  - `config/sensor_C_axis_identity_from_st_latest.json`

### 2) Convention layer
`apply_sensor_axis_convention.m` aplica una transformacion explicita:

1. permutacion channel->chip
2. permutacion/signo chip->operational

Con esto se desacopla totalmente la adquisicion de la interpretacion fisica.

### 3) Operational interpretation
`run_sensorC_phase11_operational_interpretation.m` ejecuta:

- baseline Fase 10 + convention layer
- resumen por corrida, pose y pares
- decision:
  - `operationally_usable`
  - `operationally_usable_provisional_identity`
  - `identity_or_convention_review_needed`
  - `blocked_data_integrity`

## Protocolo minimo recomendado
### Protocolo A (dominante, 2 corridas)
1. Capturar `st_off` (6-8 s, sensor quieto).
2. Capturar `st_on` (6-8 s, misma orientacion, ST activado).
3. Ejecutar `run_sensorC_selftest_identity_check.m`.

Hipotesis que resuelve:
- identidad canal<->eje chip por firma direccional ST.

### Protocolo B (solo si A no cierra Y/Z, +1 corrida)
- Una sola corrida `pos_z` corta (6-8 s) para romper empate Y/Z.

## Criterios de aceptacion realistas (entorno domestico)
1. `identity_closed` por ST o `operationally_usable_provisional_identity` con evidencia fuerte.
2. Config de convencion explicita y versionada en `config/`.
3. Baseline Fase 10 preservado y trazable (sin reemplazo de modelo base).
4. `pair_axis_match_count >= 2` y `pair_sign_opposition_count >= 2` en interpretacion operativa.
5. Pipeline ejecutable de extremo a extremo con salida operacional en g.

## Ejecucion sugerida
1. `run('matlab/analysis/run_sensorC_selftest_identity_check.m')`
2. `run('matlab/analysis/run_sensorC_phase11_axis_identity_and_convention.m')`

## Nota de integridad
- Esta fase no modifica artefactos historicos.
- Esta fase no reemplaza calibracion baseline de Fase 10.
- Si ST no cierra identidad, se declara `identity_not_closed` explicitamente.
