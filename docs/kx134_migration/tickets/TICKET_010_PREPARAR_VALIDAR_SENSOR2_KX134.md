# TICKET 010 - Preparar y validar KX134 Sensor 2

## Objetivo

Preparar el firmware single-node KX134 para compilar una variante de Sensor 2,
subirla a la segunda ESP32, capturar salida Serial y decidir si queda lista para
calibracion.

## Precondiciones

- Rama: `feature/kx134-dual-capture`.
- Sensor 1 calibrado con `kx134_sensor_1_20260508_234831`.
- La segunda ESP32 debe estar conectada por USB.
- El segundo SEN-17589/KX134 debe estar cableado a esa ESP32:
  - 3V3 -> 3V3.
  - GND -> GND.
  - SDA -> GPIO21.
  - SCL -> GPIO22.
- No alimentar con 5V.
- No modificar jumpers.

## Cambios en PlatformIO

Se definen entornos:

- `kx134_sensor_1`: `KX134_SENSOR_ID=1`.
- `kx134_sensor_2`: `KX134_SENSOR_ID=2`.
- `esp32dev`: alias compatible de Sensor 1.

El wrapper `tools/platformio/kx134_single_node.ps1` acepta `-Env`.

## Procedimiento de upload

Compilar Sensor 2:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action build -Env kx134_sensor_2
```

Subir Sensor 2:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action upload -Env kx134_sensor_2 -Port COMx
```

Si el bootloader no conecta, repetir con BOOT presionado durante `Connecting...`
y soltar cuando aparezca `Writing at...`.

## Validacion Serial

Monitor a 921600 baudios:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action monitor -Port COMx
```

La salida debe incluir diagnostico, encabezado CSV KX134 v3 y muestras con:

- `sensor_id=2`
- `physical_label=KX134_SENSOR_2`
- `node_id=sensor_node_2`
- `sample_rate_hz=100`
- `odr_hz=100`
- `range_g=8`
- `calibration_id=UNCALIBRATED_SENSOR_2`
- `packet_status=CALIBRATION_MISSING`
- sin campos ADXL335/mV prohibidos.

## Criterios READY_FOR_SENSOR_2_CALIBRATION

Sensor 2 queda listo si:

- Upload exitoso.
- KX134 detectado en `0x1F` o `0x1E`.
- CSV header coincide con contrato KX134 v3.
- `sensor_id=2` en todas las muestras limpias.
- MAC no vacia capturada.
- `seq` y `sensor_t_us` incrementan.
- Frecuencia efectiva entre 98 y 102 Hz.
- `g_norm` en reposo cercano a 1 g.
- No hay `SENSOR_INIT_ERROR` ni `SENSOR_READ_ERROR` recurrente.

## Restricciones

- No calibrar Sensor 2.
- No crear `config/calibrations/kx134_sensor_2.json` valido.
- No modificar firmware funcional `src/main.cpp` salvo error tecnico justificado.
- No modificar GUI, empaquetado ni data historica.
- No implementar ESP-NOW ni sincronizacion dual.

## Archivos generados

- `reports/kx134_test_runs/TICKET_010_SENSOR2_UPLOAD_TEST_SUMMARY.md`
- `reports/kx134_test_runs/TICKET_010_sensor2_visible_monitor_<timestamp>.txt`
- `config/kx134_node_map.json` actualizado con MAC Sensor 2 si la validacion pasa.
