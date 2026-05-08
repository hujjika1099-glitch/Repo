# Proyecto de Maestria: ADXL335 + ESP32

## 1. Estado actual del proyecto

Operacion real en curso. El sistema captura aceleracion con dos sensores ADXL335
conectados a ESP32s en topologia ESP-NOW inalambrica. La aplicacion de escritorio
(GUI Python) recibe el stream USB, hace precheck de integridad y guarda los datos.

**Estado de modulos:**

| Sensor   | Estado       | Rol                                    |
|----------|--------------|----------------------------------------|
| sensor_B | **Primario** | Uso diario. sensor_id = 1 en stream.   |
| sensor_A | Backup       | Fallback. sensor_id = 2 en stream.     |
| sensor_C | Referencia   | Historico/provisional.                 |
| sensor_D | Descartado   | Fuera de uso.                          |

---

## 2. Que hace este repositorio

1. Captura en vivo via GUI Python con graficas en tiempo real.
2. Precheck dual de integridad antes de aceptar una sesion.
3. Genera automaticamente `_raw.csv`, `_processed.csv`, `_session.json`,
   `_summary.txt` y `_precheck.txt` por sesion.
4. Distribuye la aplicacion como `.exe` standalone (sin instalar Python).
5. Mantiene firmware ESP32 para el nodo sensor y el receptor USB.

**Guia de Claude:** ver [`AGENTS.md`](AGENTS.md) para estado completo, convenciones y reglas.

---

## 3. Estructura de carpetas

```text
Repo/
├── gui/                          # Aplicacion de captura live (Python/Tkinter)
│   ├── adxl_live_gui.py          #   Punto de entrada y UI
│   └── adxl_live_core.py         #   Logica de captura, serial, guardado
├── firmware/
│   ├── single_node_calibration/  #   Firmware operativo actual (PlatformIO)
│   └── dual_node_espnow/         #   Arquitectura ESP-NOW Fase 14B/14C
├── data/
│   ├── raw/sensor_B_live/        #   CSVs crudos (NO modificar)
│   └── processed/                #   CSVs procesados + JSONs de sesion
├── reports/
│   ├── analysis_outputs/         #   _summary.txt y _precheck.txt por sesion
│   └── change_log.md             #   Registro tecnico de cambios
├── live_session_hub/             # Launchers de sesion
├── scripts/                      # Helpers PowerShell
├── config/                       # Plantillas de configuracion JSON
├── matlab/                       # Analisis historico (no es ruta operativa)
├── docs/                         # Guia maestra LaTeX + PDF
├── hardware/                     # Pinout y registro de sensores
├── handoff/                      # Exports de handoff por rol (Fase 14C.1)
│
├── adxl_captura.spec             # Spec PyInstaller para compilar el .exe
├── build_exe.ps1                 # Compila .exe y genera ZIP de distribucion
├── build_manual_pdf.py           # Genera el manual de usuario PDF
├── ADXL335_Captura_Manual.pdf    # Manual de usuario (generado)
├── requirements-gui.txt          # Dependencias Python (pyserial==3.5)
├── AGENTS.md                     # Guia operativa para Claude
└── README.md                     # Este archivo
```

Carpetas en `.gitignore` (generadas, no commitear):

```text
.venv/        # Entorno virtual Python
dist/         # .exe compilado y ZIP de distribucion
build_work/   # Artefactos intermedios de PyInstaller
```

---

## 4. Requisitos

- Windows 10/11 de 64 bits + PowerShell.
- Python 3.10+ con `tkinter` (para desarrollo; no necesario para el `.exe`).
- ESP32 con firmware de `firmware/single_node_calibration/`.
- ADXL335 cableado:

  | Pin ADXL335 | Pin ESP32 |
  |-------------|-----------|
  | VCC         | 3V3       |
  | GND         | GND       |
  | X-OUT       | GPIO32    |
  | Y-OUT       | GPIO33    |
  | Z-OUT       | GPIO34    |
  | ST          | GPIO23 (solo diagnostico) |

---

## 5. Uso rapido — ejecutable standalone

La forma mas facil de usar el sistema sin instalar nada:

1. Descargar `dist/ADXL335_Captura_dist.zip` y extraer en cualquier carpeta.
2. Conectar la ESP32 por USB.
3. Ejecutar `ADXL335_Captura.exe`.
4. La app detecta el puerto automaticamente, hace el precheck y captura.

