# TICKET 026 - Registro y revision de Baquelada RevA

## Objetivo

Registrar los artefactos de baquelada/PCB RevA creados en Proteus, revisar visualmente PDF/SVG, documentar riesgos y preparar pruebas de continuidad y energizacion antes de declarar la placa usable.

## Precondiciones

- TICKET 025 aprobado.
- `PROTOTYPE_DELIVERY_PACKAGE_READY = YES`.
- `PCB_PHYSICAL_DECISIONS_COMPLETE = NO`.
- `PCB_DESIGN_AUTHORIZED = NO`.
- El usuario reporto archivos externos `Maestria.PDF` y `Maestria.SVG`.

## Artefactos registrados

- `hardware/pcb/baquelada_revA/artifacts/Maestria.PDF`
- `hardware/pcb/baquelada_revA/artifacts/Maestria.SVG`

Proyecto Proteus y librerias/footprints: `PENDING`.

Rol confirmado por el usuario:

- baquela para nodo sensor KX134;
- misma RevA repetida para Sensor 1 y Sensor 2;
- receptor sin baquela, conectado directamente al PC.

## Revision visual

Resultado: `PASS_WITH_WARNINGS`.

Motivo:

- Hay PDF/SVG exportado por Proteus.
- Se detectan dimensiones desde SVG.
- No hay netlist ni DRC.
- No se confirmo escala 1:1.
- No se confirmo mirror/orientacion de capa.
- No se confirmo pinout.
- No se hizo continuidad con multimetro.

## Restricciones

- No se modifica firmware.
- No se modifica GUI.
- No se modifican calibraciones.
- No se modifica empaquetado.
- No se modifica data historica.
- No se generan Gerbers finales.
- No se crea BOM final.
- No se autoriza PCB final.

## Criterios de aceptacion futura

La baquelada RevA solo puede considerarse usable para prototipo si:

- escala 1:1 confirmada;
- mirror/cara de cobre confirmada;
- pinout confirmado;
- continuidad aprobada;
- sin corto 3V3-GND;
- power-on sin sensor aprobado;
- prueba single-node aprobada si es placa de nodo sensor;
- prueba dual aprobada si aplica.

## Decision final

- `BAQUELADA_REVA_REGISTERED = YES`
- `BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = NO`
- `PCB_DESIGN_AUTHORIZED = NO`

## Siguiente prueba

TICKET 027 - Prueba electrica de baquelada RevA: continuidad, shorts, escala/mirror y power-on sin sensor.
