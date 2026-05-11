# Estado Del Repositorio

## Decision Actual

- `PROTOTYPE_DELIVERY_PACKAGE_READY = YES`
- `CLIENT_USER_DOCS_READY = YES`
- `PCB_DESIGN_AUTHORIZED = NO`
- `BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = NO`
- `REPOSITORY_PRODUCTION_READY = YES_WITH_SCREENSHOTS_PENDING`

## Estado Operativo

El flujo principal actual es KX134 dual. La captura con hardware real, la
exportacion, las graficas live, el empaquetado Windows y la QA visual externa
estan documentados y validados.

ADXL335 se conserva como legacy/historico y no debe confundirse con el flujo
principal.

## Baquelada RevA

La baquelada RevA creada en Proteus esta registrada bajo
`hardware/pcb/baquelada_revA/`. Su estado es `under_review`; no esta aceptada
para uso de prototipo y no autoriza PCB final.

## Pendientes

- Screenshots GUI completos.
- Icono corporativo.
- Firma digital.
- QA visual scaling 125/150.
- Configuracion remota `sample_rate_hz` desde GUI hacia firmware.
- Pruebas electricas de baquelada RevA por experto.
- Decisiones fisicas de PCB: alimentacion, conectores, cableado, montaje,
  orientacion y ubicaciones finales.
