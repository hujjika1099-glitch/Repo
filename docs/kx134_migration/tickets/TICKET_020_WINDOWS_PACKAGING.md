# TICKET 020 - Windows packaging

## Objetivo

Preparar y validar el empaquetado Windows profesional del sistema KX134/ADXL con launcher principal, DPI awareness y smoke del ejecutable.

## Alcance

- Nuevo spec PyInstaller: `sistema_captura_acelerometria.spec`.
- Nuevo script: `build_windows_app.ps1`.
- Manifest DPI-aware.
- Launcher compatible con PyInstaller/frozen mediante `--mode`.
- Validador de paquete.
- Documentacion y reporte de validacion.

## Restricciones

- No modificar firmware.
- No modificar calibraciones.
- No modificar data historica.
- No commitear `dist/`, `build_work/`, `.venv/`, `.exe` ni `.zip`.
- No borrar ni mover artefactos locales de captura.

## Procedimiento

```powershell
python -m py_compile gui\app_launcher.py gui\kx134_live_gui.py gui\adxl_live_gui.py
python -m unittest discover -s tests -p "test_app_launcher*.py"
powershell -ExecutionPolicy Bypass -File .\build_windows_app.ps1 -CreateVenv -RunSmoke
python tools\kx134\validate_windows_package.py --dist-dir dist\Sistema_Captura_Acelerometria --exe dist\Sistema_Captura_Acelerometria\Sistema_Captura_Acelerometria.exe --zip dist\Sistema_Captura_Acelerometria_dist.zip --output reports\kx134_gui_validation\TICKET_020_windows_package_validation_output.json
```

## Criterios de aceptacion

- Build local exitoso.
- Smoke launcher exitoso.
- Smoke KX134 exitoso.
- Validador confirma exe, zip y configs.
- No hay data historica ni reportes de desarrollo dentro del paquete.
- ADXL335 historico abre desde launcher en modo smoke.

## Decision esperada

`READY_FOR_EXTERNAL_PC_QA=YES` si el paquete local queda construido y validado.
