# TICKET 013 - Dual ESP-NOW KX134 Test Summary

Fecha/hora local: 2026-05-10 10:52

## Base

- Rama: `feature/kx134-dual-capture`
- Commit base antes del ticket: `2939b2e` (`firmware: capture KX134 receiver ESP32 MAC`)
- Firmware: `kx134_dual_espnow`
- Firmware version: `kx134_dual_espnow.0.1.0`
- Contrato Serial: `kx134.v3`
- ESP-NOW channel: 1
- Serial baud: 921600

## Uploads

- Sensor 1: COM5, upload SUCCESS, MAC observada `D4:E9:F4:E9:8E:1C`, BOOT no reportado como bloqueo.
- Sensor 2: COM5, upload SUCCESS, MAC observada `D4:E9:F4:C3:37:14`, BOOT no reportado como bloqueo.
- Receptor: COM4, upload SUCCESS, MAC observada `00:4B:12:96:9A:80`, BOOT no reportado como bloqueo.

## Captura

- Puerto monitor/captura: COM4
- Duracion de captura: 20 s nominales
- Log Serial: `reports/kx134_test_runs/TICKET_013_dual_espnow_receiver_monitor_20260510_104746.txt`
- Analisis JSON: `reports/kx134_test_runs/TICKET_013_dual_espnow_analysis_20260510_105228.json`
- Encabezado CSV capturado: si
- Sensor 1 presente: si
- Sensor 2 presente: si
- Ventana de analisis: se descartan 2 s de warm-up del receptor y 2 filas previas al encabezado real; esto evita contaminar la continuidad con el reset del receptor al abrir el puerto.

## Resultados

| Campo | Sensor 1 | Sensor 2 |
| --- | ---: | ---: |
| Filas limpias analizadas | 1722 | 1723 |
| Seq inicial | 55164 | 54445 |
| Seq final | 56885 | 56167 |
| Seq gaps | 0 | 0 |
| Timestamp errors | 0 | 0 |
| Effective Hz | 100.000023 | 100.000006 |
| Receiver Hz aprox | 100.001761 | 100.014491 |
| g_norm mean | 1.012828 | 1.002087 |
| Duplicados exactos retirados para analisis | 14 | 2 |

## Diagnostico receptor

- `receiver_t_us` valido: si
- `packet_status`: OK
- `packet_error_code`: OK
- Invalid packets: 0
- Queue drops: 0
- Campos prohibidos detectados: ninguno
- Ultimos contadores observados en diagnostico: `#STAT,role=receiver,rx_total=3600,rx_s1=1807,rx_s2=1793,invalid=0,queue_drops=0`

## Decision

`READY_FOR_DUAL_SYNC_PRECHECK = YES`

Justificacion: ambos sensores transmiten por ESP-NOW hacia el receptor, las MAC coinciden con el node map, el receptor emite CSV KX134 v3 sin campos ADXL335/mV/g_norm, la frecuencia efectiva por sensor queda en 100 Hz, `seq_gaps=0`, `receiver_t_us` crece y el receptor reporta `invalid=0` y `queue_drops=0`. Se observaron duplicados exactos ocasionales en el stream visible; quedaron reportados y deduplicados solo para metricas de continuidad, sin modificar el log crudo.
