# Migracion Operativa Live a GUI Python

Fecha: 2026-04-12

## Objetivo
Retirar MATLAB de la ruta operativa live del repositorio y reemplazarlo por una GUI desktop que permita:
- autodeteccion o seleccion manual de puerto serial;
- precheck dual de integridad antes de la corrida principal;
- visualizacion en tiempo real de `|g|` y ejes `mV`;
- guardado de evidencia y derivados sin tocar `data/raw/`.

## Decision adoptada
- La sesion live oficial deja de ejecutarse en MATLAB.
- La nueva ruta operativa usa `Python + tkinter + pyserial`.
- Se conserva el contrato serial del firmware:
  - `seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z`
  - `sensor_id,seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z`
- La GUI genera:
  - `data/raw/sensor_B_live/*_raw.csv`
  - `data/processed/*_processed.csv`
  - `data/processed/*_session.json`
  - `reports/analysis_outputs/*_precheck.txt`
  - `reports/analysis_outputs/*_summary.txt`

## Archivos introducidos o actualizados
- `gui/adxl_live_core.py`
- `gui/adxl_live_gui.py`
- `requirements-gui.txt`
- `scripts/install_gui_requirements.ps1`
- `scripts/run_sensorB_live_session.ps1`
- `live_session_hub/sensorB_live_gui_session.ps1`
- `README.md`
- `AGENTS.md`
- `.vscode/tasks.json`

## Flujo operativo vigente
1. Preparar dependencias una sola vez:
   - `.\scripts\install_gui_requirements.ps1`
2. Abrir launcher interactivo:
   - `.\live_session_hub\sensorB_live_gui_session.ps1`
3. Confirmar puerto y parametros dentro de la GUI.
4. Ejecutar precheck dual.
5. Ejecutar corrida principal observando graficas live.
6. Validar salida en `reports/analysis_outputs/`.

## Alcance cubierto en esta migracion
- Reemplazo de la sesion live MATLAB.
- Conservacion de trazabilidad de evidencia.
- Conservacion del esquema `raw -> processed -> reportes`.
- Reemplazo del `.mat` de sesion por `session.json`.

## Alcance explicitamente no cubierto todavia
- Migracion completa de `matlab/analysis/` a Python.
- Reescritura total de la guia maestra LaTeX.
- Eliminacion del codigo MATLAB historico; queda como referencia tecnica hasta nueva fase.

## Riesgos y criterio de uso
- Si la GUI no puede autodetectar un puerto unico, se debe seleccionar manualmente el COM correcto.
- Si el precheck falla, no se debe maquillar la inconsistencia por software; se repite montaje o se cambia de sensor segun reglas vigentes.
- `sensor_B` sigue siendo la fuente operativa primaria.
