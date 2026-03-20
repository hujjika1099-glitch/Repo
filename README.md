# Proyecto de Maestria: Validacion y Calibracion de Sensores ADXL335 con ESP32

## Proposito
Este repositorio concentra el trabajo tecnico de validacion, calibracion y analisis de sensores ADXL335 usando una unica ESP32 de referencia para comparacion individual por sensor.

El objetivo es construir un flujo trazable y reproducible para:
- adquisicion de datos por sensor,
- calibracion por sensor (no por nodo),
- analisis en MATLAB,
- reporte tecnico de resultados y decisiones.

## Alcance Tecnico
- Firmware base para ensayos individuales y comparativos (fase posterior).
- Estructura de datos crudos y procesados con trazabilidad.
- Analisis y apoyo de calibracion en MATLAB (fase posterior).
- Documentacion de hardware, pinout y registro de sensores.
- Gobernanza operativa entre agente Codex y operador humano.

## Estado Actual del Proyecto
- Repositorio Git local ya inicializado y vinculado a `origin/main`.
- Estructura base de trabajo creada para firmware, MATLAB, datos, reportes y prompts.
- Documentacion de control y reglas de ejecucion establecidas.
- Sin implementacion funcional final de firmware ni scripts MATLAB productivos todavia.
- PlatformIO disponible por ruta local verificada (`%USERPROFILE%\\.platformio\\penv\\Scripts\\pio.exe`), aunque no este en PATH global.
- `.vscode/tasks.json` ya incluye tareas reales de build/upload/monitor/clean para `firmware/single_node_calibration`.

## Estructura de Carpetas
```text
.
|-- .codex/
|-- .vscode/
|-- data/
|   |-- raw/
|   |   |-- sensor_A/
|   |   |-- sensor_B/
|   |   `-- sensor_C/
|   `-- processed/
|-- firmware/
|   |-- single_node_calibration/
|   `-- dual_node_espnow/
|-- hardware/
|-- matlab/
|   |-- calibration/
|   `-- analysis/
|-- prompts/
|-- reports/
|-- AGENTS.md
`-- README.md
```

## Flujo de Trabajo por Fases
1. Bootstrap local del repositorio (estructura, reglas, trazabilidad, documentacion).
2. Definicion de toolchain y tareas de entorno (sin alterar remoto por defecto).
3. Implementacion de firmware minimo para adquisicion controlada.
4. Implementacion de scripts MATLAB de calibracion y analisis.
5. Validacion por sensor, emision de reportes y decisiones (`pass`, `suspect`, `fail`).
6. Consolidacion de resultados, hardening y entregables finales.

## Toolchain de Firmware en VS Code
- Estrategia activa: ejecutar PlatformIO por ruta local verificada (sin depender de PATH global).
- Comando base usado por tareas:
  - `${env:USERPROFILE}\\.platformio\\penv\\Scripts\\pio.exe`
- Tareas disponibles:
  - Build Single Calibration
  - Upload Single Calibration
  - Monitor Single Calibration
  - Clean Single Calibration

## Responsabilidades: Codex vs Operador Humano
- Codex:
  - Gestion de estructura del repo, documentacion y automatizaciones locales.
  - Propuesta e implementacion de cambios de software aprobados.
  - Registro tecnico de cambios en `reports/change_log.md`.
- Operador humano:
  - Conexion de hardware, mediciones fisicas y manipulacion de sensores.
  - Autenticaciones y confirmaciones requeridas por el sistema.
  - Validacion de decisiones tecnicas de alto impacto.

## Estrategia de Versionado
- Commits pequenos, trazables y orientados por fase.
- Un cambio relevante debe quedar documentado en `reports/change_log.md`.
- No aplicar cambios irreversibles sin verificacion previa.
- No crear ni recrear remoto por defecto cuando ya existe `origin`.

## Estrategia de Validacion y Calibracion por Sensor
- La unidad de evaluacion es el sensor individual.
- Se utiliza una sola ESP32 de referencia para comparar sensores bajo el mismo entorno.
- Los datos crudos en `data/raw/` se preservan como evidencia (sin sobrescritura).
- Cada analisis debe producir evidencia en `reports/`.
- Criterio de decision por sensor:
  - `pass`: comportamiento consistente y tolerancias aceptables.
  - `suspect`: variabilidad/anomalias que requieren repeticion o revision.
  - `fail`: incoherencia fisica o desviacion fuera de criterios aceptables.

## Nota Sobre el Remoto
`origin` ya existe y se encuentra configurado. Este repositorio no debe recrear remoto por defecto ni modificarlo sin instruccion explicita.
