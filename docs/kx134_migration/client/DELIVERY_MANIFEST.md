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
- Nota de que la PCB no autorizada sigue pendiente.

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
- [ ] Cliente informado de que `PCB_DESIGN_AUTHORIZED = NO`.
- [ ] Cliente informado de que si cambia `range_g` debe recalibrar.
