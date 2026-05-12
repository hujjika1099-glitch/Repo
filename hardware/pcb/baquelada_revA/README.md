# Baquelada RevA

## Identificacion

- Nombre: Baquelada RevA.
- Origen: Proteus Design Suite.
- Formato recibido: PDF/SVG.
- Archivos registrados:
  - `hardware/pcb/baquelada_revA/artifacts/Maestria.PDF`
  - `hardware/pcb/baquelada_revA/artifacts/Maestria.SVG`
- Proposito: baquelada funcional para prototipo KX134 Sensor 1/Sensor 2.
- Estado: `functional_validated_by_expert`.

## Decision de uso

Esta baquelada RevA fue completada fisicamente y validada como funcional por el experto del proyecto. Queda aceptada para uso de prototipo; no equivale a paquete de fabricacion industrial repetible.

- `BAQUELADA_REVA_REGISTERED = YES`
- `BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = YES`
- `PROTOTYPE_PCB_REVA_AUTHORIZED_FOR_USE = YES`; `PRODUCTION_MANUFACTURING_PACKAGE_READY = NO`

## Dimensiones declaradas por SVG

- Ancho: 90.49 mm.
- Alto: 44.99 mm.
- Fuente: atributo `width` / `height` del SVG.
- `viewBox`: `0 0 9049 4499`.

Estas dimensiones provienen del SVG registrado. La validacion funcional final fue reportada por el experto del proyecto.

## Advertencias

- Confirmar escala 1:1 impresa.
- Confirmar mirror/orientacion de capa segun cara de cobre.
- Confirmar que la capa exportada corresponde a la cara fisica que se usara.
- No hay netlist formal registrada en el repo.
- No hay DRC formal registrado en el repo.
- No hay nombres de net visibles en el SVG revisado.
- No hay marcas de orientacion de Sensor 1/Sensor 2 visibles en el artefacto exportado.
- Pruebas fisicas posteriores quedan bajo responsabilidad del experto del proyecto.

## Artefactos pendientes

- Proyecto Proteus: opcional/no entregado al repo.
- Librerias/footprints Proteus: opcional/no entregadas al repo.
- DFM/BOM/Gerbers/QA de manufactura: pendiente solo si se requiere fabricacion repetible.
- Rol exacto de placa: baquela para nodo sensor KX134, repetida para Sensor 1 y Sensor 2.
- Receptor: sin baquela en esta RevA; queda conectado directamente al PC.

## Cierre Final TICKET 028

- `PROJECT_FUNCTIONAL_COMPLETE = YES`
- `PROTOTYPE_RELEASE_CANDIDATE_READY = YES`
- `BAQUELADA_REVA_FUNCTIONAL_VALIDATED_BY_EXPERT = YES`
- `BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = YES`
- `PRODUCTION_MANUFACTURING_PACKAGE_READY = NO`

La baquelada RevA fue completada fisicamente y validada como funcional por el experto del proyecto. Queda aceptada para uso de prototipo KX134 Sensor 1/Sensor 2. Esto no constituye paquete de fabricacion industrial repetible; si el cliente lo requiere, faltan DFM, BOM final, Gerbers y QA de manufactura.
