# Fase 5.1: Guided Bootloader Upload (Single Node Baseline)

Fecha: 2026-03-20

## Puerto y contexto
- COM usado: `COM5`
- Dispositivo detectado: `Silicon Labs CP210x USB to UART Bridge`
- Proyecto: `firmware/single_node_calibration`
- Firmware objetivo: baseline ADXL335 con salida CSV

## Secuencia manual aplicada (operador humano)
1. Mantener presionado `BOOT`.
2. Cuando inicia el intento de upload, pulsar y soltar `EN/RST`.
3. Mantener `BOOT` unos segundos mientras conecta el cargador.
4. Soltar `BOOT` cuando avanza la conexion.

## Intentos ejecutados (maximo permitido: 2)

### Intento 1
- Comando:
  - `pio run --target upload --environment esp32dev --upload-port COM5`
- Resultado:
  - `FAILED`
- Evidencia de error:
  - `Invalid head of packet (0x65): Possible serial noise or corruption.`
  - `A fatal error occurred: The chip stopped responding.`

### Intento 2
- Ajuste minimo previo:
  - `upload_speed = 115200` en `platformio.ini`
- Comando:
  - `pio run --target upload --environment esp32dev --upload-port COM5`
- Resultado:
  - `SUCCESS`
- Evidencia clave:
  - `Chip is ESP32-D0WD-V3`
  - escritura y verificacion de imagen completadas
  - `Hard resetting via RTS pin...`

## Evidencia serial posterior al upload
Captura en `COM5` a `115200` (post-reset):

```text
# adxl335_single_node_baseline
# board=esp32dev
# pins:x=GPIO32,y=GPIO33,z=GPIO34
# sample_hz=100
seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z
0,342266,1808,1776,1200,1637,1583,1134
1,351396,1808,1737,1205,1636,1581,1089
2,361396,1932,1742,1206,1636,1577,1134
3,371396,1809,1753,1205,1641,1588,1138
```

## Resultado final
- Upload guided bootloader: `SUCCESS` en intento 2.
- Stream baseline CSV: `VALIDADO`.
- Estado operativo final: `ready_for_matlab`.
