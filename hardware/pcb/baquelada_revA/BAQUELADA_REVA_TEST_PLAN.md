# Plan de prueba - Baquelada RevA

## Fase 0 - Revision sin energia

- Inspeccion visual.
- Confirmar escala 1:1.
- Confirmar mirror correcto.
- Confirmar separacion real de headers.
- Continuidad con multimetro.
- Shorts entre 3V3/GND/SDA/SCL.
- Confirmar orientacion del ESP32.
- Confirmar orientacion de KX134 o conector.

## Fase 1 - Energia sin sensor

- Alimentar con limitacion de corriente si es posible.
- Verificar 3V3.
- Verificar GND.
- Verificar consumo anomalo.
- Desconectar inmediatamente si hay calentamiento, olor o consumo inesperado.

## Fase 2 - Energia con ESP32

- Verificar que ESP32 arranca.
- Verificar USB/Serial.
- Verificar que se puede cargar firmware si aplica.
- Verificar acceso EN/BOOT.

## Fase 3 - Sensor KX134

- Conectar KX134 solo despues de continuidad y power-on seguro.
- Ejecutar firmware single-node.
- Confirmar I2C 0x1F/0x1E.
- Confirmar stream a 100 Hz.
- Confirmar `x_raw/y_raw/z_raw`.
- Confirmar `x_g/y_g/z_g`.
- Confirmar que no hay reinicios ni calentamiento.

## Fase 4 - Sistema dual

- Repetir para Sensor 1 y Sensor 2 si la baquelada aplica a nodos sensores.
- Validar ESP-NOW.
- Validar receptor.
- Validar GUI KX134.
- Validar exportacion CSV/JSON/summary.

## Criterios

- `BAQUELADA_REVA_FUNCTIONAL_VALIDATED_BY_EXPERT = YES`.
- `BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = YES`.
- `PRODUCTION_MANUFACTURING_PACKAGE_READY = NO`; fabricacion repetible requiere DFM/BOM/Gerbers/QA si se solicita.

## Proximo ticket recomendado

Siguientes pasos opcionales: DFM/BOM/Gerbers/QA si se requiere fabricacion repetible.

## Cierre Final TICKET 028

- `PROJECT_FUNCTIONAL_COMPLETE = YES`
- `PROTOTYPE_RELEASE_CANDIDATE_READY = YES`
- `BAQUELADA_REVA_FUNCTIONAL_VALIDATED_BY_EXPERT = YES`
- `BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = YES`
- `PRODUCTION_MANUFACTURING_PACKAGE_READY = NO`

La baquelada RevA fue completada fisicamente y validada como funcional por el experto del proyecto. Queda aceptada para uso de prototipo KX134 Sensor 1/Sensor 2. Esto no constituye paquete de fabricacion industrial repetible; si el cliente lo requiere, faltan DFM, BOM final, Gerbers y QA de manufactura.
