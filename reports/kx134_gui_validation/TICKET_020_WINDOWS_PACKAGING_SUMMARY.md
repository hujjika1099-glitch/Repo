# TICKET 020 - Windows packaging summary

## Fecha

2026-05-10

## Commit base

`ad31208` - `gui: add KX134 live plots during capture`

## Producto

- Nombre: `Sistema de Captura de Acelerometria`.
- Ejecutable: `Sistema_Captura_Acelerometria.exe`.
- Entry point: `gui/app_launcher.py`.
- Modo: PyInstaller onedir.
- Spec: `sistema_captura_acelerometria.spec`.
- Build script: `build_windows_app.ps1`.
- DPI manifest: `packaging/windows/dpi_aware.manifest`.
- Icono: `none`.

## Build local

- Comando: `powershell -ExecutionPolicy Bypass -File .\build_windows_app.ps1 -CreateVenv -RunSmoke`, luego repetido como `.\build_windows_app.ps1 -RunSmoke` tras ajustar reintento de ZIP.
- Resultado: exitoso.
- Exe: `dist\Sistema_Captura_Acelerometria\Sistema_Captura_Acelerometria.exe`.
- ZIP: `dist\Sistema_Captura_Acelerometria_dist.zip`.
- Tamano exe: `2.02 MB`.
- Tamano ZIP: `10.33 MB`.
- Smoke launcher: `pass`.
- Smoke KX134: `pass`.
- Smoke ADXL: `pass` ejecutado manualmente con `--mode adxl --smoke --close-after-ms 1000`.

Primer intento: el ZIP fallo porque `base_library.zip` quedo bloqueado temporalmente despues del smoke. Se agrego espera/reintento en `build_windows_app.ps1` y el segundo build completo correctamente.

## Configs incluidos

- `kx134_node_map.json`.
- `kx134_transport_contract_v3.json`.
- `kx134_sensor_1.json`.
- `kx134_sensor_2.json`.

## Validacion del paquete

- Output: `reports/kx134_gui_validation/TICKET_020_windows_package_validation_output.json`.
- validation_pass: `true`.
- package_exists: `true`.
- exe_exists: `true`.
- zip_exists: `true`.
- configs_present: `true`.
- historical_data_packaged: `false`.
- development_reports_packaged: `false`.
- zip_contains_exe: `true`.

## ADXL335

- ADXL335 historico preservado.
- Cambio aplicado: compatibilidad de import y smoke/close wrapper para poder abrir desde `gui.app_launcher --mode adxl`.
- Parser/exportacion ADXL335: sin cambios funcionales.

## Artefactos generados localmente no commiteados

- `dist/`.
- `build_work/`.
- `.venv/`.
- `.exe`.
- `.zip`.

## Estado de gitignore

Se agregaron exclusiones para caches, artefactos PlatformIO/PyInstaller y salidas runtime KX134 generadas desde repo root:

- `data/raw/kx134_dual_live/`.
- `data/processed/kx134_dual_live/`.
- `reports/analysis_outputs/kx134_dual_live/`.

No se ignoran `reports/kx134_gui_validation/`, `reports/kx134_test_runs/`, `docs/` ni `config/`.

## Node map

- status global: `windows_packaging_prepared_pending_external_pc_qa`.
- last_windows_packaging_report: `reports/kx134_gui_validation/TICKET_020_WINDOWS_PACKAGING_SUMMARY.md`.

## Restricciones

- Firmware no modificado.
- Calibraciones no modificadas.
- Data historica no modificada.
- `dist/` no commiteado.
- `build_work/` no commiteado.
- `.venv/` no commiteado.
- `.exe` y `.zip` no commiteados.

## Pendientes

- QA en otro PC.
- Revisar resolucion 1366x768.
- Revisar scaling Windows 125/150%.
- Icono corporativo.
- Firma digital.
- Envio de configuracion `sample_rate_hz` al firmware si se decide implementarlo.

## Decision

`READY_FOR_EXTERNAL_PC_QA=YES`
