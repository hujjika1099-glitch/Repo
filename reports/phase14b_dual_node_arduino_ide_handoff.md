# Fase 14B.2 - Handoff Arduino IDE Dual Node ESP-NOW

Fecha: 2026-03-31

## Objetivo
Dejar el flujo `ADXL335 -> ESP32 sensor -> ESP-NOW -> ESP32 receiver -> USB -> MATLAB` listo para subir desde Arduino IDE sin depender de PlatformIO.

## Entregable
Se agregaron sketches autocontenidos:
- `firmware/dual_node_espnow/arduino_ide/sensor_node_espnow/sensor_node_espnow.ino`
- `firmware/dual_node_espnow/arduino_ide/receiver_node_espnow/receiver_node_espnow.ino`
- `firmware/dual_node_espnow/arduino_ide/README.md`

## Comportamiento esperado
- `sensor_node_espnow`
  - lee ADXL335 por `GPIO32/33/34`
  - deja `ST` en `GPIO23`
  - empaqueta `seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z`
  - envia por ESP-NOW en canal `6`
- `receiver_node_espnow`
  - recibe el paquete por ESP-NOW
  - imprime el mismo header CSV que consume MATLAB
  - expone metadata `# relay=espnow_receiver` para autodeteccion del puerto en MATLAB

## Orden operativo
1. Subir `receiver_node_espnow.ino` a la ESP32 conectada por USB al PC.
2. Subir `sensor_node_espnow.ino` a la ESP32 con el ADXL335.
3. Abrir monitor serie del receptor y verificar:
   - `# relay=espnow_receiver`
   - `# source=sensor_node`
   - `seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z`
   - filas CSV cuando el transmisor este encendido
4. Cerrar el monitor serie de Arduino IDE para liberar el puerto.
5. Ejecutar en MATLAB:
   - `run('live_session_hub/sensorB_live_prompt_session.m')`

## Decision tecnica
- Se mantiene `broadcast` para el peer ESP-NOW en esta etapa.
- Motivo: minimizar friccion para el primer upload manual en Arduino IDE.
- MATLAB solo necesita el puerto USB del receptor, no el de los transmisores.

## Riesgo residual
- No se verifico compilacion con `arduino-cli` porque no esta disponible en este entorno.
- El codigo fuente del sketch replica la logica ya compilada con exito en PlatformIO, por lo que el riesgo principal queda del lado de configuracion local de Arduino IDE y seleccion de board/core.
