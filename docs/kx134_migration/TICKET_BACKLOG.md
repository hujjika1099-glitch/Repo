# Backlog de migracion KX134

## Tickets completados

- TICKET 001: COMPLETADO - Crear rama de migracion KX134 y baseline documental.
- TICKET 002: COMPLETADO - Auditoria tecnica del repositorio actual antes de migracion KX134/SEN-17589.
- TICKET 003: COMPLETADO - Contrato de datos KX134 v3.
- TICKET 004: COMPLETADO - Cerrar arquitectura fisica KX134 con tres ESP32.
- TICKET 005: COMPLETADO - Ajustar ODR KX134 a 100, 200, 400 y 800 Hz.
- TICKET 006: COMPLETADO - Firmware minimo KX134 para una ESP32 sensora por I2C/Qwiic.

## Tickets futuros recomendados

- TICKET 007: Prueba fisica de un KX134 y captura de MAC de ESP32 sensora.
- TICKET 008: Firmware para sensor_node_2.
- TICKET 009: Firmware dual ESP-NOW dos ESP32 sensoras.
- TICKET 010: Receptor KX134 ESP-NOW a Serial USB.
- TICKET 011: Sincronizacion y precheck.
- TICKET 012: Calibracion individual.
- TICKET 013: GUI - duracion manual y frecuencia de muestreo seleccionable.
- TICKET 014: Exportacion CSV/JSON KX134.
- TICKET 015: GUI - redisenio adaptable/profesional.
- TICKET 016: Empaquetado profesional Windows.
- TICKET 017: Validacion de prototipo.
- TICKET 018: Criterios para baquelada/PCB.

## Dependencias de trabajo

- TICKET 007 debe ejecutarse con hardware real para confirmar inicializacion, lectura y MAC de una ESP32 sensora.
- TICKET 008 debe replicar configuracion para `sensor_id=2` sin cambiar el contrato.
- TICKET 009 y TICKET 010 deben conservar dos ESP32 sensoras y una ESP32 receptora.
- TICKET 011 depende de que existan timestamps y campos de identidad suficientes.
- TICKET 012 debe definir archivos de calibracion individuales antes de pruebas de prototipo.
- TICKET 016 debe esperar a que la GUI y los nombres finales KX134 esten estabilizados.

## Regla de alcance

Este backlog enumera trabajo futuro. Ninguno de los tickets futuros queda implementado
por el firmware minimo single-node creado en TICKET 006.
