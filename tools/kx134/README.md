# KX134 tools

Herramientas operativas para pruebas y calibracion de los nodos KX134.

## Calibracion Sensor 1

Ejemplo:

```powershell
powershell -ExecutionPolicy Bypass -File tools\kx134\calibrate_kx134_sensor.ps1 -Port COM5 -SensorId 1 -ExpectedMac "D4:E9:F4:E9:8E:1C" -CaptureSeconds 20 -SettleSeconds 3
```

## Calibracion Sensor 2

Ejemplo:

```powershell
powershell -ExecutionPolicy Bypass -File tools\kx134\calibrate_kx134_sensor.ps1 -Port COM5 -SensorId 2 -ExpectedMac "D4:E9:F4:C3:37:14" -CaptureSeconds 20 -SettleSeconds 3
```

El script guia la calibracion estatica de seis posiciones para `KX134_SENSOR_1` o
`KX134_SENSOR_2`, segun `-SensorId`. No sube firmware, no aplica calibracion al
firmware y no modifica datos historicos.

## Parametros principales

- `-Port`: puerto serial. Default: `COM5`.
- `-Baud`: baudrate serial. Default: `921600`.
- `-SensorId`: sensor esperado. Default: `1`.
- `-ExpectedMac`: MAC ESP32 esperada. Default: `D4:E9:F4:E9:8E:1C`.
- `-SampleRateHz`: frecuencia esperada. Default: `100`.
- `-OdrHz`: ODR esperado. Default: `100`.
- `-RangeG`: rango esperado. Default: `8`.
- `-CaptureSeconds`: duracion por posicion. Default: `20`.
- `-SettleSeconds`: tiempo de estabilizacion descartado. Default: `3`.
- `-MinSamples`: minimo de muestras por posicion. Default: `1500`.
- `-OutputRoot`: raiz de reportes. Default segun sensor: `reports/kx134_calibration/sensor_1` o `reports/kx134_calibration/sensor_2`.
- `-PhysicalLabel`: etiqueta esperada. Default segun sensor.
- `-NodeId`: nodo esperado. Default segun sensor.
- `-ForceAcceptWarnings`: acepta warnings automaticamente. Default: `false`.
- `-CaptureBackend`: `Auto`, `SerialPort` o `PlatformIO`. Default: `Auto`.

## Salidas

Si las seis posiciones se completan, el script genera:

- `config/calibrations/kx134_sensor_<N>.json`
- `config/kx134_node_map.json`
- `reports/kx134_calibration/sensor_<N>/<session_id>/calibration_result.json`
- `reports/kx134_calibration/sensor_<N>/<session_id>/calibration_summary.md`
- `reports/kx134_calibration/sensor_<N>/<session_id>/captures/*.csv`

La calibracion es valida solo para el sensor fisico, MAC, `range_g`, `sample_rate_hz`
y `odr_hz` usados durante la captura. No compartir coeficientes entre sensores.
