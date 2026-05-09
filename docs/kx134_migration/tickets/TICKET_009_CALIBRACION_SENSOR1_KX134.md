# TICKET 009 - Calibracion Sensor 1 KX134

## Objetivo

Ejecutar calibracion estatica de seis posiciones para `KX134_SENSOR_1` usando
el stream Serial KX134 v3 ya validado.

## Rama

- `feature/kx134-dual-capture`

## Precondiciones

- Firmware KX134 single-node cargado y validado.
- Puerto probable: `COM5`.
- Baudrate: `921600`.
- MAC esperada: `D4:E9:F4:E9:8E:1C`.
- KX134 detectado por I2C en `0x1F`.
- `sensor_id=1`, `sample_rate_hz=100`, `odr_hz=100`, `range_g=8`.
- Cableado: 3V3 a 3V3, GND a GND, SDA a GPIO21, SCL a GPIO22.

## Procedimiento interactivo

Ejecutar:

```powershell
powershell -ExecutionPolicy Bypass -File tools\kx134\calibrate_kx134_sensor.ps1 -Port COM5 -SensorId 1 -ExpectedMac "D4:E9:F4:E9:8E:1C" -CaptureSeconds 20 -SettleSeconds 3
```

El operador debe colocar el sensor en estas posiciones, en orden:

1. `X_POS`
2. `X_NEG`
3. `Y_POS`
4. `Y_NEG`
5. `Z_POS`
6. `Z_NEG`

Para cada posicion el script descarta una ventana de estabilizacion, captura
datos, guarda CSV, analiza estabilidad y decide si avanza o si se repite.

## Criterios de aceptacion

- Minimo 1500 muestras por posicion.
- Identidad, MAC y configuracion coinciden con Sensor 1.
- Header compatible con contrato `kx134.v3`.
- Sin campos ADXL335/mV prohibidos.
- `seq` incrementa sin saltos significativos.
- `sensor_t_us` incrementa.
- Frecuencia efectiva cercana a 100 Hz.
- El eje dominante y su signo coinciden con la posicion fisica.
- `g_norm_mean` entre 0.85 y 1.15.
- Sin errores criticos de sensor.

## Archivos generados

- `tools/kx134/calibrate_kx134_sensor.ps1`
- `tools/kx134/README.md`
- `config/calibrations/kx134_sensor_1.json`
- `config/kx134_node_map.json`
- `docs/kx134_migration/CALIBRATION_PROCEDURE_SENSOR1.md`
- `reports/kx134_calibration/sensor_1/<session_id>/calibration_summary.md`
- `reports/kx134_calibration/sensor_1/<session_id>/calibration_result.json`
- `reports/kx134_calibration/sensor_1/<session_id>/captures/*.csv`

## Restricciones

- No modificar firmware.
- No modificar GUI.
- No modificar empaquetado.
- No modificar `data/`.
- No aplicar calibracion dentro del firmware.
- No implementar ESP-NOW.
- No commitear `.pio` ni binarios.

## Resultado esperado

Si las seis posiciones pasan, el ticket queda cerrado con:

```text
SENSOR_1_CALIBRATION_VALID = YES
```

El siguiente ticket recomendado es preparar firmware y prueba fisica para
`KX134_SENSOR_2`.
