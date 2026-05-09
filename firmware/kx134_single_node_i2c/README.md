# KX134 Single Node I2C Prototype

## Proposito

Firmware minimo para probar una ESP32 sensora con un SEN-17589/KX134 por I2C/Qwiic.

## Alcance

Incluye:

- Lectura de un KX134.
- Datos crudos `x_raw/y_raw/z_raw`.
- Conversion basica `x_g/y_g/z_g`.
- `sensor_id`.
- `node_mac`.
- `seq`.
- `sensor_t_us`.
- Salida Serial CSV.

No incluye:

- ESP-NOW.
- Receptor.
- GUI.
- Calibracion.
- Sincronizacion dual.
- Empaquetado.

## Hardware

Conexion inicial sugerida:

- SEN-17589/KX134 VIN o 3V3 -> 3V3 ESP32, segun breakout y cableado disponible.
- GND -> GND.
- SDA -> GPIO21 por default.
- SCL -> GPIO22 por default.
- Interfaz: I2C/Qwiic.
- Direccion I2C: el firmware intenta 0x1F y luego 0x1E.

## Cableado rapido

| SEN-17589/KX134 | ESP32 |
|---|---|
| 3V3 | 3V3 |
| GND | GND |
| SDA | GPIO21 |
| SCL | GPIO22 |

## Configuracion

Macros:

- `KX134_SENSOR_ID`: 1 o 2.
- `KX134_SAMPLE_RATE_HZ`: 100, 200, 400 u 800.
- `KX134_RANGE_G`: 8, 16, 32 o 64.
- `KX134_I2C_SDA`: default 21.
- `KX134_I2C_SCL`: default 22.
- `KX134_I2C_FREQ_HZ`: default 400000.
- `KX134_SERIAL_BAUD`: default 921600.

Default de prueba:

- `sensor_id=1`.
- `sample_rate=100 Hz`.
- `range_g=8 g`.

## Entornos PlatformIO

El mismo firmware se compila para Sensor 1 o Sensor 2 mediante build flags:

- `kx134_sensor_1`: `KX134_SENSOR_ID=1`, `KX134_SENSOR_1`, `sensor_node_1`, `UNCALIBRATED_SENSOR_1`.
- `kx134_sensor_2`: `KX134_SENSOR_ID=2`, `KX134_SENSOR_2`, `sensor_node_2`, `UNCALIBRATED_SENSOR_2`.
- `esp32dev`: alias compatible de Sensor 1.

No cargar el entorno de Sensor 1 en la ESP32 destinada a Sensor 2.

## Compilacion

Sensor 1:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action build -Env kx134_sensor_1
```

Sensor 2:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action build -Env kx134_sensor_2
```

## Monitor serial

Comando esperado:

```powershell
pio device monitor -d firmware/kx134_single_node_i2c -b 921600
```

## Uso con wrappers PlatformIO

Estos wrappers no requieren que `pio` este en el PATH.

Build:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action build -Env kx134_sensor_1
```

Build Sensor 2:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action build -Env kx134_sensor_2
```

Listar dispositivos:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action list-devices
```

Upload:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action upload -Env kx134_sensor_1 -Port COM5
```

Upload Sensor 2:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action upload -Env kx134_sensor_2 -Port COM5
```

Monitor:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action monitor -Port COM5
```

Upload y monitor:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action upload-monitor -Env kx134_sensor_2 -Port COM5
```

Reemplazar `COM5` por el puerto real de la ESP32.

## Salida CSV

Debe incluir el encabezado:

```text
protocol_version,session_id,sensor_id,physical_label,node_id,node_mac,seq,sensor_t_us,receiver_t_us,pc_wall_s,sync_group_id,pair_seq,x_raw,y_raw,z_raw,x_g,y_g,z_g,sample_rate_hz,odr_hz,range_g,calibration_id,calibration_applied,packet_status,packet_error_code,firmware_version,contract_version
```

## Limitaciones conocidas

- `receiver_t_us` se imprime como 0 porque no hay receptor en este ticket.
- `pc_wall_s` se imprime como 0 porque no hay GUI en este ticket.
- `calibration_id` indica sensor no calibrado.
- `packet_status` indica `CALIBRATION_MISSING` para muestras validas antes de calibracion.
- 800 Hz puede requerir validacion adicional por rendimiento serial y configuracion High-Performance.
- El rango final del proyecto sigue pendiente.

## Siguiente paso

Despues de validar este firmware con un sensor, se implementara el firmware dual con ESP-NOW.
