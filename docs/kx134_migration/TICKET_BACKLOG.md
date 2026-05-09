# Backlog de migracion KX134

## Tickets completados

- TICKET 001: COMPLETADO - Crear rama de migracion KX134 y baseline documental.
- TICKET 002: COMPLETADO - Auditoria tecnica del repositorio actual antes de migracion KX134/SEN-17589.
- TICKET 003: COMPLETADO - Contrato de datos KX134 v3.
- TICKET 004: COMPLETADO - Cerrar arquitectura fisica KX134 con tres ESP32.
- TICKET 005: COMPLETADO - Ajustar ODR KX134 a 100, 200, 400 y 800 Hz.
- TICKET 006: COMPLETADO - Firmware minimo KX134 para una ESP32 sensora por I2C/Qwiic.
- TICKET 007: COMPLETADO - Cableado KX134 I2C y helpers PlatformIO Windows.
- TICKET 008: COMPLETADO - Prueba fisica de KX134 Sensor 1, upload y captura Serial.
- TICKET 009: COMPLETADO - Calibracion interactiva de seis posiciones para KX134 Sensor 1.
- TICKET 010: COMPLETADO - Preparar firmware y prueba fisica para KX134 Sensor 2.
- TICKET 011: COMPLETADO - Generalizar herramienta y calibrar KX134 Sensor 2.

## Tickets futuros recomendados

- TICKET 012: Firmware dual ESP-NOW KX134: dos nodos sensores hacia receptor.
- TICKET 013: Receptor KX134 ESP-NOW a Serial USB.
- TICKET 014: Sincronizacion y precheck.
- TICKET 015: GUI configurable para KX134.
- TICKET 016: Exportacion CSV/JSON KX134.
- TICKET 017: GUI profesional adaptable.
- TICKET 018: Empaquetado profesional Windows.
- TICKET 019: Validacion de prototipo.
- TICKET 020: Criterios para baquelada/PCB.

## Dependencias de trabajo

- TICKET 012 y TICKET 013 deben conservar dos ESP32 sensoras y una ESP32 receptora.
- TICKET 014 depende de que existan timestamps y campos de identidad suficientes.
- TICKET 018 debe esperar a que la GUI y los nombres finales KX134 esten estabilizados.

## Regla de alcance

Este backlog enumera trabajo futuro. Ninguno de los tickets futuros queda implementado
por la calibracion de Sensor 1 de TICKET 009.
