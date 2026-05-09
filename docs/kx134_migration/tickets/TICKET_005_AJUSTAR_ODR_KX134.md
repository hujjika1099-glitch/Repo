# TICKET 005 - Ajustar ODR KX134

## Objetivo

Corregir las frecuencias configurables del sistema KX134 para que coincidan con las opciones ODR seleccionadas para el proyecto.

## Decision

Las frecuencias permitidas seran:

- 100 Hz.
- 200 Hz.
- 400 Hz.
- 800 Hz.

Se eliminan como opciones configurables:

- 500 Hz.
- 1000 Hz.

El default sigue siendo:

- 100 Hz.

## Motivo

La tabla ODR del KX134 usa valores discretos. Para esta fase se adoptan 100, 200, 400 y 800 Hz. La opcion 800 Hz debe validarse en firmware porque puede requerir modo High-Performance segun la configuracion de la libreria.

## Rama

`feature/kx134-dual-capture`

## Entregables

- Actualizacion de `config/kx134_transport_contract_v3.json`.
- Actualizacion de `config/kx134_node_map_template.json`.
- Actualizacion de `docs/kx134_migration/DATA_CONTRACT_V3.md`.
- Actualizacion de `docs/kx134_migration/ARCHITECTURE_V1.md`.
- Actualizacion de `docs/kx134_migration/REQUIREMENTS_BASELINE.md`.
- Actualizacion de `docs/kx134_migration/TICKET_BACKLOG.md`.
- Actualizacion de `reports/change_log.md`.

## Restricciones

- No modificar firmware.
- No modificar GUI.
- No modificar empaquetado.
- No modificar scripts funcionales.
- No modificar datos historicos.
- No implementar KX134.
- No implementar ESP-NOW.
- No implementar calibracion.
- No crear binarios.

## Criterios de aceptacion

- El contrato KX134 v3 permite solo 100, 200, 400 y 800 Hz.
- La plantilla de nodos permite solo 100, 200, 400 y 800 Hz.
- La documentacion de arquitectura indica solo 100, 200, 400 y 800 Hz.
- La documentacion de requisitos indica solo 100, 200, 400 y 800 Hz.
- La documentacion del contrato indica solo 100, 200, 400 y 800 Hz.
- 100 Hz sigue siendo default.
- 500 Hz y 1000 Hz ya no aparecen como opciones permitidas actuales.
- Se documenta que 800 Hz debe validarse en firmware y puede requerir modo High-Performance.
- No hay cambios funcionales.
- Git queda limpio despues del commit.
- La rama queda publicada en origin si las credenciales lo permiten.

## Estado de cierre

- Estado: completado documentalmente.
- Fecha: 2026-05-09.
- Rama: `feature/kx134-dual-capture`.
- Commit base TICKET 004: `6c97d5ef0cf3e9b416f54ece88ae17fa91452500`.
- Cambios funcionales: ninguno.
