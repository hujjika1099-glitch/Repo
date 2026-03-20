# Fase 5: Upload y Monitor Serie (Single Node)

Fecha: 2026-03-20

## Contexto
- Proyecto: `firmware/single_node_calibration`
- Entorno: `esp32dev`
- Puerto objetivo: `COM5`
- Ejecutable PlatformIO:
  - `C:\\Users\\JOSE DAVID\\.platformio\\penv\\Scripts\\pio.exe`

## Verificacion previa
- `platformio.ini` ajustado con:
  - `upload_port = COM5`
  - `monitor_port = COM5`
- Firmware baseline presente en:
  - `firmware/single_node_calibration/src/main.cpp`

## Resultado de upload
- Comando:
  - `pio run --target upload --environment esp32dev`
- Resultado:
  - `FAILED`
- Error principal:
  - `Failed to connect to ESP32: Wrong boot mode detected (0x13)! The chip needs to be in download mode.`
- Reintento controlado:
  - `pio run --target upload --environment esp32dev --upload-port COM5`
  - Resultado: `FAILED` con el mismo error.

## Resultado de monitor serie
- Escaneo de dispositivos:
  - `COM5` detectado como `Silicon Labs CP210x USB to UART Bridge`.
- Captura serial de evidencia en `COM5` a `115200`:
  - Se obtuvieron lineas reales de arranque y telemetria.
  - Fragmento representativo:

```text
ets Jul 29 2019 12:21:46
rst:0x1 (POWERON_RESET),boot:0x13 (SPI_FAST_FLASH_BOOT)
...
#NODE,1,READY,mac=D4:E9:F4:E8:28:08,channel=6
#STAT,node=1,run=0,seq=0,pkts=0,sendFails=0,overruns=0
```

## Validacion de formato esperado del baseline
Formato esperado del baseline:
- `seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z`

Observacion:
- El stream observado no coincide con el formato CSV del baseline ADXL335.
- Esto es consistente con upload no aplicado y presencia de firmware previo en el dispositivo.

## Observaciones operativas
- El puerto serie es claro (`COM5`) y responde.
- El bloqueo actual es entrada a modo descarga (bootloader) durante upload.
- Se requiere intervencion manual de operador para forzar modo descarga (secuencia BOOT/EN) y repetir upload.

## Decision operativa
- `blocked`
