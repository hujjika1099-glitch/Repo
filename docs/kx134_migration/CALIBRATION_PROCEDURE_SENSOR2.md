# Procedimiento de Calibracion - KX134 Sensor 2

## Objetivo

Calibrar el Sensor 2 KX134 mediante seis posiciones estaticas y generar
`config/calibrations/kx134_sensor_2.json`.

## Sensor

- sensor_id: `2`
- physical_label: `KX134_SENSOR_2`
- node_id: `sensor_node_2`
- MAC ESP32: `D4:E9:F4:C3:37:14`
- Puerto probable: `COM5`
- Baudrate: `921600`
- sample_rate_hz: `100`
- odr_hz: `100`
- range_g: `8`

## Comando

```powershell
powershell -ExecutionPolicy Bypass -File tools\kx134\calibrate_kx134_sensor.ps1 -Port COM5 -SensorId 2 -ExpectedMac "D4:E9:F4:C3:37:14" -CaptureSeconds 20 -SettleSeconds 3 -MinSamples 1500
```

## Posiciones

1. `X_POS`: +X vertical hacia el techo.
2. `X_NEG`: -X vertical hacia el techo.
3. `Y_POS`: +Y vertical hacia el techo.
4. `Y_NEG`: -Y vertical hacia el techo.
5. `Z_POS`: +Z vertical hacia el techo.
6. `Z_NEG`: -Z vertical hacia el techo.

Mantener el modulo quieto durante estabilizacion y captura. Si el signo del eje
dominante sale invertido, repetir la posicion y revisar la orientacion fisica.

## Criterios

- `samples_count >= 1500`.
- Identidad exacta de Sensor 2 y MAC `D4:E9:F4:C3:37:14`.
- Frecuencia efectiva 98-102 Hz para pass.
- `seq_gaps=0` preferido.
- `timestamp_errors=0`.
- `g_norm_mean` entre 0.85 y 1.15.
- `g_norm_std <= 0.05` para pass.
- Eje dominante y signo correctos.
- Sin campos ADXL335/mV ni errores repetitivos.

## Archivos Generados

- `reports/kx134_calibration/sensor_2/<session_id>/captures/*.csv`
- `reports/kx134_calibration/sensor_2/<session_id>/calibration_summary.md`
- `reports/kx134_calibration/sensor_2/<session_id>/calibration_result.json`
- `config/calibrations/kx134_sensor_2.json`
- `config/kx134_node_map.json`

## Validez

La calibracion es valida solo para el Sensor 2 fisico actual, MAC
`D4:E9:F4:C3:37:14`, `range_g=8`, `sample_rate_hz=100` y `odr_hz=100`.

No mezclar ni copiar coeficientes desde Sensor 1.
