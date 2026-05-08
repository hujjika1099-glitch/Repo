# TICKET 004 - Cerrar arquitectura fisica KX134

## Objetivo

Cerrar documentalmente la arquitectura fisica para la migracion KX134/SEN-17589.

## Decision cerrada

La arquitectura usara tres ESP32 totales:

- ESP32 sensora 1 para `sensor_id=1`.
- ESP32 sensora 2 para `sensor_id=2`.
- ESP32 receptora para recibir por ESP-NOW y transmitir a la aplicacion por Serial USB.

## Rama

`feature/kx134-dual-capture`

## Entregables

- `docs/kx134_migration/ARCHITECTURE_V1.md`
- `config/kx134_node_map_template.json`
- Actualizacion de `config/kx134_transport_contract_v3.json`
- Actualizacion de `docs/kx134_migration/DATA_CONTRACT_V3.md`
- Actualizacion de `docs/kx134_migration/REQUIREMENTS_BASELINE.md`
- Actualizacion de `docs/kx134_migration/TICKET_BACKLOG.md`
- Actualizacion de `reports/change_log.md`

## Restricciones

- No modificar firmware.
- No modificar GUI.
- No modificar empaquetado.
- No modificar scripts funcionales.
- No modificar datos historicos.
- No implementar KX134.
- No implementar ESP-NOW nuevo.
- No implementar calibracion.
- No implementar parser serial.
- No crear binarios.

## Criterios de aceptacion

- La arquitectura de tres ESP32 queda documentada.
- El contrato KX134 v3 deja de mostrar la arquitectura ESP32 como pendiente.
- La plantilla de mapeo de nodos existe y es JSON valido.
- El contrato KX134 v3 sigue siendo JSON valido.
- Se conserva ESP-NOW desde nodos sensores hacia receptor.
- Se conserva Serial USB desde receptor hacia aplicacion.
- No hay cambios funcionales.
- Git queda limpio despues del commit.
- La rama queda publicada en origin si las credenciales lo permiten.

## Estado de cierre

- Estado: completado documentalmente.
- Fecha: 2026-05-08.
- Rama: `feature/kx134-dual-capture`.
- Commit base TICKET 003: `987ade22e0e64d1cb3f6369a0dca612a51580cc8`.
- Cambios funcionales: ninguno.
