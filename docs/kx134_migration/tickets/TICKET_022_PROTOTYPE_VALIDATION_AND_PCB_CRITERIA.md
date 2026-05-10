# TICKET 022 - Validacion de prototipo y criterios PCB

## Objetivo

Validar el prototipo KX134 dual con una sesion controlada y dejar criterios tecnicos para decidir entrega de prototipo y avance hacia baquelada/PCB.

## Precondiciones

- TICKET 021B aprobado.
- `READY_FOR_CLIENT_PROTOTYPE_QA = YES`.
- Sensor 1, Sensor 2 y receptor validados para GUI/exportacion.
- Ejecutable Windows generado y probado visualmente en PC externo.
- Captura hardware real y graficas live validadas previamente en PC de desarrollo.

## Sesion controlada

Configuracion objetivo:

- Puerto receptor: COM real del receptor, normalmente `COM4`.
- Baudrate: `921600`.
- Duracion: `60 s`.
- Frecuencia esperada: `100 Hz`.
- Rango: `8 g`.
- Nombre de sesion: `ticket022_prototype_controlled`.
- Carpeta controlada: `reports/prototype_validation/TICKET_022_controlled_session_<timestamp>/`.

Secuencia fisica:

1. 10 s sensores quietos.
2. 10 s movimiento suave.
3. 10 s taps suaves/evento comun.
4. 10 s sensores quietos.
5. 10 s movimiento suave adicional.
6. 10 s sensores quietos hasta terminar.

## Criterios de aceptacion

- Ambos sensores presentes.
- Sensor 1 rows >= 5500.
- Sensor 2 rows >= 5500.
- Effective Hz por sensor entre 98 y 102.
- `seq_gaps` por sensor idealmente 0; 1 a 3 advertencia; mas de 3 fallo.
- `invalid_lines = 0` ideal.
- `duplicate_keys = 0` ideal.
- `receiver_t_us` valido.
- `pc_wall_s` positivo.
- CSV KX134 v3 exacto.
- Sin campos ADXL335/mV/g_norm.
- Metadata endurecida valida.
- Summary generado.
- Graficas live confirmadas por observacion.
- Exportacion validada con `validate_kx134_export_bundle.py` y `validate_prototype_session.py`.

## Criterios PCB

`READY_FOR_PCB_DESIGN = YES` requiere sesion controlada aprobada y decisiones fisicas cerradas: alimentacion final, conectores, ubicacion mecanica, longitud de cableado, orientacion de ejes y forma de montaje.

Si esas decisiones fisicas no estan cerradas, la recomendacion tecnica es:

- `READY_FOR_PROTOTYPE_DELIVERY = YES`.
- `READY_FOR_PCB_DESIGN = NO`.

## Restricciones

- No modificar firmware.
- No modificar GUI.
- No modificar calibraciones.
- No modificar empaquetado.
- No modificar data historica.
- No generar archivos de PCB.
- No commitear `dist/`, `build_work/`, `.venv`, `.exe` ni `.zip`.

## Archivos generados

- `docs/kx134_migration/PROTOTYPE_VALIDATION_PLAN.md`
- `docs/kx134_migration/PCB_BAQUELADA_CRITERIA.md`
- `tools/kx134/validate_prototype_session.py`
- `reports/prototype_validation/TICKET_022_PROTOTYPE_VALIDATION_SUMMARY.md`
- `reports/prototype_validation/TICKET_022_prototype_validation_output.json`
- `reports/prototype_validation/TICKET_022_controlled_session_<timestamp>/`

## Decision final

La decision final se documenta en el reporte del ticket:

- `READY_FOR_PROTOTYPE_DELIVERY = YES/NO/PENDING`.
- `READY_FOR_PCB_DESIGN = YES/NO/PENDING`.
