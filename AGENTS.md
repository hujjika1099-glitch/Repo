# AGENTS.md - Guia operativa actual

Este archivo es la referencia para CODEX, Claude u otros agentes que trabajen en
este repositorio. Leerlo antes de proponer cambios.

## Sistema Principal Actual

El sistema principal actual es KX134 dual, no ADXL335.

- Dos sensores SparkFun SEN-17589/KX134.
- Dos ESP32 sensoras.
- Una ESP32 receptora.
- Transporte sensores -> receptor por ESP-NOW.
- Transporte receptor -> PC por Serial USB.
- GUI KX134 con graficas live.
- Ejecutable Windows: `Sistema_Captura_Acelerometria.exe`.
- Exportacion KX134 CSV/JSON/summary con contrato v3.

## Estado De ADXL335

ADXL335 queda como flujo legacy/historico. Se conserva por compatibilidad,
referencia y buenas practicas de trazabilidad, pero no debe presentarse como la
ruta principal del proyecto.

No borrar ni reescribir el flujo ADXL335 sin ticket explicito. Si se documenta,
marcarlo siempre como legacy, historico o preservado.

## Estado Del Proyecto

- Prototipo KX134 funcional listo para entrega tecnica.
- Documentacion de cliente lista.
- Ejecutable Windows preparado.
- QA visual externa aprobada.
- Sesion controlada de prototipo aprobada.
- PCB final no autorizada.
- Baquelada RevA registrada y en estado `under_review`.
- Baquelada RevA no aceptada aun para uso de prototipo.

## Reglas Para Agentes

- No modificar firmware sin ticket explicito.
- No modificar calibraciones sin ticket explicito.
- No modificar GUI funcional salvo alcance autorizado.
- No modificar empaquetado funcional salvo alcance autorizado.
- No autorizar PCB ni baquelada final.
- No tocar `dist/`, `build_work/`, `.venv/`, `.exe` ni `.zip`.
- No tocar data runtime ni CSV historicos.
- Registrar cambios relevantes en `reports/change_log.md`.
- Mantener README, backlog, node_map y reportes sincronizados.
- ADXL335 debe permanecer preservado como legacy.
- No introducir campos de milivoltios ni `g_norm` como columna del CSV KX134.

## Rutas Principales

```text
firmware/kx134_dual_espnow/          # Firmware actual KX134 dual
firmware/kx134_single_node_i2c/      # Bring-up/calibracion KX134
firmware/kx134_receiver_identity/    # Identidad MAC del receptor
gui/app_launcher.py                  # Launcher actual
gui/kx134_live_gui.py                # GUI KX134 actual
gui/adxl_live_gui.py                 # GUI ADXL335 legacy
config/kx134_node_map.json           # Fuente documental de nodos/estado
config/calibrations/                 # Calibraciones KX134 por sensor
docs/kx134_migration/client/         # Documentacion de usuario/cliente
hardware/pcb/baquelada_revA/         # Artefactos RevA bajo revision
build_windows_app.ps1                # Build Windows actual
sistema_captura_acelerometria.spec   # Spec PyInstaller actual
```

## Comandos Importantes

Estado inicial:

```powershell
git status --short --branch
git branch --show-current
```

Pruebas Python:

```powershell
python -m unittest discover -s tests -p "test_kx134*.py"
python -m unittest discover -s tests -p "test_app_launcher*.py"
```

Compilacion rapida de GUI:

```powershell
python -m py_compile gui\kx134_live_gui.py gui\app_launcher.py gui\adxl_live_gui.py
```

Build Windows actual:

```powershell
powershell -ExecutionPolicy Bypass -File .\build_windows_app.ps1 -RunSmoke
```

PlatformIO KX134:

```powershell
$env:PLATFORMIO_EXE="$env:USERPROFILE\.platformio\penv\Scripts\pio.exe"
& $env:PLATFORMIO_EXE run -d .\firmware\kx134_dual_espnow
```

Validador de readiness documental:

```powershell
python tools\kx134\validate_repository_readiness.py --output reports\repository_health\TICKET_027_repository_readiness_output.json
```

## Prohibiciones

- No borrar el legado ADXL335.
- No declarar PCB autorizada.
- No commitear binarios.
- No generar Gerbers, BOM final ni archivos PCB finales sin ticket especifico.
- No introducir campos `mv_*`, voltajes o `g_norm` como columnas del CSV KX134.
- No modificar MACs, calibraciones, `sample_rate_hz`, `odr_hz` o `range_g` sin
  validacion explicita.

## Higiene De Git

Antes de commitear, verificar:

```powershell
git diff --name-only | rg "^firmware/"
git diff --name-only | rg "^gui/"
git diff --name-only | rg "config/calibrations|reports/kx134_calibration"
git diff --name-only | rg "^data/"
git status --short --untracked-files=all
git diff --check
```

Los resultados esperados para firmware, GUI, calibraciones y data dependen del
ticket; en tickets documentales deben quedar sin cambios.
