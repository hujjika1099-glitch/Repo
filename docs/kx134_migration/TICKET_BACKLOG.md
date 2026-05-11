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
- TICKET 021: COMPLETADO - QA externo visual/manual del ejecutable Windows.
- TICKET 022: COMPLETADO - Validacion de prototipo con sesion controlada y criterios para entrega/baquelada.
- TICKET 023: COMPLETADO - Consolidar entrega tecnica del prototipo y documentacion final para cliente.
- TICKET 024: COMPLETADO - Documentacion de usuario/cliente y guia de operacion.
- TICKET 025: COMPLETADO DOCUMENTALMENTE - Definicion fisica para PCB/baquelada; PCB sigue bloqueada por decisiones fisicas pendientes.
- TICKET 026: COMPLETADO - Registrar y auditar baquela/PCB RevA antes de pruebas electricas.
- TICKET 027: COMPLETADO - Limpieza, documentacion profesional y readiness de repositorio KX134; screenshots GUI quedan pendientes como mejora no bloqueante.

## Tickets en curso o pendientes

- Ninguno activo.

## Tickets futuros recomendados

- TICKET 028: Cierre fisico de baquelada RevA por experto y registro de resultados: continuidad, shorts, escala/mirror y power-on sin sensor.
- TICKET 028 opcional: icono corporativo, firma digital y QA visual scaling Windows 125/150.
- FUTURO: Cierre de decisiones fisicas pendientes para PCB o reunion/levantamiento fisico con cliente.
- FUTURO: Especificacion de PCB/baquelada final cuando se cierren decisiones fisicas.
- FUTURO: Icono corporativo y firma digital si se requiere.
- FUTURO: Validacion hardware en PC externo si el cliente lo requiere.
- FUTURO: Probar scaling Windows 125/150%.
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
- TICKET 021 agrega checklist, script PowerShell y validador Python para QA externo; TICKET 021B cierra la validacion visual/manual externa con decision `READY_FOR_CLIENT_PROTOTYPE_QA=YES`. La captura hardware externa no se ejecuto y queda documentada como advertencia no bloqueante porque la captura hardware ya fue validada en el PC de desarrollo.
- TICKET 022 valida una sesion controlada de prototipo de 60 s en `COM4` con Sensor 1 `5998` filas y Sensor 2 `6000` filas. La validacion de prototipo pasa con advertencia por `2` seq gaps en Sensor 1; `READY_FOR_PROTOTYPE_DELIVERY=YES` y `READY_FOR_PCB_DESIGN=NO` por decisiones fisicas pendientes.
- TICKET 023 consolida el paquete documental de entrega del prototipo, corrige la semantica de recomendacion PCB y deja `PROTOTYPE_DELIVERY_PACKAGE_READY=YES` con `PCB_DESIGN_AUTHORIZED=NO`.
- TICKET 024 agrega documentacion cliente para instalacion Windows, conexion hardware, operacion KX134, graficas live, exportacion CSV/JSON/summary, troubleshooting, manifiesto, checklists y limitaciones. La decision queda `CLIENT_USER_DOCS_READY=YES`, manteniendo `PCB_DESIGN_AUTHORIZED=NO`.
- TICKET 025 crea formulario, especificacion fisica preliminar, matriz de decisiones, checklist de riesgos, pre-design review, JSON documental y validador para decisiones fisicas PCB. Como no hay respuestas cerradas para alimentacion, conectores, cableado, montaje, orientacion, ubicacion y ambiente, queda `PCB_PHYSICAL_DECISIONS_COMPLETE=NO` y `PCB_DESIGN_AUTHORIZED=NO`.
- TICKET 026 registra la baquelada RevA creada externamente en Proteus con artefactos `Maestria.PDF` y `Maestria.SVG`, detecta dimensiones SVG `90.49 mm x 44.99 mm`, documenta revision visual `PASS_WITH_WARNINGS`, checklist de continuidad, pinout pendiente y plan de prueba. El usuario confirma que la RevA es para nodos sensores KX134 y se repite para Sensor 1/Sensor 2; el receptor no lleva baquela porque va directo al PC. La RevA queda `under_review`, no aceptada aun para uso de prototipo y `PCB_DESIGN_AUTHORIZED=NO`.
- TICKET 027 profesionaliza README, AGENTS, indices tecnicos, diagramas, mantenimiento, estado del repositorio y validador documental. El sistema principal queda documentado como KX134 dual; ADXL335 queda preservado como legacy. La baquelada RevA sigue bajo responsabilidad experta para pruebas fisicas/electricas posteriores; `PCB_DESIGN_AUTHORIZED=NO`.

## Regla de alcance

Este backlog enumera trabajo futuro. Ninguno de los tickets futuros queda implementado
por la validacion dual de TICKET 013.
