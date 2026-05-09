# Backlog de migracion KX134

## Tickets completados

- TICKET 001: COMPLETADO - Crear rama de migracion KX134 y baseline documental.
- TICKET 002: COMPLETADO - Auditoria tecnica del repositorio actual antes de migracion KX134/SEN-17589.
- TICKET 003: COMPLETADO - Contrato de datos KX134 v3.
- TICKET 004: COMPLETADO - Cerrar arquitectura fisica KX134 con tres ESP32.
- TICKET 005: COMPLETADO - Ajustar ODR KX134 a 100, 200, 400 y 800 Hz.
- TICKET 006: COMPLETADO - Firmware minimo KX134 para una ESP32 sensora por I2C/Qwiic.
- TICKET 007: COMPLETADO - Cableado KX134 I2C y helpers PlatformIO Windows.

## Tickets futuros recomendados

- TICKET 008: Prueba fisica de un KX134, carga de firmware y captura de salida Serial.
- TICKET 009: Captura de MAC fisica de ESP32 sensora.
- TICKET 010: Firmware para sensor_node_2.
- TICKET 011: Firmware dual ESP-NOW dos ESP32 sensoras.
- TICKET 012: Receptor KX134 ESP-NOW a Serial USB.
- TICKET 013: Sincronizacion y precheck.
- TICKET 014: Calibracion individual.
- TICKET 015: GUI - duracion manual y frecuencia de muestreo seleccionable.
- TICKET 016: Exportacion CSV/JSON KX134.
- TICKET 017: GUI - redisenio adaptable/profesional.
- TICKET 018: Empaquetado profesional Windows.
- TICKET 019: Validacion de prototipo.
- TICKET 020: Criterios para baquelada/PCB.

## Dependencias de trabajo

- TICKET 008 debe ejecutarse con hardware real para confirmar inicializacion, lectura y salida serial.
- TICKET 009 debe registrar MAC fisica antes de cerrar mapeo por nodo.
- TICKET 010 debe replicar configuracion para `sensor_id=2` sin cambiar el contrato.
- TICKET 011 y TICKET 012 deben conservar dos ESP32 sensoras y una ESP32 receptora.
- TICKET 013 depende de que existan timestamps y campos de identidad suficientes.
- TICKET 014 debe definir archivos de calibracion individuales antes de pruebas de prototipo.
- TICKET 018 debe esperar a que la GUI y los nombres finales KX134 esten estabilizados.

## Regla de alcance

Este backlog enumera trabajo futuro. Ninguno de los tickets futuros queda implementado
por la documentacion de cableado y helpers PlatformIO de TICKET 007.
