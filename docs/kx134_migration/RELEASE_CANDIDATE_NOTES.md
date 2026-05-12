# Release candidate KX134

## Release candidate

El proyecto queda como release candidate funcional del prototipo KX134 dual.

## Software

- Ejecutable: `Sistema_Captura_Acelerometria.exe`.
- GUI: KX134 Dual Capture con graficas live.
- Launcher: KX134 actual y ADXL335 legacy.
- Exportacion: CSV KX134 v3, session JSON y summary MD.

## Hardware

- Sensor 1 KX134 con ESP32 sensora.
- Sensor 2 KX134 con ESP32 sensora.
- ESP32 receptora conectada al PC por USB.
- Baquelada RevA funcional para los nodos sensores, repetida para Sensor 1 y
  Sensor 2.

## Configuracion validada

- 100 Hz.
- ODR 100 Hz.
- 8 g.
- 921600 baud.
- ESP-NOW channel 1.

## Advertencias no bloqueantes

- Sensor 1 tuvo 2 `seq_gaps` en la sesion controlada de 60 s.
- Icono corporativo pendiente.
- Firma digital pendiente.
- Scaling 125/150 pendiente.
- GUI todavia no envia `sample_rate_hz` al firmware.

## Fuera de alcance del release candidate

- Produccion industrial repetible.
- DFM formal.
- BOM final.
- Gerbers finales.
- QA de manufactura.
- Fixture de prueba de produccion.

## Criterio para producto comercial

Para convertir este release candidate en producto comercial se recomienda crear
un paquete de manufactura separado con DFM, BOM, Gerbers, pruebas de produccion,
revision mecanica y QA de lote.
