# Indice KX134

Este indice resume la documentacion vigente del sistema KX134 dual.

## Estado

- [Estado del repositorio](REPOSITORY_STATUS.md)
- [Estado final del proyecto](PROJECT_FINAL_STATUS.md)
- [Release candidate](RELEASE_CANDIDATE_NOTES.md)
- [Checklist final de entrega](FINAL_HANDOVER_CHECKLIST.md)
- [Resumen tecnico](TECHNICAL_STATUS_SUMMARY.md)
- [Paquete de entrega](PROTOTYPE_DELIVERY_PACKAGE.md)
- [Pendientes y riesgos](OPEN_ITEMS_AND_RISKS.md)

## Arquitectura

- [Arquitectura general](ARCHITECTURE_OVERVIEW.md)
- [Contrato KX134 v3](../../config/kx134_transport_contract_v3.json)
- [Mapa de nodos](../../config/kx134_node_map.json)

## Operacion

- [Operacion diaria](OPERATIONS_OVERVIEW.md)
- [Guia rapida cliente](client/QUICK_START_GUIDE.md)
- [Manual de usuario](client/USER_MANUAL_KX134_PROTOTYPE.md)
- [Troubleshooting](client/TROUBLESHOOTING_GUIDE.md)

## Desarrollo

- [Guia de desarrollo](DEVELOPMENT_GUIDE.md)
- [Empaquetado Windows](WINDOWS_PACKAGING_KX134.md)
- [Graficas live](GUI_KX134_LIVE_PLOTS.md)
- [Exportacion endurecida](KX134_EXPORT_METADATA_HARDENING.md)

## Validacion

- [Resumen de validacion](VALIDATION_SUMMARY.md)
- [Matriz de evidencias](VALIDATION_EVIDENCE_MATRIX.md)
- Reportes en `reports/kx134_gui_validation/`
- Reportes en `reports/prototype_validation/`

## Cliente

- [Documentacion de cliente](client/)
- [Manifiesto de entrega](client/DELIVERY_MANIFEST.md)
- [Limitaciones y advertencias](client/LIMITATIONS_AND_WARNINGS.md)

## PCB/Baquelada

- [Criterios PCB](PCB_BAQUELADA_CRITERIA.md)
- [Formulario fisico PCB](pcb/PCB_PHYSICAL_DECISION_FORM.md)
- [Revision baquelada RevA](../../hardware/pcb/baquelada_revA/BAQUELADA_REVA_REVIEW.md)

## Legacy

- [Notas ADXL335 legacy](LEGACY_ADXL335_NOTES.md)

## Tickets

Los documentos por ticket viven en `docs/kx134_migration/tickets/`.

## Cierre Final TICKET 028

- `PROJECT_FUNCTIONAL_COMPLETE = YES`
- `PROTOTYPE_RELEASE_CANDIDATE_READY = YES`
- `BAQUELADA_REVA_FUNCTIONAL_VALIDATED_BY_EXPERT = YES`
- `BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = YES`
- `PRODUCTION_MANUFACTURING_PACKAGE_READY = NO`

La baquelada RevA fue completada fisicamente y validada como funcional por el experto del proyecto. Queda aceptada para uso de prototipo KX134 Sensor 1/Sensor 2. Esto no constituye paquete de fabricacion industrial repetible; si el cliente lo requiere, faltan DFM, BOM final, Gerbers y QA de manufactura.