Los datos se guardan junto al `.exe`:

```text
data\raw\sensor_B_live\    ← CSVs crudos
data\processed\            ← CSVs procesados + JSONs
reports\analysis_outputs\  ← Resumenes y reportes de precheck
```

Ver `ADXL335_Captura_Manual.pdf` para la descripcion completa de la interfaz
y el significado de cada campo en los archivos exportados.

---

## 6. Uso en desarrollo — GUI desde el repo

Instalar dependencias (una sola vez):

```powershell
.\scripts\install_gui_requirements.ps1
```

Lanzar la GUI:

```powershell
.\live_session_hub\sensorB_live_gui_session.ps1
```

O con parametros:

```powershell
.venv\Scripts\python.exe gui\adxl_live_gui.py `
    --duration-s 30 `
    --session-name ensayo1 `
    --port COM4
```

---

## 7. Compilar el ejecutable

```powershell
.\build_exe.ps1
```

Instala PyInstaller si falta, compila `dist\ADXL335_Captura.exe` y genera
`dist\ADXL335_Captura_dist.zip` listo para distribuir.

---

## 8. Generar el manual PDF

```powershell
.venv\Scripts\pip install fpdf2
.venv\Scripts\python.exe build_manual_pdf.py
```

Genera `ADXL335_Captura_Manual.pdf` en la raiz del repo.

---

## 9. Firmware ESP32

Build:

```powershell
$env:PLATFORMIO_EXE = "$env:USERPROFILE\.platformio\penv\Scripts\pio.exe"
& $env:PLATFORMIO_EXE run -d .\firmware\single_node_calibration
```

Upload (puede requerir mantener BOOT presionado):

```powershell
& $env:PLATFORMIO_EXE run -d .\firmware\single_node_calibration -t upload
```

---

## 10. Flujo de datos y archivos exportados

```text
ESP32 (firmware)
    │  serial USB 115200 baud
    ▼
GUI Python (adxl_live_gui.py)
    │  precheck dual 10 s → rechaza si falla
    │  captura 10-90 s
    ▼
Archivos por sesion:
    {prefijo}_{sesion}_{AAAAMMDD}_{HHMMSS}_raw.csv
    {prefijo}_{sesion}_{AAAAMMDD}_{HHMMSS}_processed.csv
    {prefijo}_{sesion}_{AAAAMMDD}_{HHMMSS}_session.json
    {prefijo}_{sesion}_{AAAAMMDD}_{HHMMSS}_summary.txt
    {prefijo}_{sesion}_{AAAAMMDD}_{HHMMSS}_precheck.txt
```

Campos del CSV procesado:

```text
sensor_id, seq, t_us, wall_s, raw_x, raw_y, raw_z,
mv_x, mv_y, mv_z, gx_est, gy_est, gz_est, g_norm_est
```

Ver `ADXL335_Captura_Manual.pdf` para descripcion completa de cada campo.

---

## 11. Reglas de calidad rapidas

Una captura es util si cumple:

- `SEQ_JUMPS = 0` (o muy pocos saltos de secuencia)
- `95 <= FREQ_HZ <= 105` Hz por sensor
- `SAT_PCT_ANY_AXIS <= 1.0 %`

Si no cumple: revisar cableado, cerrar monitores seriales externos y repetir.

---

## 12. Fallback operativo

Si `sensor_B` falla sanidad en dos corridas cortas consecutivas:

1. Cambiar temporalmente a `sensor_A` (mismo flujo de captura).
2. Registrar el incidente en `reports/analysis_outputs/`.
3. Investigar la causa antes de volver a `sensor_B`.

---

## 13. Documentacion adicional

| Documento | Descripcion |
|-----------|-------------|
| `AGENTS.md` | Guia completa para Claude: estado, convenciones, formatos |
| `ADXL335_Captura_Manual.pdf` | Manual de usuario del .exe |
| `docs/project_master_guide_adxl335_esp32.pdf` | Guia tecnica maestra del proyecto |
| `reports/change_log.md` | Registro cronologico de todos los cambios |
| `reports/gui_live_runtime_migration_20260412.md` | Reporte de migracion MATLAB→GUI |
| `reports/repository_sync_status_20260508.md` | Auditoria local/remoto, remoto correcto y cierre de sincronizacion Git |
