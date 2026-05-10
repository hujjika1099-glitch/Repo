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
- TICKET 012: COMPLETADO - Capturar MAC de ESP32 receptora KX134 y cerrar node_map.
- TICKET 013: COMPLETADO - Firmware ESP-NOW KX134 dual: dos nodos sensores hacia receptor Serial.
- TICKET 014: COMPLETADO - Precheck de sincronizacion dual KX134 y diagnostico de duplicados.
- TICKET 015: COMPLETADO - Integrar stream Serial KX134 v3 en la GUI/core sin alterar flujo historico ADXL335.

## Tickets futuros recomendados

- TICKET 016: Validacion GUI KX134 con hardware real y exportacion de sesion.
- TICKET 017: GUI profesional adaptable.
- TICKET 018: Empaquetado profesional Windows.
- TICKET 019: Validacion de prototipo.
- TICKET 020: Criterios para baquelada/PCB.

## Dependencias de trabajo

- TICKET 013 debe conservar dos ESP32 sensoras y una ESP32 receptora.
- TICKET 014 valido timestamps, campos de identidad y filtro acotado de duplicados en receptor.
- TICKET 015 agrego parser/core/GUI KX134 separado y replay con log real; la validacion con hardware real desde GUI queda en TICKET 016.
- TICKET 018 debe esperar a que la GUI y los nombres finales KX134 esten estabilizados.

## Regla de alcance

Este backlog enumera trabajo futuro. Ninguno de los tickets futuros queda implementado
por la validacion dual de TICKET 013.
