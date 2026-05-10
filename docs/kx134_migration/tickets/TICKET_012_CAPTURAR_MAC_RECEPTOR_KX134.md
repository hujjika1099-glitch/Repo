# TICKET 012 - Capturar MAC de ESP32 Receptora KX134

## Objetivo

Capturar la MAC real de la tercera ESP32, que sera `receiver_esp32` en la arquitectura
KX134 dual.

## Precondiciones

- Sensor 1 calibrado.
- Sensor 2 calibrado.
- Rama activa: `feature/kx134-dual-capture`.
- Tercera ESP32 conectada por USB.
- No conectar sensores KX134 a esta placa durante este ticket.

## Procedimiento Interactivo

1. Crear firmware minimo `firmware/kx134_receiver_identity`.
2. Compilar con PlatformIO.
3. Pedir al usuario conectar la tercera ESP32.
4. Listar puertos y confirmar COM.
5. Subir firmware de identidad.
6. Monitorear Serial a 921600 baudios.
7. Extraer `receiver_mac`.
8. Actualizar `config/kx134_node_map.json`.

## Criterios de Aceptacion

- Build PlatformIO exitoso.
- Upload exitoso.
- Log Serial contiene:
  - `# firmware=kx134_receiver_identity`
  - `# role=receiver_esp32`
  - `# node_id=receiver_esp32`
  - `# receiver_mac=<MAC>`
  - `# status=READY_FOR_NODE_MAP_CAPTURE`
- `receiver_esp32` queda con MAC real en `config/kx134_node_map.json`.

## Archivos Generados

- `firmware/kx134_receiver_identity/platformio.ini`
- `firmware/kx134_receiver_identity/src/main.cpp`
- `firmware/kx134_receiver_identity/README.md`
- `docs/kx134_migration/RECEIVER_IDENTITY_KX134.md`
- `reports/kx134_test_runs/TICKET_012_RECEIVER_MAC_CAPTURE_SUMMARY.md`
- `reports/kx134_test_runs/TICKET_012_receiver_identity_monitor_<timestamp>.txt`

## Restricciones

- No modificar firmware de sensores.
- No modificar calibraciones.
- No modificar GUI.
- No modificar empaquetado.
- No implementar ESP-NOW dual en este ticket.
