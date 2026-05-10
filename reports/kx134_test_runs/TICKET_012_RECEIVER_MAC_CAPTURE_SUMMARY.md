# TICKET 012 - KX134 Receiver ESP32 MAC Capture

Fecha: 2026-05-09
Rama: `feature/kx134-dual-capture`

## Decision

`RECEIVER_MAC_CAPTURED = YES`

La tercera ESP32 quedo identificada como receptora KX134 pendiente de firmware ESP-NOW.

## Firmware

- Ruta: `firmware/kx134_receiver_identity`
- Firmware: `kx134_receiver_identity`
- Rol: `receiver_esp32`
- Build: pass
- Upload: pass
- ESP-NOW dual: no implementado en este ticket

## Puerto y MAC

- Puerto usado: `COM4`
- Baudrate: `921600`
- MAC capturada por esptool: `00:4b:12:96:9a:80`
- MAC capturada por Serial: `00:4B:12:96:9A:80`
- Estado: `mac_captured_pending_kx134_receiver_firmware`

## Evidencia Serial

Log interactivo:

`reports/kx134_test_runs/TICKET_012_receiver_identity_monitor_20260509_190020.txt`

Log complementario principal:

`reports/kx134_test_runs/TICKET_012_receiver_identity_monitor_20260509_190217.txt`

Lineas relevantes:

```text
# receiver_identity,mac=00:4B:12:96:9A:80,millis=34000
# receiver_identity,mac=00:4B:12:96:9A:80,millis=36000
# receiver_identity,mac=00:4B:12:96:9A:80,millis=38000
# receiver_identity,mac=00:4B:12:96:9A:80,millis=40000
# receiver_identity,mac=00:4B:12:96:9A:80,millis=42000
# receiver_identity,mac=00:4B:12:96:9A:80,millis=44000
# receiver_identity,mac=00:4B:12:96:9A:80,millis=46000
# receiver_identity,mac=00:4B:12:96:9A:80,millis=48000
# receiver_identity,mac=00:4B:12:96:9A:80,millis=50000
# receiver_identity,mac=00:4B:12:96:9A:80,millis=52000
```

## Node Map

`config/kx134_node_map.json` actualizado:

- `sensor_node_1`: sin cambios, calibrado.
- `sensor_node_2`: sin cambios, calibrado.
- `receiver_esp32`: MAC `00:4B:12:96:9A:80`, status `mac_captured_pending_kx134_receiver_firmware`, `receives_from_sensor_ids=[1,2]`, `serial_output_to_pc=true`.

## Restricciones Verificadas

- No se modificaron calibraciones de Sensor 1 o Sensor 2.
- No se modificaron reportes de calibracion.
- No se modifico firmware de sensores.
- No se modifico `firmware/dual_node_espnow`.
- No se modifico GUI.
- No se modifico empaquetado.
- No se modifico data historica.
- No se implemento ESP-NOW dual todavia.
