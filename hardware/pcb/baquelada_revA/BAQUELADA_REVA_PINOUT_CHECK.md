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
| 3V3 | 3V3 | validated_by_expert_functional_test |
| GND | GND | validated_by_expert_functional_test |
| GPIO21 | SDA | validated_by_expert_functional_test |
| GPIO22 | SCL | validated_by_expert_functional_test |
| INT1 | Sin uso | not_used_for_current_prototype |
| INT2/TRIG | Sin uso | not_used_for_current_prototype |
| CS | Sin uso / modo I2C | not_used_for_current_prototype |
| ADR/SDO | Sin modificar salvo decision futura | not_used_for_current_prototype |

Notas:

- Confirmar direccion I2C esperada 0x1F/0x1E durante firmware single-node.
- Confirmar que SDA no esta intercambiado con SCL.
- Confirmar que 3V3 y GND no estan invertidos.

## Receptor

No aplica para esta RevA. El receptor no requiere baquela en esta etapa porque queda conectado directamente al PC.

## Decision actual

- `pinout_review.status = FUNCTIONAL_VALIDATED_BY_EXPERT`
- `pinout_review.confirmed = true`
- `BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = YES`

La RevA esta aceptada para el prototipo Sensor 1/Sensor 2. Fabricacion repetible requiere paquete adicional si se solicita.

## Cierre Final TICKET 028

- `PROJECT_FUNCTIONAL_COMPLETE = YES`
- `PROTOTYPE_RELEASE_CANDIDATE_READY = YES`
- `BAQUELADA_REVA_FUNCTIONAL_VALIDATED_BY_EXPERT = YES`
- `BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = YES`
- `PRODUCTION_MANUFACTURING_PACKAGE_READY = NO`

La baquelada RevA fue completada fisicamente y validada como funcional por el experto del proyecto. Queda aceptada para uso de prototipo KX134 Sensor 1/Sensor 2. Esto no constituye paquete de fabricacion industrial repetible; si el cliente lo requiere, faltan DFM, BOM final, Gerbers y QA de manufactura.
