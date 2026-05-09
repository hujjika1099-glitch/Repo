# KX134 tools

Herramientas operativas para pruebas y calibracion de los nodos KX134.

## Calibracion Sensor 1

Script:

```powershell
powershell -ExecutionPolicy Bypass -File tools\kx134\calibrate_kx134_sensor.ps1 -Port COM5 -SensorId 1 -ExpectedMac "D4:E9:F4:E9:8E:1C" -CaptureSeconds 20 -SettleSeconds 3
```

El script guia la calibracion estatica de seis posiciones para `KX134_SENSOR_1`.
No sube firmware, no aplica calibracion al firmware y no modifica datos historicos.

## Parametros principales

- `-Port`: puerto serial. Default: `COM5`.
- `-Baud`: baudrate serial. Default: `921600`.
- `-SensorId`: sensor esperado. Default: `1`.
- `-ExpectedMac`: MAC ESP32 esperada. Default: `D4:E9:F4:E9:8E:1C`.
- `-SampleRateHz`: frecuencia esperada. Default: `100`.
- `-RangeG`: rango esperado. Default: `8`.
- `-CaptureSeconds`: duracion por posicion. Default: `20`.
- `-SettleSeconds`: tiempo de estabilizacion descartado. Default: `3`.
- `-MinSamples`: minimo de muestras por posicion. Default: `1500`.
- `-OutputRoot`: raiz de reportes. Default: `reports/kx134_calibration/sensor_1`.
- `-CaptureBackend`: `Auto`, `SerialPort` o `PlatformIO`. Default: `Auto`.

## Salidas

Si las seis posiciones se completan, el script genera:

- `config/calibrations/kx134_sensor_1.json`
- `config/kx134_node_map.json`
- `reports/kx134_calibration/sensor_1/<session_id>/calibration_result.json`
- `reports/kx134_calibration/sensor_1/<session_id>/calibration_summary.md`
- `reports/kx134_calibration/sensor_1/<session_id>/captures/*.csv`

La calibracion es valida solo para `range_g=8`, `sample_rate_hz=100` y el firmware
KX134 single-node usado durante la captura.
