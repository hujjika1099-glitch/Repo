# TICKET 014 - Precheck de sincronizacion dual KX134

## Objetivo

Ejecutar una validacion operativa dual con dos sensores KX134 sobre ESP-NOW y una ESP32
receptora USB, incluyendo una prueba estatica, una prueba con evento fisico comun y un
diagnostico explicito de duplicados exactos observados previamente en el stream.

Decision esperada:

`READY_FOR_GUI_KX134_STREAM_INTEGRATION = YES/NO`

## Precondiciones

- TICKET 013 aprobado.
- Rama activa: `feature/kx134-dual-capture`.
- Firmware dual disponible en `firmware/kx134_dual_espnow/`.
- Sensor 1 calibrado, `sensor_id=1`, MAC `D4:E9:F4:E9:8E:1C`, 100 Hz, rango 8 g.
- Sensor 2 calibrado, `sensor_id=2`, MAC `D4:E9:F4:C3:37:14`, 100 Hz, rango 8 g.
- Receptor cargado con firmware `kx134_dual_espnow`, MAC `00:4B:12:96:9A:80`,
  canal ESP-NOW 1 y Serial a 921600 baudios.

## Procedimiento interactivo

### 1. Captura estatica

Instruccion al operador:

```text
Conecte ambas ESP32 sensoras alimentadas, cada una con su KX134. Conecte la ESP32
receptora al PC por USB. Coloque ambos sensores quietos sobre una superficie estable,
preferiblemente en la misma orientacion. Cuando todo este listo, presione Enter.
```

Comando de captura:

```powershell
powershell -ExecutionPolicy Bypass -File tools\kx134\capture_serial_direct.ps1 -Port COM4 -Baud 921600 -Seconds 30 -OutputPath reports\kx134_test_runs\TICKET_014_static_receiver_monitor_<timestamp>.txt
```

Comando de analisis:

```powershell
python tools\kx134\analyze_dual_sync_precheck.py reports\kx134_test_runs\TICKET_014_static_receiver_monitor_<timestamp>.txt --event-mode static --output reports\kx134_test_runs\TICKET_014_static_analysis_<timestamp>.json --dedup-mode report_only
```

### 2. Captura con evento comun

Instruccion al operador:

```text
Coloque ambos sensores firmemente sobre la misma superficie o sobre la misma pieza
rigida. La idea es aplicar un evento comun suave, no un golpe fuerte. Cuando presione
Enter, CODEX iniciara captura. Espere 5 segundos, luego de 3 taps suaves separados por
2 segundos. Despues deje los sensores quietos hasta terminar.
```

Comando de captura:

```powershell
powershell -ExecutionPolicy Bypass -File tools\kx134\capture_serial_direct.ps1 -Port COM4 -Baud 921600 -Seconds 30 -OutputPath reports\kx134_test_runs\TICKET_014_event_receiver_monitor_<timestamp>.txt
```

Comando de analisis:

```powershell
python tools\kx134\analyze_dual_sync_precheck.py reports\kx134_test_runs\TICKET_014_event_receiver_monitor_<timestamp>.txt --event-mode event --output reports\kx134_test_runs\TICKET_014_event_analysis_<timestamp>.json --dedup-mode report_only
```

Si no se detecta evento comun, se permite repetir una vez con taps un poco mas claros,
sin golpes violentos.

## Archivos generados

- `tools/kx134/capture_serial_direct.ps1`
- `tools/kx134/analyze_dual_sync_precheck.py`
- `docs/kx134_migration/DUAL_SYNC_PRECHECK_KX134.md`
- `docs/kx134_migration/tickets/TICKET_014_PRECHECK_SINCRONIZACION_DUAL_KX134.md`
- `reports/kx134_test_runs/TICKET_014_static_receiver_monitor_<timestamp>.txt`
- `reports/kx134_test_runs/TICKET_014_event_receiver_monitor_<timestamp>.txt`
- `reports/kx134_test_runs/TICKET_014_static_analysis_<timestamp>.json`
- `reports/kx134_test_runs/TICKET_014_event_analysis_<timestamp>.json`
- `reports/kx134_test_runs/TICKET_014_DUAL_SYNC_PRECHECK_SUMMARY.md`

## Criterios de aceptacion

- Captura estatica con ambos sensores presentes.
- Al menos 1000 filas por sensor.
- Frecuencia efectiva entre 98 y 102 Hz por sensor.
- `seq_gaps=0` preferible.
- `receiver_t_us` valido.
- `packet_status=OK` y `packet_error_code=OK`.
- Evento comun detectado en ambos sensores.
- `delta_event_receiver_us <= 30000`.
- Duplicados clasificados como no observados, artefacto probable, no bloqueantes o
  corregidos.
- Sin campos ADXL335 prohibidos en el contrato KX134.

## Restricciones

No se modifica firmware ADXL335, firmware KX134 single-node, GUI, empaquetado, data
historica, calibraciones KX134 ni reportes historicos de calibracion. El firmware dual
solo puede modificarse si se confirma una causa clara de doble emision real del receptor.

## Decision final esperada

El cierre del ticket debe emitir una sola decision operativa:

`READY_FOR_GUI_KX134_STREAM_INTEGRATION = YES/NO`
