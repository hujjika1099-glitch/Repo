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
| 2026-03-20 | Fase 5 Upload y Monitor Single Node | `firmware/single_node_calibration/platformio.ini`, `reports/single_node_upload_and_monitor.md` | alta/modificacion | Ejecutar validacion operativa de upload/monitor en COM5 sin tocar remoto | Puerto y monitor verificados; upload bloqueado por boot mode `0x13`, requiere intervencion manual BOOT/EN para aplicar baseline | medio |
| 2026-03-20 | Fase 5.1 Guided Bootloader Upload | `firmware/single_node_calibration/platformio.ini`, `reports/single_node_bootloader_guided_upload.md` | alta/modificacion | Reintentar upload con secuencia manual BOOT/EN (maximo 2 intentos) y validar stream final | Intento 2 exitoso; baseline CSV confirmado en monitor serie; estado `ready_for_matlab` | medio |
| 2026-03-20 | Fase 6 MATLAB Capture Single Sensor | `matlab/calibration/capture_single_sensor_baseline.m`, `.vscode/tasks.json`, `data/raw/sensor_A/sensor_A_z_plus_static_20260320_132709.csv`, `data/raw/sensor_A/sensor_A_z_plus_static_20260320_132709_session.txt`, `reports/single_node_matlab_capture_baseline.md` | alta/modificacion | Implementar y validar primera captura MATLAB funcional individual para `sensor_A` en COM5 | Captura real guardada sin sobrescritura, formato validado, frecuencia estimada ~100 Hz, estado `matlab_capture_ok` | medio |
| 2026-03-20 | Fase 7 Analisis Basico y Repetibilidad Misma Pose | `matlab/analysis/analyze_single_capture_baseline.m`, `matlab/analysis/analyze_repeatability_same_pose.m`, `.vscode/tasks.json`, `reports/analysis_outputs/*`, `reports/sensor_A_single_capture_analysis.md`, `reports/repeatability_next_step_plan.md` | alta/modificacion | Crear flujo reproducible de analisis individual y preparar comparacion de repetibilidad para `sensor_A` en `z_plus_static` sin iniciar multipose | Analisis individual ejecutado con metricas/figuras; preparacion de repetibilidad lista con `runs_found=1` y plan operativo para 2-3 corridas adicionales | medio |
