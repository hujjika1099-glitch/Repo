# Backlog de migracion KX134

## Tickets completados

- TICKET 001: COMPLETADO - Crear rama de migracion KX134 y baseline documental.
- TICKET 002: COMPLETADO - Auditoria tecnica del repositorio actual antes de migracion KX134/SEN-17589.

## Tickets futuros recomendados

- TICKET 003: Contrato de datos KX134 v3.
- TICKET 004: Firmware KX134 de un nodo sensor.
- TICKET 005: Firmware dual dos ESP32 + receptor.
- TICKET 006: Sincronizacion y precheck.
- TICKET 007: Calibracion individual.
- TICKET 008: GUI - duracion manual y frecuencia de muestreo seleccionable.
- TICKET 009: Exportacion CSV/JSON KX134.
- TICKET 010: GUI - redisenio adaptable/profesional.
- TICKET 011: Empaquetado profesional Windows.
- TICKET 012: Validacion de prototipo.
- TICKET 013: Criterios para baquelada/PCB.

## Dependencias de trabajo

- TICKET 003 debe cerrar el contrato antes de modificar firmware o GUI.
- TICKET 004 y TICKET 005 dependen de confirmar la topologia fisica de ESP32.
- TICKET 006 depende de que existan timestamps y campos de identidad suficientes.
- TICKET 007 debe definir archivos de calibracion individuales antes de pruebas de prototipo.
- TICKET 011 debe esperar a que la GUI y los nombres finales KX134 esten estabilizados.

## Regla de alcance

Este backlog enumera trabajo futuro. Ninguno de los tickets futuros queda implementado
por la auditoria documental del TICKET 002.
