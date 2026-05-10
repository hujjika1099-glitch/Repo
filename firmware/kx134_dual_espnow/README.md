# KX134 dual ESP-NOW prototype

Firmware PlatformIO independiente para el primer prototipo KX134 con dos nodos sensores y una ESP32 receptora USB.

## Arquitectura

- `kx134_sensor_1_espnow`: ESP32 del Sensor 1, MAC `D4:E9:F4:E9:8E:1C`, KX134 por I2C.
- `kx134_sensor_2_espnow`: ESP32 del Sensor 2, MAC `D4:E9:F4:C3:37:14`, KX134 por I2C.
- `kx134_receiver_espnow`: ESP32 receptora, MAC `00:4B:12:96:9A:80`, salida USB Serial.

Los nodos sensores aplican sus coeficientes de calibracion embebidos en `include/kx134_calibration_constants.h`, preservan `x_raw/y_raw/z_raw` y transmiten paquetes binarios por ESP-NOW. El receptor valida MAC, `sensor_id`, checksum y contrato antes de emitir una fila CSV KX134 v3.

## Build

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\pio.ps1 run -d firmware\kx134_dual_espnow -e kx134_sensor_1_espnow
powershell -ExecutionPolicy Bypass -File tools\platformio\pio.ps1 run -d firmware\kx134_dual_espnow -e kx134_sensor_2_espnow
powershell -ExecutionPolicy Bypass -File tools\platformio\pio.ps1 run -d firmware\kx134_dual_espnow -e kx134_receiver_espnow
```

## Upload

Sensor 1:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\pio.ps1 run -d firmware\kx134_dual_espnow -e kx134_sensor_1_espnow -t upload --upload-port COMX
```

Sensor 2:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\pio.ps1 run -d firmware\kx134_dual_espnow -e kx134_sensor_2_espnow -t upload --upload-port COMX
```

Receptor:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\pio.ps1 run -d firmware\kx134_dual_espnow -e kx134_receiver_espnow -t upload --upload-port COMX
```

## Monitor receptor

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\pio.ps1 device monitor -p COMX -b 921600
```

La salida valida del receptor usa el encabezado KX134 v3:

```text
protocol_version,session_id,sensor_id,physical_label,node_id,node_mac,seq,sensor_t_us,receiver_t_us,pc_wall_s,sync_group_id,pair_seq,x_raw,y_raw,z_raw,x_g,y_g,z_g,sample_rate_hz,odr_hz,range_g,calibration_id,calibration_applied,packet_status,packet_error_code,firmware_version,contract_version
```

Las lineas que empiezan por `#` son diagnostico.

## Limitaciones

- `pair_seq` es todavia un contador del receptor, no una sincronizacion definitiva.
- `pc_wall_s=0` hasta integrar el flujo en la GUI KX134.
- Frecuencia actual: 100 Hz.
- Rango actual: 8 g.
- Canal ESP-NOW actual: 1.
- Las calibraciones estan embebidas en `include/kx134_calibration_constants.h`; si un sensor se recalibra, este header debe actualizarse.
