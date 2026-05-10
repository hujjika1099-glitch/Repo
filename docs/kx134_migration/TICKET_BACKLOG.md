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
- TICKET 016: COMPLETADO - Validacion GUI KX134 con hardware real y exportacion de sesion.
- TICKET 017: COMPLETADO - Endurecer exportacion KX134, metadata y validadores de sesion.
- TICKET 018: COMPLETADO - Rediseno visual profesional y responsive de GUI KX134/ADXL sin empaquetar.
- TICKET 019: COMPLETADO - Graficas en vivo KX134 para retroalimentacion durante captura.
- TICKET 020: COMPLETADO - Empaquetado Windows profesional KX134/ADXL con DPI awareness y validacion del ejecutable.

## Tickets en curso o pendientes

- TICKET 021: PENDIENTE - QA externo del ejecutable en otro PC. Smoke del exe paso en `MOMOTTO_PC` a `1920x1080` y scaling `100%`; falta validacion visual/manual completa, scaling 125/150% y captura/exportacion hardware externa si el hardware esta disponible.

## Tickets futuros recomendados

- TICKET 022: Validacion de prototipo con sesion controlada y criterios para entrega/baquelada.
- TICKET 023: Criterios para baquelada/PCB.
- FUTURO: Icono corporativo y firma digital si se requiere.
- FUTURO: Envio de configuracion `sample_rate_hz` al firmware si se decide implementarlo.

## Dependencias de trabajo

- TICKET 013 debe conservar dos ESP32 sensoras y una ESP32 receptora.
- TICKET 014 valido timestamps, campos de identidad y filtro acotado de duplicados en receptor.
- TICKET 015 agrego parser/core/GUI KX134 separado y replay con log real.
- TICKET 016 valido captura/exportacion GUI KX134 con hardware real; detecto necesidad de warmup serial al abrir COM4 y `pc_wall_s` de alta resolucion.
- TICKET 017 endurecio metadata, summary y validador de bundle KX134; los bundles previos pueden quedar como metadata legacy.
- TICKET 018 agrego launcher, tema compartido, componentes responsive y smoke visual sin hardware.
- TICKET 019 agrego graficas live KX134 con Canvas, eventos de progreso del core, buffer visual por sensor y validacion manual satisfactoria con hardware.
- TICKET 020 preparo PyInstaller onedir con launcher frozen-aware, manifest DPI, smoke del exe y validador de paquete; `dist/`, `build_work/`, `.venv`, `.exe` y `.zip` quedan como artefactos locales no commiteados.
- TICKET 021 agrega checklist, script PowerShell y validador Python para QA externo; la decision se mantiene `PENDING` hasta cerrar validacion visual/manual y hardware externo segun disponibilidad.

## Regla de alcance

Este backlog enumera trabajo futuro. Ninguno de los tickets futuros queda implementado
por la validacion dual de TICKET 013.
