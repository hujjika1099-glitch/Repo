# KX134 Receiver Identity Firmware

Firmware minimo para capturar la MAC de la ESP32 que sera receptora del sistema KX134
dual.

Este firmware no lee sensores, no emite datos ADXL335/KX134 y no implementa ESP-NOW.
Solo configura WiFi en modo STA, imprime la MAC por Serial y repite una linea de
identidad cada 2 segundos.

## Build

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\pio.ps1 run -d firmware\kx134_receiver_identity
```

## Upload

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\pio.ps1 run -d firmware\kx134_receiver_identity -t upload --upload-port COMX
```

Puede requerir mantener BOOT durante `Connecting...` y soltar cuando empiece
`Writing at...`.

## Monitor

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\pio.ps1 device monitor -p COMX -b 921600
```

Lineas esperadas:

```text
# firmware=kx134_receiver_identity
# role=receiver_esp32
# node_id=receiver_esp32
# receiver_mac=XX:XX:XX:XX:XX:XX
# status=READY_FOR_NODE_MAP_CAPTURE
```

Este firmware sera reemplazado por el firmware receptor ESP-NOW KX134 en el siguiente
ticket.
