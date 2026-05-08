# Backlog de migracion KX134

## Tickets completados

- TICKET 001: COMPLETADO - Crear rama de migracion KX134 y baseline documental.
- TICKET 002: COMPLETADO - Auditoria tecnica del repositorio actual antes de migracion KX134/SEN-17589.
- TICKET 003: COMPLETADO - Contrato de datos KX134 v3.

## Tickets futuros recomendados

- TICKET 004: Confirmacion de arquitectura fisica y seleccion de interfaz KX134.
- TICKET 005: Firmware KX134 de un nodo sensor.
- TICKET 006: Firmware dual dos ESP32 + receptor.
- TICKET 007: Sincronizacion y precheck.
- TICKET 008: Calibracion individual.
- TICKET 009: GUI - duracion manual y frecuencia de muestreo seleccionable.
- TICKET 010: Exportacion CSV/JSON KX134.
- TICKET 011: GUI - redisenio adaptable/profesional.
- TICKET 012: Empaquetado profesional Windows.
- TICKET 013: Validacion de prototipo.
- TICKET 014: Criterios para baquelada/PCB.

## Dependencias de trabajo

- TICKET 004 debe cerrar la topologia fisica antes de modificar firmware.
- TICKET 005 y TICKET 006 dependen de confirmar si habra dos o tres ESP32 totales.
- TICKET 007 depende de que existan timestamps y campos de identidad suficientes.
- TICKET 008 debe definir archivos de calibracion individuales antes de pruebas de prototipo.
- TICKET 012 debe esperar a que la GUI y los nombres finales KX134 esten estabilizados.

## Regla de alcance

Este backlog enumera trabajo futuro. Ninguno de los tickets futuros queda implementado
por la definicion documental del contrato en TICKET 003.
