# Manifiesto de entrega del prototipo KX134 dual

## Software

- ZIP del ejecutable: `Sistema_Captura_Acelerometria_dist.zip`.
- Carpeta onedir descomprimida: `Sistema_Captura_Acelerometria`.
- Ejecutable: `Sistema_Captura_Acelerometria.exe`.
- Documentacion cliente en `docs/kx134_migration/client/`.

## Hardware

- Sensor 1 KX134 + ESP32 sensora.
- Sensor 2 KX134 + ESP32 sensora.
- Receptor ESP32.
- Cables USB y alimentacion necesarios.
- Etiquetas fisicas Sensor 1, Sensor 2 y Receptor.

## Archivos importantes del repositorio

- `config/kx134_node_map.json`.
- `config/kx134_transport_contract_v3.json`.
- `config/calibrations/kx134_sensor_1.json`.
- `config/calibrations/kx134_sensor_2.json`.
- Reportes de validacion KX134.

## No incluir en git como entrega versionada

- `dist/`.
- `build_work/`.
- `.venv/`.
- `.exe`.
- `.zip`.
- Datos runtime historicos.

## Entrega fisica al cliente

- Sensor 1.
- Sensor 2.
- Receptor.
- Cables.
- Indicacion de puerto COM cuando se conecte.
- Nota de que la baquelada RevA funcional esta aceptada para uso de prototipo.

## Entrega digital al cliente

- ZIP del ejecutable.
- Guia rapida.
- Manual de usuario.
- Guia de instalacion Windows.
- Guia de conexion hardware.
- Guia de captura/exportacion.
- Referencia de archivos.
- Troubleshooting.
- Release notes.
- Checklists.
- Limitaciones y advertencias.

## Checklist de entrega

- [ ] ZIP copiado.
- [ ] Ejecutable abre.
- [ ] KX134 abre.
- [ ] ADXL335 historico abre si se requiere.
- [ ] Sensor 1 etiquetado.
- [ ] Sensor 2 etiquetado.
- [ ] Receptor etiquetado.
- [ ] Documentacion incluida.
- [ ] Cliente informado de `100 Hz`, `8 g`, `921600`.
- [x] Cliente informado de que RevA es funcional para prototipo y que produccion repetible requiere DFM/BOM/Gerbers/QA.
- [ ] Cliente informado de que si cambia `range_g` debe recalibrar.

## Cierre Final TICKET 028

- `PROJECT_FUNCTIONAL_COMPLETE = YES`
- `PROTOTYPE_RELEASE_CANDIDATE_READY = YES`
- `BAQUELADA_REVA_FUNCTIONAL_VALIDATED_BY_EXPERT = YES`
- `BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = YES`
- `PRODUCTION_MANUFACTURING_PACKAGE_READY = NO`

La baquelada RevA fue completada fisicamente y validada como funcional por el experto del proyecto. Queda aceptada para uso de prototipo KX134 Sensor 1/Sensor 2. Esto no constituye paquete de fabricacion industrial repetible; si el cliente lo requiere, faltan DFM, BOM final, Gerbers y QA de manufactura.
