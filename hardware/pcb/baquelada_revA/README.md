# Baquelada RevA

## Identificacion

- Nombre: Baquelada RevA.
- Origen: Proteus Design Suite.
- Formato recibido: PDF/SVG.
- Archivos registrados:
  - `hardware/pcb/baquelada_revA/artifacts/Maestria.PDF`
  - `hardware/pcb/baquelada_revA/artifacts/Maestria.SVG`
- Proposito: prototipo fisico de revision.
- Estado: `under_review`.

## Decision de uso

Esta baquelada RevA se registra como prototipo fisico bajo revision. No es PCB final autorizada.

- `BAQUELADA_REVA_REGISTERED = YES`
- `BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = NO`
- `PCB_DESIGN_AUTHORIZED = NO`

## Dimensiones declaradas por SVG

- Ancho: 90.49 mm.
- Alto: 44.99 mm.
- Fuente: atributo `width` / `height` del SVG.
- `viewBox`: `0 0 9049 4499`.

Estas dimensiones deben confirmarse contra impresion real 1:1 con calibre antes de transferir o energizar.

## Advertencias

- Confirmar escala 1:1 impresa.
- Confirmar mirror/orientacion de capa segun cara de cobre.
- Confirmar que la capa exportada corresponde a la cara fisica que se usara.
- No hay netlist formal registrada en el repo.
- No hay DRC formal registrado en el repo.
- No hay nombres de net visibles en el SVG revisado.
- No hay marcas de orientacion de Sensor 1/Sensor 2/Receptor visibles en el artefacto exportado.
- No energizar hasta completar continuidad y shorts con multimetro.

## Artefactos pendientes

- Proyecto Proteus: `PENDING`.
- Librerias/footprints Proteus: `PENDING`.
- Netlist/DRC: `PENDING`.
- Rol exacto de placa: `PENDING`.
