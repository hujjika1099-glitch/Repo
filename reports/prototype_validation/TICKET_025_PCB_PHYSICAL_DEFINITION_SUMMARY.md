# TICKET 025 - PCB physical definition summary

## Fecha

2026-05-10

## Decision

- `PCB_PHYSICAL_DECISIONS_COMPLETE = NO`
- `PCB_DESIGN_AUTHORIZED = NO`

## Contexto

El prototipo KX134 dual esta listo para entrega funcional, con documentacion cliente completa y validacion de sesion controlada. La PCB/baquelada sigue bloqueada porque faltan decisiones fisicas y mecanicas criticas.

## Decisiones cerradas

- Mantener arquitectura de tres ESP32: Sensor 1, Sensor 2 y Receptor.
- Mantener configuracion validada `100 Hz`, `odr_hz=100`, `range_g=8`.
- Mantener receptor USB Serial a `921600` en prototipo.
- Mantener identidades MAC y calibraciones existentes.

## Decisiones pendientes

- Alimentacion final.
- Tension y corriente objetivo.
- Proteccion contra inversion/sobrecorriente.
- Conectores finales.
- Qwiic/I2C cableado vs soldado/integrado a PCB.
- Longitudes de cable Sensor 1, Sensor 2 y receptor-PC.
- Alivio de tension.
- Montaje mecanico.
- Caja/carcasa.
- Orientacion X/Y/Z de Sensor 1 y Sensor 2.
- Ubicacion de sensores y receptor.
- Acceso a USB/BOOT/EN.
- Dimensiones, portabilidad y restricciones del cliente.
- Ambiente: polvo, humedad, golpes, vibracion y temperatura.

## Blockers

- `final_power_source_not_defined`
- `target_voltage_current_not_defined`
- `power_protection_not_defined`
- `sensor_connectors_not_defined`
- `qwiic_or_direct_pcb_not_defined`
- `final_cable_lengths_not_defined`
- `strain_relief_not_defined`
- `mechanical_mounting_not_defined`
- `enclosure_not_defined`
- `axis_orientation_not_defined`
- `receiver_and_sensor_locations_not_defined`
- `service_access_not_defined`
- `client_dimensions_constraints_not_defined`
- `environmental_requirements_not_defined`

## Riesgos

- Intercambio fisico accidental de sensores.
- Cable I2C excesivo o flojo.
- Alimentacion inestable.
- Orientacion de ejes sin marcar.
- Recalibracion omitida tras cambio fisico.
- Acceso a servicio bloqueado.
- Montaje mecanico que altere medicion.
- Ambiente con golpes/humedad/polvo sin caja definida.

## Resultado del validador

Salida: `reports/prototype_validation/TICKET_025_pcb_physical_decisions_output.json`.

El validador permite cerrar documentalmente el ticket con `validation_pass=true`, pero confirma `pcb_design_authorized=false` por decisiones criticas pendientes.

## Proximo paso

TICKET 026 - Cierre de decisiones fisicas pendientes para PCB o reunion/levantamiento fisico con cliente.

## Restricciones verificadas

- Firmware no modificado.
- GUI no modificada.
- Calibraciones no modificadas.
- Empaquetado no modificado.
- Data historica no modificada.
- No se generaron archivos PCB, esquematicos, Gerber ni BOM final.
