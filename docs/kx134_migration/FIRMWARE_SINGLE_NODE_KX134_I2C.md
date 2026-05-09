# Firmware minimo KX134 - una ESP32 sensora

## Objetivo

Validar lectura basica de un SEN-17589/KX134 conectado por I2C/Qwiic a una ESP32 sensora.

## Relacion con arquitectura final

Este firmware representa solo uno de los dos nodos sensores futuros.

Arquitectura final:

- ESP32 sensora 1 con `sensor_id=1`.
- ESP32 sensora 2 con `sensor_id=2`.
- ESP32 receptora por ESP-NOW.
- Aplicacion por Serial USB.

El mismo proyecto PlatformIO soporta Sensor 1 y Sensor 2 mediante build flags:

- `kx134_sensor_1`: compila con `KX134_SENSOR_ID=1`.
- `kx134_sensor_2`: compila con `KX134_SENSOR_ID=2`.
- `esp32dev`: alias historico compatible de Sensor 1.

No se requiere cambiar `src/main.cpp` para alternar entre Sensor 1 y Sensor 2.

## Datos generados

El firmware genera:

- `x_raw`.
- `y_raw`.
- `z_raw`.
- `x_g`.
- `y_g`.
- `z_g`.
- `sensor_id`.
- `node_mac`.
- `seq`.
- `sensor_t_us`.
- `sample_rate_hz`.
- `odr_hz`.
- `range_g`.

## Conversion basica a g

Formula:

```text
axis_g = axis_raw * range_g / 32768.0
```

La conversion:

- No reemplaza los datos crudos.
- No aplica calibracion.
- No aplica filtros.
- No hace analisis profundo.

## Frecuencias permitidas

- 100 Hz.
- 200 Hz.
- 400 Hz.
- 800 Hz.

Default:

- 100 Hz.

Nota:

- 800 Hz debe validarse en firmware/libreria y por ancho de banda Serial.

## Rango g

Default de prueba:

- 8 g.

Valores permitidos:

- 8 g.
- 16 g.
- 32 g.
- 64 g.

El rango final del sistema sigue pendiente.

## Criterios de prueba fisica para el usuario

Despues de cargar el firmware:

1. Abrir monitor serial a 921600 baudios.
2. Confirmar que aparecen lineas de diagnostico con `#`.
3. Confirmar que aparece el encabezado CSV.
4. Confirmar que `sensor_id` aparece como 1 por default.
5. Confirmar que `node_mac` no esta vacio.
6. Confirmar que `seq` incrementa.
7. Confirmar que `sensor_t_us` incrementa.
8. Confirmar que `x_raw/y_raw/z_raw` cambian al mover el sensor.
9. Confirmar que en reposo una de las componentes en g se acerca aproximadamente a +/-1 g segun orientacion.
10. Confirmar que no aparecen `mv_x/mv_y/mv_z`.
11. Confirmar que no aparecen `gx_est/gy_est/gz_est/g_norm_est`.

## Resultado esperado

El usuario debe reportar:

- Salida inicial completa del monitor serial.
- 10 a 20 lineas de muestra.
- Si el sensor inicializa en 0x1F o 0x1E.
- Si la lectura parece estable.
- Si hubo errores `SENSOR_INIT_ERROR` o `SENSOR_READ_ERROR`.

## Comandos Sensor 2

Compilar:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action build -Env kx134_sensor_2
```

Subir:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action upload -Env kx134_sensor_2 -Port COMx
```

Validar monitor:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action monitor -Port COMx
```
