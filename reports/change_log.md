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
