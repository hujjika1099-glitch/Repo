# Guia Operativa del Proyecto ADXL335 + ESP32

Version: 2026-03-22

## 1. Resumen ejecutivo
Este documento explica como usar el proyecto de forma practica para capturar datos, procesarlos y obtener salidas utiles para desarrollo funcional.

Estado operativo actual:
- sensor_B: modulo principal.
- sensor_A: modulo backup.
- sensor_C: referencia historica.
- sensor_D: descartado.

Resultado principal:
- El flujo completo ya funciona en entorno real con captura validada, ingesta y bloque funcional.

## 2. Objetivo del sistema
Tomar datos de movimiento desde un ADXL335 conectado a ESP32 y dejar archivos listos para analisis y desarrollo del siguiente modulo del proyecto.

En terminos simples:
1. Se captura la senal.
2. Se organiza y limpia.
3. Se generan indicadores de movimiento.
4. Se guarda todo con trazabilidad.

## 3. Que incluye el repositorio
### 3.1 Firmware
- Ruta: `firmware/single_node_calibration/src/main.cpp`
- Funcion: leer el sensor y enviar datos por serial en formato CSV.

### 3.2 Captura y analisis en MATLAB
- Captura live: `matlab/live/run_sensorB_live_session.m`
- Parser de linea serial: `matlab/live/parse_adxl335_stream_line.m`
- Estimacion base en g: `matlab/live/estimate_sensorB_accel_g.m`
- Ingesta operativa: `matlab/analysis/run_sensorB_operational_ingest.m`
- Bloque funcional (features y segmentos): `matlab/analysis/run_sensorB_operational_feature_block.m`

### 3.3 Helpers de ejecucion
- Captura operativa: `scripts/run_sensorB_operational_capture.ps1`
- Sesion live por comando: `scripts/run_sensorB_live_session.ps1`
- Launcher recomendado para no abrir muchas ventanas: `live_session_hub/sensorB_live_prompt_session.m`

## 4. Cableado estandar
Usar siempre este mapeo:

| Pin ADXL335 | Pin ESP32 |
|---|---|
| VCC | 3V3 |
| GND | GND |
| X-OUT | GPIO32 |
| Y-OUT | GPIO33 |
| Z-OUT | GPIO34 |
| ST (pad lateral) | GPIO23 |

Notas practicas:
- ST es un pad lateral separado del header principal.
- GPIO34 es solo entrada, pero para lectura analogica funciona bien.
- ST no se usa como requisito en operacion normal diaria.

## 5. Flujo recomendado para trabajo diario
### 5.1 Captura live sin abrir nuevas ventanas de MATLAB
Este es el modo recomendado para varias pruebas seguidas.

Pasos:
1. Abrir MATLAB una sola vez.
2. Ejecutar:
   `run('live_session_hub/sensorB_live_prompt_session.m')`
3. Responder preguntas:
   - duracion,
   - nombre,
   - prefijo,
   - carpeta de salida,
   - guardar CSV/MAT,
   - modo grafica.
4. Al terminar, repetir el mismo comando para una nueva prueba.

Ventaja:
- evita abrir una nueva instancia de MATLAB cada vez.
- reduce carga del PC.

### 5.2 Captura automatica por PowerShell
Comando:

```powershell
.\scripts\run_sensorB_operational_capture.ps1 -Port COM5 -DurationS 90 -PoseLabel operational_run
```

Este comando tambien revisa sanidad basica y muestra:
- frecuencia,
- saltos de secuencia,
- porcentaje de saturacion,
- estado final pass/review.

## 6. Flujo de procesamiento del archivo capturado
### 6.1 Ingesta
Objetivo:
- crear un archivo procesado estable que sirva como entrada del siguiente bloque.

Ejemplo:

```powershell
matlab -batch "sensor_id='sensor_B'; input_csv_abs='data/raw/sensor_B/sensor_B_operational_run_90s_20260322_191502.csv'; run('matlab/analysis/run_sensorB_operational_ingest.m')"
```

Salida principal:
- `data/processed/sensor_B_operational_ingest_<timestamp>.csv`

### 6.2 Bloque funcional
Objetivo:
- transformar la corrida procesada en features por ventana y segmentos de movimiento.

Ejemplo:

```powershell
matlab -batch "sensor_id='sensor_B'; input_processed_csv='data/processed/sensor_B_operational_ingest_20260322_193323.csv'; run('matlab/analysis/run_sensorB_operational_feature_block.m')"
```

Salidas principales:
- `data/processed/sensor_B_operational_features_<timestamp>.csv`
- `data/processed/sensor_B_operational_motion_segments_<timestamp>.csv`
- `data/processed/sensor_B_operational_feature_block_<timestamp>.mat`

## 7. Formato de datos esperado
### 7.1 Linea serial base
CSV con columnas:
- `seq`
- `t_us`
- `raw_x`
- `raw_y`
- `raw_z`
- `mv_x`
- `mv_y`
- `mv_z`

