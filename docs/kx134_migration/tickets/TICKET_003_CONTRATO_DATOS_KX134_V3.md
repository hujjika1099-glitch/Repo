# TICKET 003 - Contrato de datos KX134 v3

## Objetivo

Definir el contrato formal de datos para dos sensores SEN-17589/KX134 antes de modificar firmware, GUI o empaquetado.

## Rama

`feature/kx134-dual-capture`

## Entregables

- `config/kx134_transport_contract_v3.json`
- `docs/kx134_migration/DATA_CONTRACT_V3.md`
- `docs/kx134_migration/tickets/TICKET_003_CONTRATO_DATOS_KX134_V3.md`
- Actualizacion de `docs/kx134_migration/TICKET_BACKLOG.md`
- Actualizacion de `reports/change_log.md`

## Restricciones

- No modificar firmware.
- No modificar GUI.
- No modificar empaquetado.
- No modificar scripts funcionales.
- No modificar datos historicos.
- No implementar KX134.
- No implementar calibracion.
- No implementar parser serial.
- No implementar exportacion CSV.
- No crear binarios.

## Criterios de aceptacion

- El archivo JSON existe.
- El JSON es valido.
- El contrato define campos crudos, derivados, metadata y diagnostico.
- El contrato prohibe campos ADXL335 incompatibles.
- El contrato define encabezado CSV KX134.
- El contrato incluye sample rates permitidos: 100, 200, 500, 1000 Hz.
- El contrato define 100 Hz como default.
- El contrato contempla duracion manual futura.
- El contrato contempla calibracion individual.
- El contrato contempla sincronizacion con `sensor_t_us` y `receiver_t_us`.
- No hay cambios funcionales.
- Git queda limpio despues del commit.
- La rama queda publicada en origin si las credenciales lo permiten.

## Estado de cierre

- Estado: completado documentalmente.
- Fecha: 2026-05-08.
- Rama: `feature/kx134-dual-capture`.
- Commit base TICKET 001: `1d31f2abe1cbbfee623ff73a3d889fc83fae98fc`.
- Commit base TICKET 002: `f745fc344bbe8243c43d26bb7ad63d651b28cff8`.
- Cambios funcionales: ninguno.
- Advertencia: antes de implementar firmware debe existir un ticket corto de confirmacion de arquitectura fisica.
