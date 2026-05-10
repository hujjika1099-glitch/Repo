# Windows packaging KX134/ADXL

## Producto

- Nombre: Sistema de Captura de Acelerometria.
- Ejecutable: `Sistema_Captura_Acelerometria.exe`.
- Entry point: `gui/app_launcher.py`.
- Modo de paquete: PyInstaller onedir.

## Launcher

El ejecutable inicia en `--mode launcher` por defecto. Desde el launcher se puede abrir:

- `--mode kx134`: KX134 Dual Capture.
- `--mode adxl`: ADXL335 historico.

En modo frozen, los botones relanzan el mismo `.exe` con `--mode kx134` o `--mode adxl`; en desarrollo usan `python -m gui.app_launcher --mode ...`.

## DPI awareness

El paquete incluye `packaging/windows/dpi_aware.manifest` con `asInvoker` y DPI awareness PerMonitor/PerMonitorV2. La GUI tambien conserva el best effort por `ctypes`.

## Archivos incluidos

El spec incluye los modulos `gui/`, `pyserial` y las configuraciones KX134 necesarias:

- `config/kx134_node_map.json`
- `config/kx134_transport_contract_v3.json`
- `config/calibrations/kx134_sensor_1.json`
- `config/calibrations/kx134_sensor_2.json`

## Lo que no se empaqueta

- `data/` historica.
- `reports/kx134_gui_validation/`.
- `reports/kx134_test_runs/`.
- `dist/`.
- `build_work/`.
- `.venv/`.

## Build

```powershell
powershell -ExecutionPolicy Bypass -File .\build_windows_app.ps1 -CreateVenv -RunSmoke
```

## Validacion

```powershell
python tools\kx134\validate_windows_package.py `
  --dist-dir dist\Sistema_Captura_Acelerometria `
  --exe dist\Sistema_Captura_Acelerometria\Sistema_Captura_Acelerometria.exe `
  --zip dist\Sistema_Captura_Acelerometria_dist.zip `
  --output reports\kx134_gui_validation\TICKET_020_windows_package_validation_output.json
```

## Pendientes

- QA en otro PC.
- Revision de resolucion 1366x768 y scaling 125/150%.
- Icono corporativo.
- Firma digital.
- Envio de configuracion `sample_rate_hz` al firmware si se decide implementarlo.
