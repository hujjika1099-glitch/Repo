# Proyecto de Maestria: ADXL335 + ESP32 (Operacion Real)

## 1) Estado actual del proyecto
Este repositorio ya paso la etapa de validacion larga de sensores y esta en uso operativo real.

Estado de modulos:
- `sensor_B`: modulo primario para trabajo diario.
- `sensor_A`: backup operativo.
- `sensor_C`: referencia historica/provisional.
- `sensor_D`: descartado.

Decision operativa vigente:
- El proyecto avanza con `sensor_B`.
- No se reabre Fase 11 ni self-test como gate de uso normal.
- El flujo prioriza captura en vivo, procesamiento y bloques funcionales.

## 2) Que problema resuelve este repo
Permite capturar datos de aceleracion con ESP32 + ADXL335 y convertirlos en artefactos listos para analisis funcional:
1. Captura en vivo (serial -> MATLAB).
2. Ingesta operativa (limpieza y estandarizacion).
3. Bloque funcional post-ingesta (features + segmentos de movimiento).
4. Preparacion de migracion futura a ESP-NOW sin romper MATLAB.

## 3) Estructura de carpetas (guia rapida)
Rutas clave:
- `firmware/single_node_calibration/`
  Firmware operativo actual del ESP32.
- `firmware/dual_node_espnow/phase14b_transport_contract.json`
  Contrato para migracion a arquitectura dual-node (14B).
- `matlab/live/`
  Sesion live en tiempo real.
- `matlab/analysis/`
  Ingesta operativa y bloque funcional.
- `scripts/`
  Helpers PowerShell para ejecucion rapida.
- `live_session_hub/`
  Lanzador para correr multiples pruebas en una sola instancia MATLAB.
- `data/raw/`
  Evidencia primaria (no se sobrescribe).
- `data/processed/`
  Datos derivados listos para modulos siguientes.
- `reports/analysis_outputs/`
  Resumenes y trazabilidad de ejecucion.

## 4) Requisitos minimos
- Windows + PowerShell.
- MATLAB instalado y licenciado.
- ESP32 con firmware de `firmware/single_node_calibration`.
- ADXL335 cableado en el pinout estandar:
  - `VCC -> 3V3`
  - `GND -> GND`
  - `X-OUT -> GPIO32`
  - `Y-OUT -> GPIO33`
  - `Z-OUT -> GPIO34`
  - `ST -> GPIO23` (solo diagnostico; no requerido para operacion normal)

## 5) Flujo operativo recomendado (diario)
### Opcion A: sesion live manual en una sola ventana MATLAB (recomendada)
Evita abrir nuevas instancias y reduce carga del PC.

1. Abrir MATLAB una sola vez.
2. Ejecutar:
```matlab
run('live_session_hub/sensorB_live_prompt_session.m')
```
3. Responder en consola:
- duracion en segundos,
- nombre de sesion,
- prefijo,
- carpeta de salida,
- guardar CSV/MAT,
- modo de grafica.

Salida esperada al terminar:
- CSV raw en `data/raw/sensor_B_live/`
- CSV processed en `data/processed/`
- MAT de sesion en `data/processed/`
- TXT resumen en `reports/analysis_outputs/`

### Opcion B: captura rapida por PowerShell
```powershell
.\scripts\run_sensorB_operational_capture.ps1 -Port COM5 -DurationS 90 -PoseLabel operational_run
```

Este helper entrega sanidad automatica:
- `FREQ_HZ`
- `SEQ_JUMPS`
- `SAT_PCT_ANY_AXIS`
- `SANITY_STATUS`

## 6) Flujo de procesamiento (post-captura)
### Paso 1: ingesta operativa
Convierte un raw CSV en paquete procesado para el siguiente modulo.

Ejemplo:
```powershell
matlab -batch "sensor_id='sensor_B'; input_csv_abs='data/raw/sensor_B/sensor_B_operational_run_90s_20260322_191502.csv'; run('matlab/analysis/run_sensorB_operational_ingest.m')"
```

