# Pinout check - Baquelada RevA

## Pregunta abierta

Esta baquela RevA es para nodo sensor KX134, para receptor, o para otra funcion?

Respuesta registrada en esta corrida:

- `board_role = PENDING`

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

## Si la baquela es para receptor

Validar:

- No debe tener KX134.
- Debe exponer USB/Serial.
- No requiere SDA/SCL para KX134.
- Debe mantener acceso a programacion/reset.

## Decision actual

- `pinout_review.status = PENDING`
- `pinout_review.confirmed = false`

No energizar como nodo sensor ni receptor hasta confirmar rol y pinout.
