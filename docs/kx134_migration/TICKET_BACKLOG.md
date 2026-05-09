# Backlog de migracion KX134

## Tickets completados

- TICKET 001: COMPLETADO - Crear rama de migracion KX134 y baseline documental.
- TICKET 002: COMPLETADO - Auditoria tecnica del repositorio actual antes de migracion KX134/SEN-17589.
- TICKET 003: COMPLETADO - Contrato de datos KX134 v3.
- TICKET 004: COMPLETADO - Cerrar arquitectura fisica KX134 con tres ESP32.
- TICKET 005: COMPLETADO - Ajustar ODR KX134 a 100, 200, 400 y 800 Hz.

## Tickets futuros recomendados

- TICKET 006: Firmware KX134 minimo para una ESP32 sensora por I2C/Qwiic.
- TICKET 007: Firmware dual dos ESP32 sensoras + receptor.
- TICKET 008: Sincronizacion y precheck.
- TICKET 009: Calibracion individual.
- TICKET 010: GUI - duracion manual y frecuencia de muestreo seleccionable.
- TICKET 011: Exportacion CSV/JSON KX134.
- TICKET 012: GUI - redisenio adaptable/profesional.
- TICKET 013: Empaquetado profesional Windows.
- TICKET 014: Validacion de prototipo.
- TICKET 015: Criterios para baquelada/PCB.

## Dependencias de trabajo

- TICKET 006 debe partir de la arquitectura cerrada de tres ESP32 y usar I2C/Qwiic como objetivo inicial.
- TICKET 007 debe conservar dos ESP32 sensoras y una ESP32 receptora.
- TICKET 008 depende de que existan timestamps y campos de identidad suficientes.
- TICKET 009 debe definir archivos de calibracion individuales antes de pruebas de prototipo.
- TICKET 013 debe esperar a que la GUI y los nombres finales KX134 esten estabilizados.

## Regla de alcance

Este backlog enumera trabajo futuro. Ninguno de los tickets futuros queda implementado
por el ajuste documental de ODR en TICKET 005.