Resultado principal:
- `data/processed/sensor_B_operational_ingest_<timestamp>.csv`

### Paso 2: bloque funcional
Genera features por ventana y segmentos de movimiento.

Ejemplo:
```powershell
matlab -batch "sensor_id='sensor_B'; input_processed_csv='data/processed/sensor_B_operational_ingest_20260322_193323.csv'; run('matlab/analysis/run_sensorB_operational_feature_block.m')"
```

Resultados principales:
- `data/processed/sensor_B_operational_features_<timestamp>.csv`
- `data/processed/sensor_B_operational_motion_segments_<timestamp>.csv`
- `data/processed/sensor_B_operational_feature_block_<timestamp>.mat`

## 7) Evidencia de funcionamiento real
Captura operativa oficial ya validada:
- `data/raw/sensor_B/sensor_B_operational_run_90s_20260322_191502.csv`

Resumen validado:
- `CAPTURE_OK`
- `SAMPLES: 8991`
- `FREQ_EST_HZ: 100.001`
- `SEQ_JUMPS: 0`
- `SAT_PCT_ANY_AXIS: 0.000`
- `SANITY_STATUS: pass`

Ingesta oficial derivada:
- `data/processed/sensor_B_operational_ingest_20260322_193323.csv`

Con esto, el pipeline ya esta operando de extremo a extremo en condiciones reales.

## 8) Que archivos usar como entrada del siguiente modulo
Entrada oficial recomendada para desarrollo funcional:
- `data/processed/sensor_B_operational_ingest_20260322_193323.csv`

Si el siguiente bloque requiere features en ventanas, usar:
- `data/processed/sensor_B_operational_features_<timestamp>.csv`

## 9) Reglas de calidad rapidas antes de usar una corrida
Una corrida se considera util para continuar si cumple:
- `SEQ_JUMPS = 0`
- `95 <= FREQ_HZ <= 105`
- `SAT_PCT_ANY_AXIS <= 1.0`

Si no cumple:
1. revisar cableado y puerto,
2. repetir una sola captura corta,
3. si persiste, fallback a `sensor_A`.

## 10) Fallback operativo
Regla de fallback:
- si `sensor_B` falla sanidad en dos corridas cortas consecutivas, cambiar temporalmente a `sensor_A`.
- mantener mismo flujo de captura e ingesta.
- registrar el incidente en `reports/analysis_outputs/`.

## 11) Preparacion de Fase 14B (ESP-NOW)
El contrato ya esta definido en:
- `firmware/dual_node_espnow/phase14b_transport_contract.json`

Regla clave para no romper MATLAB:
- el receptor USB debe emitir la misma linea CSV actual:
`seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z`

## 12) Documentacion principal del proyecto
Guia maestra editable y compilada:
- `docs/project_master_guide_adxl335_esp32.tex`
- `docs/project_master_guide_adxl335_esp32.pdf`

## 13) Comandos utiles de referencia
### Build de firmware (PlatformIO local)
```powershell
$env:PLATFORMIO_EXE="$env:USERPROFILE\.platformio\penv\Scripts\pio.exe"
& $env:PLATFORMIO_EXE run -d .\firmware\single_node_calibration
```

### Upload de firmware
```powershell
$env:PLATFORMIO_EXE="$env:USERPROFILE\.platformio\penv\Scripts\pio.exe"
& $env:PLATFORMIO_EXE run -d .\firmware\single_node_calibration -t upload
```

### Si el upload no entra automatico
- Presionar y mantener `BOOT`.
- Lanzar el comando de upload.
- Soltar `BOOT` cuando aparezca `Connecting...`.

## 14) Soporte rapido
Checklist rapido cuando algo no corre:
1. Confirmar puerto COM correcto.
2. Cerrar otro programa que use el puerto serial.
3. Verificar que el firmware este cargado.
4. Ejecutar una corrida corta de 10-20s.
5. Revisar resumen `.txt` en `reports/analysis_outputs/`.

---
Repositorio preparado para operacion real y para compartir URL de referencia tecnica.
