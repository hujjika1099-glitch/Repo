# Arduino IDE - Dual Node ESP-NOW

Estas carpetas permiten subir el firmware desde Arduino IDE sin depender de PlatformIO.

## Sketches
- `sensor_node_espnow/sensor_node_espnow.ino`
- `receiver_node_espnow/receiver_node_espnow.ino`

## Configuracion de dos transmisores
- Primer transmisor:
  - en `sensor_node_espnow.ino` dejar `kSensorId = 1`
  - dejar `kSensorLabel = "sensor_B"`
- Segundo transmisor:
  - copiar el mismo sketch a otra carpeta de Arduino IDE
  - cambiar `kSensorId = 2`
  - cambiar `kSensorLabel = "sensor_A"`

## Hardware
- `sensor_node_espnow`:
  - ADXL335 `X-OUT -> GPIO32`
  - ADXL335 `Y-OUT -> GPIO33`
  - ADXL335 `Z-OUT -> GPIO34`
  - ADXL335 `ST -> GPIO23`
  - `VCC -> 3V3`
  - `GND -> GND`
- `receiver_node_espnow`:
  - solo ESP32 por USB al PC

## Ajustes Arduino IDE
- Board: `ESP32 Dev Module`
- Upload speed: `115200`
- Monitor speed: `115200`
- Core ESP32: compatible con callback ESP-NOW de Arduino ESP32 2.x y 3.x

## Orden recomendado
1. Abrir `receiver_node_espnow.ino` y subirlo a la ESP32 puente USB.
2. Abrir `sensor_node_espnow.ino` y subirlo a la ESP32 con el ADXL335.
3. Verificar en el monitor serie del receptor:
   - `# relay=espnow_receiver`
   - `sensor_id,seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z`
   - filas CSV cuando el transmisor este encendido
4. Cerrar el monitor serie de Arduino IDE para liberar el puerto.
5. En MATLAB ejecutar:
   - `run('live_session_hub/sensorB_live_prompt_session.m')`

## Nota operativa
- El peer esta en modo `broadcast` para evitar configurar MACs manualmente en el primer bring-up.
- MATLAB solo necesita ver el puerto USB del receptor; no importa cuantos transmisores potenciales existan mientras uses un solo concentrador operativo.
