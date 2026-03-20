# Change Log del Proyecto

## Proposito
Registro tecnico y trazable de cambios relevantes del repositorio.

## Plantilla de Registro
| Fecha | Fase | Archivo o Componente Afectado | Tipo de Cambio | Motivo | Impacto | Riesgo |
|---|---|---|---|---|---|---|
| AAAA-MM-DD | Fase X | ruta/archivo | alta/modificacion/correccion | razon del cambio | resultado esperado | bajo/medio/alto |

## Registros
| Fecha | Fase | Archivo o Componente Afectado | Tipo de Cambio | Motivo | Impacto | Riesgo |
|---|---|---|---|---|---|---|
| 2026-03-20 | Fase 1 Bootstrap Local | Estructura de carpetas, `README.md`, `.gitignore`, `AGENTS.md`, `.codex/`, `.vscode/`, `hardware/`, `reports/`, `data/`, `prompts/` | alta/modificacion | Establecer base profesional local con trazabilidad y reglas operativas sin tocar remoto ni toolchain de firmware | Repo preparado para fases tecnicas siguientes con control documental y de datos | bajo |
| 2026-03-20 | Fase 1 Bootstrap Local | `.vscode/tasks.json` | diferido | Toolchain incompleto (`pio/platformio` no disponible en PATH) y se evita configurar tareas prematuras o ficticias | Se pospone definicion de tareas funcionales a fase posterior de toolchain | bajo |
| 2026-03-20 | Fase 3 Toolchain Local Firmware | Diagnostico de PlatformIO en terminal integrada, `.vscode/tasks.json`, `firmware/single_node_calibration/platformio.ini`, `firmware/single_node_calibration/src/main.cpp`, `reports/toolchain_status.md`, `README.md` | alta/modificacion | Habilitar flujo local real de firmware con ejecutable verificado sin tocar remoto ni instalar dependencias nuevas | VS Code queda con tareas operativas para build/upload/monitor/clean sobre scaffolding minimo de firmware | medio |
| 2026-03-20 | Fase 4 Firmware Baseline ADXL335 | `firmware/single_node_calibration/src/main.cpp`, `reports/single_node_firmware_baseline.md` | alta/modificacion | Implementar adquisicion minima real (ADC raw + mV + seq + t_us) para validacion individual y compilar en entorno local | Baseline funcional listo para carga posterior en ESP32 de referencia; salida serial estable para captura y analisis | medio |
| 2026-03-20 | Fase 4 Firmware Baseline ADXL335 | Entorno local PlatformIO (`~/.platformio/penv`) | correccion | Resolver error de compilacion por dependencia faltante (`intelhex`) detectada en `tool-esptoolpy` | Build recuperado y validado con resultado `SUCCESS` | bajo |
