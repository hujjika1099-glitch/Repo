# TICKET 023 - Prototype delivery summary

## Fecha

2026-05-10

## Commit base

`8a1d983` - `test: validate KX134 prototype controlled session`

## Decision

- `PROTOTYPE_DELIVERY_PACKAGE_READY = YES`
- `PCB_DESIGN_AUTHORIZED = NO`

## Resumen de estado

El prototipo KX134 dual esta listo para entrega funcional: los dos sensores KX134 estan calibrados, la arquitectura dual ESP-NOW fue validada, la GUI KX134 captura ambos sensores, las graficas live funcionan, la exportacion CSV/JSON/summary es auditable y el ejecutable Windows fue generado y validado visualmente en un PC externo.

La PCB/baquelada no queda autorizada porque faltan decisiones fisicas y mecanicas: alimentacion, conectores, longitudes de cable, montaje, orientacion de ejes y ubicacion final de receptor/nodos sensores.

## Metricas TICKET 022

- Sensor 1 rows: `5998`.
- Sensor 2 rows: `6000`.
- Effective Hz Sensor 1: `99.966656`.
- Effective Hz Sensor 2: `100.000007`.
- Seq gaps Sensor 1: `2` advertencia no bloqueante.
- Seq gaps Sensor 2: `0`.
- Invalid lines: `0`.
- Duplicate keys: `0`.
- `pc_wall_s` positivo: `true`.
- `receiver_t_us` valido: `true`.
- Packet status: `OK`.
- Packet error code: `OK`.
- Campos prohibidos detectados: `false`.
- Graficas live confirmadas: `true`.

## Correccion semantica PCB

El output historico de TICKET 022 tenia una recomendacion PCB tecnica incompleta. En este ticket se corrige la semantica:

- `ready_for_pcb_design_technical_capture_recommendation = true`
- `ready_for_pcb_design_final_recommendation = false`
- `PCB_DESIGN_AUTHORIZED = NO`

## Documentacion generada

- `docs/kx134_migration/PROTOTYPE_DELIVERY_PACKAGE.md`
- `docs/kx134_migration/TECHNICAL_STATUS_SUMMARY.md`
- `docs/kx134_migration/VALIDATION_EVIDENCE_MATRIX.md`
- `docs/kx134_migration/OPEN_ITEMS_AND_RISKS.md`
- `docs/kx134_migration/tickets/TICKET_023_PROTOTYPE_DELIVERY_PACKAGE.md`

## Proximo ticket recomendado

Opcion A: `TICKET 024 - Documentacion de usuario/cliente y guia de operacion`.

Opcion B: `TICKET 024 - Definicion fisica para PCB/baquelada: alimentacion, conectores, montaje y orientacion`.

## Restricciones

- Firmware no modificado.
- GUI no modificada.
- Calibraciones no modificadas.
- Empaquetado no modificado.
- Data historica no modificada.
- `dist/`, `build_work/`, `.venv`, `.exe` y `.zip` no se commitean.
