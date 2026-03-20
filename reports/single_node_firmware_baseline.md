# Baseline Firmware: Single Node ADXL335

Fecha: 2026-03-20

## Proposito
Definir un firmware minimo real para adquisicion individual de ADXL335 en una ESP32 de referencia, orientado a captura de banco y analisis posterior.

## Hardware objetivo
- Board: `esp32dev` (ESP32 clasica).
- Sensor: ADXL335 (analogico, 3V3).
- Mapeo de pines:
  - X -> GPIO32
  - Y -> GPIO33
  - Z -> GPIO34

## Formato serial de salida
Cabecera:
- Lineas de metadata con prefijo `#`.
- Encabezado CSV:
  - `seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z`

Campos por muestra:
- `seq`: contador incremental por muestra.
- `t_us`: timestamp en microsegundos (`micros()`).
- `raw_x/raw_y/raw_z`: lectura ADC cruda.
- `mv_x/mv_y/mv_z`: lectura en milivoltios.

## Frecuencia objetivo
- `100 Hz` (periodo de `10,000 us`).
- Razon: frecuencia estable y suficiente para baseline de banco, con buena trazabilidad y sin introducir carga innecesaria en fase inicial.

## Estado de compilacion
- Comando ejecutado:
  - `C:\\Users\\JOSE DAVID\\.platformio\\penv\\Scripts\\pio.exe run --environment esp32dev`
- Resultado final: `SUCCESS`.

## Incidencia y correccion aplicada
- Falla inicial de build:
  - `ModuleNotFoundError: No module named 'intelhex'` en `tool-esptoolpy`.
- Correccion minima aplicada:
  - Instalacion de `intelhex` en el entorno local de PlatformIO (`~/.platformio/penv`).
- Resultado tras correccion:
  - Compilacion exitosa.

## Estado de upload
- Diagnostico de puertos serie:
  - `COM5` detectado (Silicon Labs CP210x USB to UART Bridge).
- Upload en esta fase:
  - `DIFERIDO` (no se ejecuto `upload` en Fase 4).
