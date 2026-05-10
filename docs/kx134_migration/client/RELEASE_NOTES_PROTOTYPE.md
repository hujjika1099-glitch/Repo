# Release notes - Prototype release KX134 dual

## Estado

El prototipo KX134 dual esta listo para entrega funcional.

- `PROTOTYPE_DELIVERY_PACKAGE_READY = YES`.
- `CLIENT_USER_DOCS_READY = YES` cuando esta documentacion pase validacion.
- `PCB_DESIGN_AUTHORIZED = NO`.

## Incluye

- Firmware dual ESP-NOW KX134.
- Sensor 1 y Sensor 2 calibrados.
- Receptor ESP-NOW a USB Serial.
- GUI KX134 con graficas live.
- Exportacion CSV/JSON/summary endurecida.
- Ejecutable Windows onedir.
- Launcher para KX134 y ADXL335 historico.

## Validaciones completadas

- Calibracion Sensor 1.
- Calibracion Sensor 2.
- Dual ESP-NOW.
- Sync precheck.
- GUI hardware capture.
- Export hardening.
- Live plots.
- Packaging Windows.
- QA visual externa.
- Sesion controlada de prototipo.

## Configuracion validada

- `sample_rate_hz`: `100 Hz`.
- `odr_hz`: 100.
- `range_g`: `8 g`.
- Baudrate: `921600`.
- ESP-NOW channel: 1.

## Advertencias

- Sensor 1 tuvo 2 `seq_gaps` en la sesion controlada de 60 s; advertencia no bloqueante.
- PCB no autorizada hasta cerrar decisiones fisicas/mecanicas.
- Icono corporativo pendiente.
- Firma digital pendiente.
- Scaling Windows 125/150 pendiente.
- `sample_rate_hz` desde GUI a firmware pendiente.
- Hardware externo con captura queda pendiente si el cliente lo exige.

## Compatibilidad

El flujo ADXL335 historico se conserva. La documentacion de este paquete se enfoca en KX134.
