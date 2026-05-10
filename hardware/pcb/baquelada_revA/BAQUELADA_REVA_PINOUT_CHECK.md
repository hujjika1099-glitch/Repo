# Pinout check - Baquelada RevA

## Rol registrado

El usuario confirmo que esta baquela RevA es para nodo sensor KX134 y que se repite para Sensor 1 y Sensor 2.

Respuesta registrada:

- `board_role = kx134_sensor_node_repeated_for_sensor_1_and_sensor_2`
- Receptor: no usa baquela; queda conectado directamente al PC.

## Si la baquela es para nodo sensor KX134

Validar obligatoriamente:

| ESP32 | KX134 | Estado |
|---|---|---|
| 3V3 | 3V3 | PENDING |
| GND | GND | PENDING |
| GPIO21 | SDA | PENDING |
| GPIO22 | SCL | PENDING |
| INT1 | Sin uso | PENDING |
| INT2/TRIG | Sin uso | PENDING |
| CS | Sin uso / modo I2C | PENDING |
| ADR/SDO | Sin modificar salvo decision futura | PENDING |

Notas:

- Confirmar direccion I2C esperada 0x1F/0x1E durante firmware single-node.
- Confirmar que SDA no esta intercambiado con SCL.
- Confirmar que 3V3 y GND no estan invertidos.

## Receptor

No aplica para esta RevA. El receptor no requiere baquela en esta etapa porque queda conectado directamente al PC.

## Decision actual

- `pinout_review.status = PENDING_SENSOR_NODE_ROLE_CONFIRMED`
- `pinout_review.confirmed = false`

No energizar como nodo sensor hasta confirmar pinout con continuidad, escala y orientacion mirror/layer.
