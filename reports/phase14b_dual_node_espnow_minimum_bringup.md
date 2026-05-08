# Fase 14B - Bring-up Minimo Dual Node ESP-NOW

Fecha: 2026-03-30

## Ultimo punto estable antes de escalar
- El estado operativo cerrado del repo quedo en `sensor_B` como modulo primario.
- El firmware estable previo sigue siendo `firmware/single_node_calibration/src/main.cpp`.
- La captura live estable sigue siendo:
  - `run('live_session_hub/sensorB_live_prompt_session.m')`
- La regla ya fijada en el repo era no romper el parser MATLAB:
  - `seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z`

Referencias directas:
- `reports/phase13_sensor_module_selection.md`
- `reports/sensor_B_operational_runbook_phase13.md`
- `firmware/dual_node_espnow/phase14b_transport_contract.json`

## Objetivo de esta fase minima
Implementar la primera topologia inalambrica sin cambiar MATLAB:
1. ESP32 `sensor_node` con ADXL335.
2. ESP32 `receiver_node` conectada por USB al PC.
3. `receiver_node` imprime exactamente el mismo CSV que antes leia MATLAB por serial directo.

## Implementacion agregada
Se creo un proyecto nuevo en:
- `firmware/dual_node_espnow/platformio.ini`

Targets:
- `sensor_node`
- `receiver_node`

Archivos clave:
- `firmware/dual_node_espnow/include/transport_packet.h`
- `firmware/dual_node_espnow/include/transport_config.h`
- `firmware/dual_node_espnow/src/sensor_node_main.cpp`
- `firmware/dual_node_espnow/src/receiver_node_main.cpp`

## Verificacion local realizada
Compilacion verificada en local con PlatformIO:
- `sensor_node`: `SUCCESS`
- `receiver_node`: `SUCCESS`

Incidencia del entorno:
- reaparecio la dependencia faltante `intelhex` dentro de `~/.platformio/penv`
- se corrigio localmente con `python -m pip install intelhex`
- no fue necesario cambiar el codigo del repo para resolver esa parte del toolchain

## Contrato operativo respetado
- Frecuencia objetivo: `100 Hz`
- Canal Wi-Fi fijado: `6`
- El receptor USB imprime:
  - lineas metadata con `#`
  - header CSV exacto
  - muestras CSV exactas compatibles con `matlab/live/parse_adxl335_stream_line.m`

## Bring-up recomendado para la primera prueba
### 1. Cargar `receiver_node` en la ESP32 puente
Compilar:
```powershell
$env:PLATFORMIO_EXE="$env:USERPROFILE\.platformio\penv\Scripts\pio.exe"
& $env:PLATFORMIO_EXE run -d .\firmware\dual_node_espnow -e receiver_node
```

Subir:
```powershell
$env:PLATFORMIO_EXE="$env:USERPROFILE\.platformio\penv\Scripts\pio.exe"
& $env:PLATFORMIO_EXE run -d .\firmware\dual_node_espnow -e receiver_node -t upload
```

Validacion esperada en monitor serie:
- `# relay=espnow_receiver`
- `# relay_mac=...`
- `seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z`

### 2. Cargar `sensor_node` en la ESP32 con acelerometro
Cableado:
- `VCC -> 3V3`
- `GND -> GND`
- `X-OUT -> GPIO32`
- `Y-OUT -> GPIO33`
- `Z-OUT -> GPIO34`
- `ST -> GPIO23`

Compilar:
```powershell
$env:PLATFORMIO_EXE="$env:USERPROFILE\.platformio\penv\Scripts\pio.exe"
& $env:PLATFORMIO_EXE run -d .\firmware\dual_node_espnow -e sensor_node
```

Subir:
```powershell
$env:PLATFORMIO_EXE="$env:USERPROFILE\.platformio\penv\Scripts\pio.exe"
& $env:PLATFORMIO_EXE run -d .\firmware\dual_node_espnow -e sensor_node -t upload
```

### 3. Verificacion funcional
- Mantener la ESP32 `receiver_node` conectada por USB al PC.
- Encender la ESP32 `sensor_node`.
- Verificar en el serial del receptor que empiezan a salir filas CSV con los 8 campos esperados.
- Si eso ocurre, MATLAB puede seguir usando el mismo launcher live, solo apuntando al COM del receptor.

## Decision tecnica para esta fase
- Se deja `broadcast` por defecto en `transport_config.h`.
- Motivo: reducir friccion en la primera prueba `1 sensor + 1 receptor`.
- Endurecimiento posterior recomendado:
  - pasar a `unicast`
  - fijar MAC del receptor
  - agregar identificacion explicita de fuente para etapa multi-sensor

## Limite actual intencional
Esta fase no resuelve todavia el escenario final de `2 acelerometros -> 1 receptor -> MATLAB`.
Para esa etapa hara falta definir una estrategia explicita de multiplexacion/identidad de sensor sin romper trazabilidad.
