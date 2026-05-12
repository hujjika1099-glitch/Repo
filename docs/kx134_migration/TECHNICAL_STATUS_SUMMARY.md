# Resumen tecnico del sistema KX134 dual

## Hardware

- Sensor 1: SEN-17589/KX134, `sensor_id=1`, MAC ESP32 `D4:E9:F4:E9:8E:1C`.
- Sensor 2: SEN-17589/KX134, `sensor_id=2`, MAC ESP32 `D4:E9:F4:C3:37:14`.
- Receptor: ESP32 receptor, MAC `00:4B:12:96:9A:80`.
- Arquitectura: dos nodos sensores por ESP-NOW hacia receptor USB Serial.
- Configuracion validada: 100 Hz, ODR 100 Hz, rango 8 g.

## Calibraciones

- Sensor 1: `config/calibrations/kx134_sensor_1.json`.
- Sensor 2: `config/calibrations/kx134_sensor_2.json`.
- Regla: no compartir calibracion entre sensores y no intercambiar nodos sin actualizar `config/kx134_node_map.json`.

## Firmware

- Firmware single-node KX134 probado para ambos sensores.
- Firmware dual ESP-NOW creado en `firmware/kx134_dual_espnow/`.
- Receptor Serial USB validado a 921600 baudios.
- Firmware actual: `kx134_dual_espnow.0.1.0`.
- ESP-NOW channel: 1.

## GUI

- Launcher principal: `Sistema de Captura de Acelerometria`.
- Modo KX134: captura dual, graficas en vivo, diagnostico y exportacion.
- Modo ADXL335: flujo historico preservado.
- Exportacion KX134: CSV raw v3, session JSON endurecido y summary MD.
- Graficas live: ejes `x_g/y_g/z_g`, comparacion visual `|g|` y eje seleccionado.

## Empaquetado

- Producto Windows: `Sistema_Captura_Acelerometria.exe`.
- Modo PyInstaller: onedir.
- ZIP local generado en TICKET 020.
- QA visual externa aprobada en TICKET 021B.
- Pendientes: icono corporativo, firma digital y scaling 125/150%.

## Validaciones

- Sensor 1 calibrado: TICKET 009.
- Sensor 2 calibrado: TICKET 011.
- Dual ESP-NOW: TICKET 013.
- Sync precheck: TICKET 014.
- GUI hardware capture: TICKET 016.
- Export hardening: TICKET 017.
- Visual redesign: TICKET 018.
- Live plots: TICKET 019.
- Windows packaging: TICKET 020.
- External visual QA: TICKET 021/021B.
- Prototype controlled session: TICKET 022.

## Estado actual

- Prototipo listo para entrega funcional: si.
- Baquelada RevA funcional validada por experto: si.
- Release candidate tecnico: si.
- Fabricacion industrial repetible: pendiente de DFM/BOM/Gerbers/QA si el cliente la requiere.

## Cierre Final TICKET 028

- `PROJECT_FUNCTIONAL_COMPLETE = YES`
- `PROTOTYPE_RELEASE_CANDIDATE_READY = YES`
- `BAQUELADA_REVA_FUNCTIONAL_VALIDATED_BY_EXPERT = YES`
- `BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = YES`
- `PRODUCTION_MANUFACTURING_PACKAGE_READY = NO`

La baquelada RevA fue completada fisicamente y validada como funcional por el experto del proyecto. Queda aceptada para uso de prototipo KX134 Sensor 1/Sensor 2. Esto no constituye paquete de fabricacion industrial repetible; si el cliente lo requiere, faltan DFM, BOM final, Gerbers y QA de manufactura.
