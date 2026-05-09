# TICKET 011 - Calibracion Sensor 2 KX134

## Objetivo

Generalizar la herramienta de calibracion KX134 y calibrar el Sensor 2 mediante seis
posiciones estaticas.

## Rama

`feature/kx134-dual-capture`

## Precondiciones

- Sensor 2 validado por Serial con `READY_FOR_SENSOR_2_CALIBRATION=YES`.
- MAC Sensor 2: `D4:E9:F4:C3:37:14`.
- Firmware Sensor 2 cargado con `sensor_id=2`.
- Cableado: 3V3, GND, SDA=GPIO21, SCL=GPIO22.
- Puerto probable: `COM5`.

## Procedimiento Interactivo

1. Ejecutar `tools/kx134/calibrate_kx134_sensor.ps1` con `-SensorId 2`.
2. Confirmar stream KX134 v3 activo.
3. Capturar en orden: `X_POS`, `X_NEG`, `Y_POS`, `Y_NEG`, `Z_POS`, `Z_NEG`.
4. Analizar cada posicion.
5. Repetir posiciones fallidas o cancelar.
6. Generar calibracion valida solo si las seis posiciones pasan o se aceptan
   advertencias de forma explicita.

## Criterios de Aceptacion

- Minimo 1500 muestras por posicion.
- Identidad Sensor 2 exacta.
- 100 Hz, ODR 100 Hz, rango 8 g.
- Frecuencia efectiva 98-102 Hz para pass.
- Cero errores de timestamp.
- Eje dominante y signo correctos.
- Norma en reposo plausible y estable.
- Sin campos ADXL335/mV.

## Archivos Esperados

- `config/calibrations/kx134_sensor_2.json`
- `reports/kx134_calibration/sensor_2/<session_id>/calibration_summary.md`
- `reports/kx134_calibration/sensor_2/<session_id>/calibration_result.json`
- `reports/kx134_calibration/sensor_2/<session_id>/captures/*.csv`
- `config/kx134_node_map.json`

## Restricciones

- No modificar firmware.
- No modificar GUI.
- No modificar empaquetado.
- No modificar datos historicos.
- No modificar calibracion ni reportes de Sensor 1.
- No aplicar calibracion en firmware.

## Resultado Esperado

`SENSOR_2_CALIBRATION_VALID = YES` y Sensor 2 marcado como `calibrated` en el mapa
de nodos.
