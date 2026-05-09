# Cableado SEN-17589/KX134 con ESP32 por I2C/Qwiic

## Objetivo

Documentar la conexion fisica para probar una ESP32 sensora con un SEN-17589/KX134 usando el firmware `firmware/kx134_single_node_i2c`.

## Conexion principal

| SEN-17589/KX134 | ESP32 | Descripcion |
|---|---|---|
| 3V3 | 3V3 | Alimentacion 3.3 V |
| GND | GND | Tierra comun |
| SDA | GPIO21 | I2C datos |
| SCL | GPIO22 | I2C reloj |

## Pines no usados en este prototipo

| Pin | Estado |
|---|---|
| INT1 | Sin conectar |
| INT2 | Sin conectar |
| TRIG | Sin conectar |
| ADR/SDO | Sin modificar |
| CS | Sin conectar |

## Reglas

- No conectar el modulo a 5V.
- Usar 3.3 V.
- Mantener GND comun.
- No modificar jumpers para la primera prueba.
- La direccion I2C default esperada es 0x1E.
- El firmware intenta detectar 0x1F y luego 0x1E.
- Para pruebas de vibracion o montaje final, usar soldadura en PTH o conexion mecanicamente firme.

## Misma conexion para ambos nodos sensores

Para `sensor_id=1`:

- ESP32 sensora 1 usa GPIO21/GPIO22.

Para `sensor_id=2`:

- ESP32 sensora 2 usara la misma asignacion GPIO21/GPIO22 salvo decision posterior.

## Advertencia

Este documento aplica al firmware single-node. El firmware ESP-NOW dual se implementara en tickets posteriores.
