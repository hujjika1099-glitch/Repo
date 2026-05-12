# Pendientes y riesgos abiertos

## Fabricacion repetible si el cliente la requiere

- Revision DFM formal.
- BOM final.
- Gerbers finales.
- Plan QA de manufactura.
- Fixture/prueba de produccion.

Estos puntos no bloquean el prototipo funcional ni la RevA aceptada para prototipo.

## No bloqueantes para prototipo

- Icono corporativo pendiente.
- Firma digital pendiente.
- Scaling Windows 125/150% pendiente.
- Captura hardware en PC externo no ejecutada.
- `sample_rate_hz` no configurable desde GUI hacia firmware.
- Sensor 1 tuvo 2 `seq_gaps` en la sesion controlada de 60 s.

## Riesgos

- Intercambio fisico accidental de sensores.
- Reemplazo de ESP32 sin actualizar MAC en `node_map`.
- Cambio de `range_g` sin recalibrar.
- Cambio de frecuencia sin revalidar firmware/GUI/exportacion.
- Cables o montaje inadecuado durante pruebas dinamicas.
- Alimentacion inestable.
- Montaje mecanico que cambie la orientacion de ejes sin documentarlo.

## Mitigaciones

- Etiquetas fisicas Sensor 1 / Sensor 2 / Receptor.
- Mantener `config/kx134_node_map.json` como fuente de verdad.
- Recalibrar si cambia sensor, rango o montaje.
- Ejecutar validacion de sesion despues de cambios fisicos.
- Usar la baquelada RevA funcional validada por experto para el prototipo.
- Definir DFM/BOM/Gerbers solo si se busca fabricacion repetible.
- Usar checklist de PCB antes de baquelada.

## Cierre Final TICKET 028

- `PROJECT_FUNCTIONAL_COMPLETE = YES`
- `PROTOTYPE_RELEASE_CANDIDATE_READY = YES`
- `BAQUELADA_REVA_FUNCTIONAL_VALIDATED_BY_EXPERT = YES`
- `BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = YES`
- `PRODUCTION_MANUFACTURING_PACKAGE_READY = NO`

La baquelada RevA fue completada fisicamente y validada como funcional por el experto del proyecto. Queda aceptada para uso de prototipo KX134 Sensor 1/Sensor 2. Esto no constituye paquete de fabricacion industrial repetible; si el cliente lo requiere, faltan DFM, BOM final, Gerbers y QA de manufactura.
