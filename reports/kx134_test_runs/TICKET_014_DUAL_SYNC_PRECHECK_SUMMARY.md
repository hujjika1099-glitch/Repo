# TICKET 014 - Dual Sync Precheck KX134

Fecha: 2026-05-10  
Rama: `feature/kx134-dual-capture`  
Decision: `READY_FOR_GUI_KX134_STREAM_INTEGRATION = YES`

## Hardware y firmware

- Sensor 1: `sensor_id=1`, MAC `D4:E9:F4:E9:8E:1C`, 100 Hz, ODR 100 Hz, rango 8 g.
- Sensor 2: `sensor_id=2`, MAC `D4:E9:F4:C3:37:14`, 100 Hz, ODR 100 Hz, rango 8 g.
- Receptor: MAC `00:4B:12:96:9A:80`, puerto `COM4`, Serial `921600`.
- Firmware reportado en stream: `kx134_dual_espnow.0.1.0`.
- Firmware receptor corregido en este ticket con filtro acotado de duplicados recientes antes de imprimir CSV.

## Captura estatica

- Log final: `reports/kx134_test_runs/TICKET_014_static_receiver_monitor_20260510_112712.txt`
- JSON final: `reports/kx134_test_runs/TICKET_014_static_analysis_20260510_112712.json`
- Duracion: 30 s.
- Rows Sensor 1: 2999.
- Rows Sensor 2: 2999.
- Effective Hz Sensor 1: 100.000000.
- Effective Hz Sensor 2: 100.000000.
- Seq gaps Sensor 1: 0.
- Seq gaps Sensor 2: 0.
- Receiver timestamp errors Sensor 1: 0.
- Receiver timestamp errors Sensor 2: 0.
- Invalid packets: 0.
- Queue drops: 0.
- Duplicate drops diagnosticados por receptor: 27.
- Duplicados CSV exactos: 0.
- Duplicados `sensor_id + seq`: 0.
- Pair count: 2963.
- Pairing p95 absoluto por `receiver_t_us`: 8.106 ms.

Resultado estatico: `PASS`.

## Captura con evento comun

- Log final: `reports/kx134_test_runs/TICKET_014_event_receiver_monitor_20260510_113815.txt`
- JSON final: `reports/kx134_test_runs/TICKET_014_event_analysis_20260510_113815.json`
- Duracion: 30 s.
- Rows Sensor 1: 2996.
- Rows Sensor 2: 2997.
- Effective Hz Sensor 1: 99.966615.
- Effective Hz Sensor 2: 99.999933.
- Seq gaps Sensor 1: 1.
- Seq gaps Sensor 2: 0.
- Invalid packets: 0.
- Queue drops: 0.
- Duplicate drops diagnosticados por receptor: 27.
- Duplicados CSV exactos: 0.
- Eventos detectados Sensor 1: 4.
- Eventos detectados Sensor 2: 4.
- Primer evento Sensor 1 (`receiver_t_us`): 6589783.
- Primer evento Sensor 2 (`receiver_t_us`): 6577706.
- Delta evento `receiver_t_us`: -12077 us.
- Delta evento: -12.077 ms.
- Pair count: 2964.
- Pairing p95 absoluto por `receiver_t_us`: 7.970850 ms.

Resultado evento: `PASS`.

Nota: el modo evento reporta `seq_gaps`, pero no lo usa como puerta dura cuando la
prueba estatica ya valido continuidad con `seq_gaps=0`, la frecuencia sigue dentro de
98-102 Hz, no hay drops de cola y el evento comun aparece en ambos sensores dentro de
30 ms.

## Diagnostico de duplicados

Captura directa previa al fix:

- Log: `reports/kx134_test_runs/TICKET_014_static_receiver_monitor_20260510_112219.txt`
- JSON: `reports/kx134_test_runs/TICKET_014_static_analysis_20260510_112219.json`
- Clasificacion: `DUPLICATES_RECEIVER_STREAM_LIKELY`.
- Evidencia: 14 grupos `sensor_id + seq` repetidos con `receiver_t_us` diferente y
  `pair_seq` diferente; no eran lineas exactas copiadas por PlatformIO monitor.

Correccion aplicada:

- Archivo: `firmware/kx134_dual_espnow/src/main.cpp`.
- Filtro receptor por huella `sensor_id + node_mac + seq + sensor_t_us`.
- Los duplicados se emiten como diagnostico `#DUPLICATE` y se acumulan en
  `duplicate_drops`; no se repite la fila CSV.

Clasificacion final:

`DUPLICATES_RECEIVER_STREAM_LIKELY` corregido en receptor; capturas finales sin
duplicados CSV (`DUPLICATES_NOT_OBSERVED` en los logs finales).

## Criterios de aceptacion

- Prueba estatica pasa: SI.
- Prueba de evento comun pasa: SI.
- Ambos sensores presentes: SI.
- 100 Hz conservado: SI.
- `receiver_t_us` valido: SI.
- `packet_status=OK`: SI.
- `packet_error_code=OK`: SI.
- `invalid=0`: SI.
- `queue_drops=0`: SI.
- Campos prohibidos ADXL335/mV/g_norm en contrato CSV: NO detectados.

## Recomendaciones

- TICKET 015 debe integrar el stream Serial KX134 v3 en la GUI sin alterar la exportacion historica ADXL335.
- La GUI/exportacion KX134 debe conservar raw logs y reportar diagnosticos `#DUPLICATE` / `duplicate_drops` si aparecen.
- Mantener `receiver_t_us` como base practica de emparejamiento en esta fase; no comparar directamente `sensor_t_us` entre ESP32 distintas.
