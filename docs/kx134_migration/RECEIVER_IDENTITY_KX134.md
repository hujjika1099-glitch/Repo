# Identidad de ESP32 Receptora KX134

## Rol

La tercera ESP32 sera el receptor del sistema KX134 dual. Recibira paquetes por ESP-NOW
desde:

- `sensor_node_1` / `sensor_id=1`
- `sensor_node_2` / `sensor_id=2`

y enviara el stream consolidado por USB Serial hacia la aplicacion de captura.

## Motivo de Capturar MAC

ESP-NOW usa direcciones MAC para emparejar nodos. Antes de implementar el receptor
completo se registra la MAC real de la ESP32 receptora en `config/kx134_node_map.json`
para evitar suposiciones durante el firmware dual.

## Firmware de Identidad

Ruta:

`firmware/kx134_receiver_identity`

Este firmware solo imprime identidad por Serial. No implementa ESP-NOW, no lee sensores
y no genera columnas ADXL335/KX134.

## Comandos

Build:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\pio.ps1 run -d firmware\kx134_receiver_identity
```

Upload:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\pio.ps1 run -d firmware\kx134_receiver_identity -t upload --upload-port COMX
```

Monitor:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\pio.ps1 device monitor -p COMX -b 921600
```

## Interpretacion

La linea clave es:

```text
# receiver_mac=XX:XX:XX:XX:XX:XX
```

Esa MAC se copia en `config/kx134_node_map.json` bajo `receiver_esp32.esp32_mac`.

## Siguiente Paso

Con las MAC de Sensor 1, Sensor 2 y receptor cerradas, el siguiente ticket debe preparar
el firmware ESP-NOW KX134 dual: dos nodos sensores hacia receptor USB Serial.
