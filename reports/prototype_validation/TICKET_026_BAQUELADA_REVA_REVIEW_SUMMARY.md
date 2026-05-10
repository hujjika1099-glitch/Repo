# TICKET 026 - Baquelada RevA review summary

## Fecha

2026-05-10

## Artefactos recibidos

- PDF: `hardware/pcb/baquelada_revA/artifacts/Maestria.PDF`
- SVG: `hardware/pcb/baquelada_revA/artifacts/Maestria.SVG`
- Proteus project: `PENDING`

## Dimensiones detectadas

- Ancho: 90.49 mm.
- Alto: 44.99 mm.
- Fuente: SVG exportado por Proteus.
- `viewBox`: `0 0 9049 4499`.

## Revision visual

- `BAQUELADA_REVA_VISUAL_REVIEW = PASS_WITH_WARNINGS`

Observaciones:

- Placa rectangular.
- Pistas gruesas.
- Pads circulares/laterales.
- Zonas tipo header.
- Sin serigrafia funcional visible.
- Sin nombres de net visibles.
- Sin labels 3V3/GND/SDA/SCL.
- Sin marcas de orientacion visibles.
- Sin layer/mirror explicito.
- Sin netlist/DRC entregado.

## Board role

- `board_role = kx134_sensor_node_repeated_for_sensor_1_and_sensor_2`

El usuario confirmo que la baquela RevA aplica a nodos sensores KX134 y se repite para Sensor 1 y Sensor 2. El receptor no lleva baquela en esta etapa porque queda conectado directamente al PC.

## Pinout

- `pinout_review.status = PENDING_SENSOR_NODE_ROLE_CONFIRMED`
- `pinout_review.confirmed = false`

Pinout esperado si aplica a nodo sensor KX134:

- ESP32 3V3 -> KX134 3V3.
- ESP32 GND -> KX134 GND.
- ESP32 GPIO21 -> KX134 SDA.
- ESP32 GPIO22 -> KX134 SCL.

## Continuidad

- `continuity_test.status = PENDING`

No se ejecutaron pruebas con multimetro en este ticket.

## Scale/mirror

- `scale_1_to_1_confirmed = false`
- `mirror_orientation_confirmed = false`

## Decision

- `BAQUELADA_REVA_REGISTERED = YES`
- `BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = NO`
- `PCB_DESIGN_AUTHORIZED = NO`

## Proximos pasos

1. Confirmar escala 1:1 con calibre.
2. Confirmar mirror/orientacion de capa.
3. Ejecutar continuidad con multimetro.
4. Confirmar pinout contra footprint Proteus.
5. Ejecutar power-on sin sensor con limitacion de corriente si es posible.
6. Ejecutar prueba single-node KX134 en una baquela de Sensor 1 o Sensor 2.
7. Repetir para la segunda baquela si se fabrica para ambos sensores.
8. Ejecutar prueba dual solo despues de aprobar fases previas.

## Restricciones

- Firmware no modificado.
- GUI no modificada.
- Calibraciones no modificadas.
- Empaquetado no modificado.
- Data historica no modificada.
- No se generaron Gerbers.
- PCB final no autorizada.
