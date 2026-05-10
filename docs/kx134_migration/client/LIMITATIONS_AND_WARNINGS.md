# Limitaciones y advertencias

## Estado del prototipo

El sistema es un prototipo funcional KX134 dual. No es PCB final.

- `PROTOTYPE_DELIVERY_PACKAGE_READY = YES`.
- `PCB_DESIGN_AUTHORIZED = NO`.
- PCB no autorizada hasta cerrar decisiones fisicas y mecanicas.

## Configuracion validada

- Validado a `100 Hz`.
- Validado a `8 g`.
- Validado a `921600` baudios.
- ESP-NOW channel 1.

## Cambios que obligan recalibracion o revalidacion

- Si cambia `range_g`, recalibrar.
- Si cambia el sensor KX134 fisico, recalibrar.
- Si cambia la ESP32 sensora, actualizar `node_map` y validar.
- Si cambia frecuencia, revalidar firmware, GUI y exportacion.

## Pendientes no bloqueantes para prototipo

- La GUI no configura `sample_rate_hz` remotamente en firmware.
- Icono corporativo pendiente.
- Firma digital pendiente.
- Scaling Windows 125/150 pendiente.
- Hardware externo con captura no se probo en otro PC; si el cliente lo exige, ejecutar QA adicional.

## Advertencias tecnicas

- Sensor 1 tuvo 2 `seq_gaps` en la sesion controlada de 60 s; fue advertencia no bloqueante.
- No se hace analisis profundo de vibracion.
- Los datos crudos se conservan en CSV.
- `|g|` es visual, no columna CSV final.
- No deben aparecer `mv_*`, voltajes, `gx_est/gy_est/gz_est` ni `g_norm` como columnas KX134.