### 7.2 Archivo processed de ingesta
Incluye columnas originales y derivadas como:
- `time_s`
- `mv_x_centered`, `mv_y_centered`, `mv_z_centered`
- `mv_norm`, `mv_norm_centered`

### 7.3 Archivo de features
Incluye indicadores por ventana:
- RMS por eje,
- desviacion,
- pico a pico,
- umbral de movimiento,
- bandera `is_motion`.

## 8. Evidencia de funcionamiento en banco
Captura oficial validada:
- `data/raw/sensor_B/sensor_B_operational_run_90s_20260322_191502.csv`

Valores de control observados:
- CAPTURE_OK
- SAMPLES: 8991
- FREQ_EST_HZ: 100.001
- SEQ_JUMPS: 0
- SAT_PCT_ANY_AXIS: 0.000
- SANITY_STATUS: pass

Ingesta oficial asociada:
- `data/processed/sensor_B_operational_ingest_20260322_193323.csv`

## 9. Reglas de aceptacion rapida
Antes de usar una corrida en el siguiente modulo:
- `SEQ_JUMPS = 0`
- `95 <= FREQ_HZ <= 105`
- `SAT_PCT_ANY_AXIS <= 1.0`

Si una corrida no cumple:
1. revisar cableado y puerto,
2. repetir solo una corrida corta,
3. si continua mal, usar sensor_A como backup.

## 10. Fallback operativo
Regla simple:
- si sensor_B falla 2 corridas cortas seguidas, se pasa a sensor_A.
- se mantiene el mismo flujo de scripts para no perder continuidad.

## 11. Preparacion de etapa ESPNOW
Ruta de contrato:
- `firmware/dual_node_espnow/phase14b_transport_contract.json`

Condicion clave:
- el receptor USB debe emitir el mismo formato de linea serial actual.

Impacto esperado:
- MATLAB podra seguir usando el parser existente sin cambios mayores.

## 12. Checklist antes de una sesion
1. Confirmar cableado.
2. Confirmar puerto COM.
3. Confirmar firmware cargado.
4. Definir nombre de sesion y duracion.
5. Ejecutar captura.
6. Revisar resumen en `reports/analysis_outputs/`.

## 13. Checklist despues de una sesion
1. Validar que se creo CSV raw.
2. Validar que se creo CSV processed.
3. Validar que se creo resumen TXT.
4. Ejecutar ingesta si aplica.
5. Ejecutar bloque funcional si aplica.
6. Guardar la ruta de salida usada como entrada del siguiente modulo.

## 14. Comandos de referencia rapida
### Build firmware
```powershell
$env:PLATFORMIO_EXE="$env:USERPROFILE\.platformio\penv\Scripts\pio.exe"
& $env:PLATFORMIO_EXE run -d .\firmware\single_node_calibration
```

### Upload firmware
```powershell
$env:PLATFORMIO_EXE="$env:USERPROFILE\.platformio\penv\Scripts\pio.exe"
& $env:PLATFORMIO_EXE run -d .\firmware\single_node_calibration -t upload
```

Si no conecta automatico:
- mantener BOOT presionado,
- ejecutar upload,
- soltar BOOT cuando aparezca `Connecting...`.

### Sesion live desde MATLAB unico
```matlab
run('live_session_hub/sensorB_live_prompt_session.m')
```

### Captura operativa directa
```powershell
.\scripts\run_sensorB_operational_capture.ps1 -Port COM5 -DurationS 90 -PoseLabel operational_run
```

## 15. Entradas y salidas oficiales actuales
Entrada operativa oficial para desarrollo:
- `data/processed/sensor_B_operational_ingest_20260322_193323.csv`

Soporte oficial asociado:
- `data/processed/sensor_B_operational_ingest_20260322_193323.mat`
- `reports/analysis_outputs/sensor_B_operational_ingest_20260322_193323.txt`

## 16. Porque este flujo ya es confiable para avanzar
- Usa una fuente primaria definida (`sensor_B`).
- Tiene criterios de sanidad simples y medibles.
- Genera salidas trazables en cada ejecucion.
- Mantiene separadas evidencia cruda y datos procesados.
- Ya produce artefactos listos para el siguiente modulo funcional.

## 17. Rutas de documentos de apoyo
- README principal: `README.md`
- Reglas del proyecto: `AGENTS.md`
- Wiring estandar: `hardware/adxl335_standard_wiring.md`
- Runbook sensor_B: `reports/sensor_B_operational_runbook_phase13.md`
- Contrato 14B: `firmware/dual_node_espnow/phase14b_transport_contract.json`

## 18. Cierre
El proyecto esta listo para continuar desarrollo funcional con datos reales, sin volver al ciclo de caracterizacion larga de sensores.
