# Criterios para pasar a baquelada/PCB

## Estado minimo antes de PCB

Para avanzar a baquelada/PCB deben cumplirse:

1. Ambos sensores calibrados.
2. Ambos sensores validados en firmware single-node.
3. ESP-NOW dual validado.
4. Sincronizacion/precheck dual validado.
5. GUI KX134 validada con hardware.
6. Exportacion KX134 endurecida.
7. Graficas live validadas.
8. Ejecutable Windows generado y probado.
9. QA visual externa aprobada.
10. Sesion controlada de prototipo aprobada.

## Decisiones electricas pendientes antes de PCB

- Tipo de alimentacion final.
- Conectores para sensores.
- Longitud de cables.
- Ubicacion fisica de ESP32 receptor.
- Ubicacion fisica de ESP32 sensoras.
- Metodo de fijacion mecanica.
- Acceso a USB/programacion.
- Botones EN/BOOT si son necesarios.
- Proteccion mecanica de cables.
- Proteccion contra inversion de polaridad si aplica.
- Etiquetado fisico Sensor 1 / Sensor 2 / Receptor.
- Orientacion fisica de ejes.
- Montaje que permita repetir calibracion si se reemplaza sensor.

## Reglas de diseno

- No compartir calibracion entre sensores.
- No intercambiar ESP32 sensoras sin actualizar `node_map`.
- No intercambiar sensores fisicos sin recalibrar.
- Mantener `sensor_id` fisico visible.
- Mantener GND comun donde aplique.
- Mantener conexion I2C/Qwiic corta y firme.
- Evitar cables flojos para pruebas de vibracion.
- Documentar orientacion de ejes en la carcasa/PCB.
- Dejar acceso a actualizacion de firmware.
- Dejar posibilidad de reemplazar sensor si falla.
- Evitar depender de conexiones temporales tipo protoboard para entrega final.

## Criterios para aprobar PCB

`READY_FOR_PCB_DESIGN = YES` solo si:

- Existe revision DFM formal.
- Existe BOM final.
- Existen Gerbers finales.
- Existe plan QA de manufactura.
- Existe prueba de produccion/fixture.
- Cliente solicita fabricacion repetible.


- La configuracion 100 Hz / 8 g se conserva salvo nueva validacion.

## Advertencias

- Si se cambia `range_g`, repetir calibracion.
- Si se cambia frecuencia, repetir validacion.
- Si se reemplaza sensor o ESP32, actualizar `node_map` y calibracion.
- Si se requiere 200/400/800 Hz, validar firmware, GUI y exportacion antes de PCB.
- El envio de `sample_rate_hz` desde GUI al firmware sigue pendiente.

## Cierre Final TICKET 028

- `PROJECT_FUNCTIONAL_COMPLETE = YES`
- `PROTOTYPE_RELEASE_CANDIDATE_READY = YES`
- `BAQUELADA_REVA_FUNCTIONAL_VALIDATED_BY_EXPERT = YES`
- `BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = YES`
- `PRODUCTION_MANUFACTURING_PACKAGE_READY = NO`

La baquelada RevA fue completada fisicamente y validada como funcional por el experto del proyecto. Queda aceptada para uso de prototipo KX134 Sensor 1/Sensor 2. Esto no constituye paquete de fabricacion industrial repetible; si el cliente lo requiere, faltan DFM, BOM final, Gerbers y QA de manufactura.
