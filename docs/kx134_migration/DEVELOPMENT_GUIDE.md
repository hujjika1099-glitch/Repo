# Guia De Desarrollo

## Entorno Python

Usar Python local del proyecto o `.venv` si existe. No instalar dependencias
globales ni modificar PATH automaticamente.

```powershell
python -m unittest discover -s tests -p "test_kx134*.py"
python -m unittest discover -s tests -p "test_app_launcher*.py"
python -m py_compile gui\kx134_live_gui.py gui\app_launcher.py gui\adxl_live_gui.py
```

## Firmware

El firmware actual vive en `firmware/kx134_dual_espnow/`. No modificarlo sin un
ticket especifico y evidencia de hardware.

```powershell
$env:PLATFORMIO_EXE="$env:USERPROFILE\.platformio\penv\Scripts\pio.exe"
& $env:PLATFORMIO_EXE run -d .\firmware\kx134_dual_espnow
```

## Empaquetado Windows

El build actual usa:

- `sistema_captura_acelerometria.spec`
- `build_windows_app.ps1`
- `gui/app_launcher.py`

```powershell
powershell -ExecutionPolicy Bypass -File .\build_windows_app.ps1 -RunSmoke
```

`dist/`, `build_work/`, `.exe` y `.zip` no se commitean.

## Validadores

- `tools/kx134/validate_kx134_export_bundle.py`
- `tools/kx134/validate_prototype_session.py`
- `tools/kx134/validate_client_docs.py`
- `tools/kx134/validate_baquelada_reva.py`
- `tools/kx134/validate_repository_readiness.py`

## Reglas De Cambios

- Mantener KX134 separado del legado ADXL335.
- No modificar calibraciones sin ticket.
- No introducir campos ADXL335 en exportacion KX134.
- Actualizar `reports/change_log.md`, backlog y node_map cuando el estado del
  proyecto cambie.
