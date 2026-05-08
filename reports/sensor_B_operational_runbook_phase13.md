# Runbook Operativo - sensor_B (Fase 13)

## 1) Cableado estandar
Usar exactamente:
- VCC -> 3V3
- GND -> GND
- X-OUT -> GPIO32 (ADC1_CH4)
- Y-OUT -> GPIO33 (ADC1_CH5)
- Z-OUT -> GPIO34 (ADC1_CH6)
- ST pad lateral -> GPIO23 (solo cableado, no requerido para flujo normal)

Referencia: `hardware/adxl335_standard_wiring.md`.

## 2) Firmware/base a usar
- Firmware baseline actual en:
  - `firmware/single_node_calibration/src/main.cpp`
- Sin requisito de ST para operacion normal.

## 3) Captura normal (sin ST)
Opcion recomendada (PowerShell):
```powershell
.\scripts\run_sensorB_operational_capture.ps1 -Port COM5 -DurationS 12 -PoseLabel operational_run
```

Opcion directa (MATLAB batch):
```powershell
matlab -batch "sensor_id='sensor_B'; port='COM5'; duration_s=12; pose_label='operational_run'; run('matlab/calibration/capture_single_sensor_baseline.m')"
```

## 4) Artefactos esperados
- `data/raw/sensor_B/sensor_B_operational_run_<timestamp>.csv`
- `data/raw/sensor_B/sensor_B_operational_run_<timestamp>_session.txt`

## 5) Chequeo corto de sanidad antes de uso
El helper `scripts/run_sensorB_operational_capture.ps1` ya imprime:
- `FREQ_HZ`
- `SEQ_JUMPS`
- `SAT_PCT_ANY_AXIS`
- `SANITY_STATUS` (`pass` o `review`)

Criterio rapido:
- `SEQ_JUMPS = 0`
- `95 <= FREQ_HZ <= 105`
- `SAT_PCT_ANY_AXIS <= 1.0`

Si falla:
1. Revisar cableado/alimentacion.
2. Repetir una sola captura corta.
3. Si persiste, conmutar a `sensor_A` (backup) y continuar desarrollo.
