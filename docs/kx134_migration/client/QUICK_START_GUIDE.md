# Guia rapida - Sistema de Captura de Acelerometria KX134

## Que es el sistema

El prototipo KX134 dual captura aceleracion calibrada desde dos sensores SEN-17589/KX134 conectados a dos ESP32 sensoras. Una ESP32 receptora recibe los datos por ESP-NOW y los envia al PC por USB Serial para que la aplicacion Windows genere CSV, JSON y summary.

## Que incluye el prototipo

- Sensor 1 KX134, identificado como `sensor_id=1`.
- Sensor 2 KX134, identificado como `sensor_id=2`.
- Receptor ESP32 conectado al PC por USB.
- Aplicacion Windows `Sistema_Captura_Acelerometria.exe`.
- GUI KX134 con graficas en vivo y exportacion auditable.
- Flujo ADXL335 historico preservado.

## Que no incluye todavia

- Fabricacion industrial repetible; la RevA funcional esta aceptada para prototipo.
- Firma digital del ejecutable.
- Icono corporativo final.
- Configuracion remota de `sample_rate_hz` desde GUI hacia firmware.

## Pasos rapidos

1. Alimente Sensor 1.
2. Alimente Sensor 2.
3. Conecte el Receptor al PC por USB.
4. Abra `Sistema_Captura_Acelerometria.exe`.
5. En el launcher, abra KX134 Dual Capture.
6. Seleccione el puerto COM del Receptor.
7. Confirme baudrate `921600`.
8. Elija la duracion de captura.
9. Use frecuencia esperada `100 Hz` para la configuracion validada.
10. Inicie captura.
11. Observe las graficas en vivo.
12. Al terminar, revise los archivos exportados CSV, JSON y summary.

## Configuracion validada

- Frecuencia validada: `100 Hz`.
- `range_g`: `8 g`.
- Baudrate: `921600`.
- Receptor a PC: USB Serial.
- Sensores a receptor: ESP-NOW.

## Recomendacion de uso

- Inicie con capturas cortas de 10 a 20 segundos.
- Para validacion de prototipo use capturas de 60 segundos.
- Mantenga los sensores quietos al inicio y luego haga movimientos suaves.

## Advertencias

- No intercambie Sensor 1 y Sensor 2 sin actualizar `config/kx134_node_map.json`.
- No cambie `range_g` sin recalibrar.
- Si cambia un sensor fisico o una ESP32, actualice identidad y recalibre.
- La RevA funcional esta aceptada para prototipo; fabricacion repetible requiere paquete adicional si el cliente lo solicita.

## Cierre Final TICKET 028

- `PROJECT_FUNCTIONAL_COMPLETE = YES`
- `PROTOTYPE_RELEASE_CANDIDATE_READY = YES`
- `BAQUELADA_REVA_FUNCTIONAL_VALIDATED_BY_EXPERT = YES`
- `BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = YES`
- `PRODUCTION_MANUFACTURING_PACKAGE_READY = NO`

La baquelada RevA fue completada fisicamente y validada como funcional por el experto del proyecto. Queda aceptada para uso de prototipo KX134 Sensor 1/Sensor 2. Esto no constituye paquete de fabricacion industrial repetible; si el cliente lo requiere, faltan DFM, BOM final, Gerbers y QA de manufactura.
