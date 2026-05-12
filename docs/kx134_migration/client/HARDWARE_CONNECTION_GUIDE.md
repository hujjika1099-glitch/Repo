# Guia de conexion hardware KX134

## Arquitectura de conexion

- Sensor 1: KX134 + ESP32 sensora.
- Sensor 2: KX134 + ESP32 sensora.
- Receptor: ESP32 receptora conectada al PC por USB.
- Comunicacion Sensor 1/Sensor 2 hacia Receptor: ESP-NOW.
- Comunicacion Receptor hacia PC: USB Serial a `921600`.

## Reglas operativas

- No intercambiar Sensor 1 y Sensor 2.
- Mantener etiquetas fisicas visibles.
- Conectar el Receptor al PC por USB antes de capturar.
- Alimentar Sensor 1 y Sensor 2 antes de iniciar captura.
- Evitar cables flojos durante pruebas dinamicas.

## Identidad de nodos

| Nodo | MAC | Estado |
|---|---|---|
| Sensor 1 | `D4:E9:F4:E9:8E:1C` | validado |
| Sensor 2 | `D4:E9:F4:C3:37:14` | validado |
| Receptor | `00:4B:12:96:9A:80` | validado |

## Configuracion validada

- ESP-NOW channel: 1.
- Serial: `921600`.
- Frecuencia: `100 Hz`.
- `range_g`: `8 g`.
- `odr_hz`: 100.

## Advertencias

- Si cambia un KX134 fisico, recalibrar.
- Si cambia una ESP32, actualizar `config/kx134_node_map.json`.
- Si cambia `range_g`, recalibrar.
- Si cambia frecuencia, revalidar firmware, GUI y exportacion.
- La PCB no autorizada no debe iniciarse hasta cerrar alimentacion, conectores, longitudes, montaje, orientacion de ejes y ubicacion fisica de nodos.

## PCB

Este documento no es un diagrama electrico final de PCB. La baquelada sigue pendiente de decisiones fisicas/mecanicas.

## Cierre Final TICKET 028

- `PROJECT_FUNCTIONAL_COMPLETE = YES`
- `PROTOTYPE_RELEASE_CANDIDATE_READY = YES`
- `BAQUELADA_REVA_FUNCTIONAL_VALIDATED_BY_EXPERT = YES`
- `BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = YES`
- `PRODUCTION_MANUFACTURING_PACKAGE_READY = NO`

La baquelada RevA fue completada fisicamente y validada como funcional por el experto del proyecto. Queda aceptada para uso de prototipo KX134 Sensor 1/Sensor 2. Esto no constituye paquete de fabricacion industrial repetible; si el cliente lo requiere, faltan DFM, BOM final, Gerbers y QA de manufactura.
