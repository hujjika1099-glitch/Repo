# TICKET 006 - Firmware minimo KX134 para una ESP32 sensora por I2C/Qwiic

## Objetivo

Crear un firmware minimo, aislado y compilable para leer un SEN-17589/KX134 por I2C/Qwiic usando una ESP32 sensora.

## Rama

`feature/kx134-dual-capture`

## Entregables

- `firmware/kx134_single_node_i2c/platformio.ini`
- `firmware/kx134_single_node_i2c/src/main.cpp`
- `firmware/kx134_single_node_i2c/README.md`
- `docs/kx134_migration/FIRMWARE_SINGLE_NODE_KX134_I2C.md`
- `docs/kx134_migration/tickets/TICKET_006_FIRMWARE_SINGLE_NODE_KX134_I2C.md`
- Actualizacion de `docs/kx134_migration/TICKET_BACKLOG.md`
- Actualizacion de `reports/change_log.md`

## Restricciones

- No modificar firmware ADXL335 existente.
- No modificar receptor.
- No implementar ESP-NOW.
- No modificar GUI.
- No modificar empaquetado.
- No modificar scripts funcionales.
- No modificar datos historicos.
- No implementar calibracion.
- No crear binarios para commit.
- No commitear `.pio/`.

## Criterios de aceptacion

- Existe proyecto `firmware/kx134_single_node_i2c`.
- El firmware usa `SparkFun_KX134`.
- El firmware usa I2C/Qwiic.
- El firmware compila si PlatformIO y dependencias estan disponibles.
- El firmware permite sample rate 100, 200, 400 y 800 Hz.
- El firmware usa 100 Hz como default.
- El firmware permite rango 8, 16, 32 y 64 g.
- El firmware usa 8 g como default de prueba.
- El firmware imprime `x_raw/y_raw/z_raw`.
- El firmware imprime `x_g/y_g/z_g`.
- El firmware imprime `sensor_id`.
- El firmware imprime `node_mac`.
- El firmware imprime `seq`.
- El firmware imprime `sensor_t_us`.
- El firmware no usa `analogRead`.
- El firmware no usa `analogReadMilliVolts`.
- El firmware no imprime `mv_*`.
- El firmware no imprime `gx_est/gy_est/gz_est/g_norm_est`.
- No hay cambios en GUI.
- No hay cambios en empaquetado.
- Git queda limpio despues del commit.
- La rama queda publicada en origin si las credenciales lo permiten.

## Estado de cierre

- Estado: completado en codigo/documentacion.
- Fecha: 2026-05-09.
- Rama: `feature/kx134-dual-capture`.
- Commit base TICKET 005: `5555bf648bbd4ffccfb1f0c82b2781d75b402336`.
- Cambios en receptor/GUI/empaquetado: ninguno.
