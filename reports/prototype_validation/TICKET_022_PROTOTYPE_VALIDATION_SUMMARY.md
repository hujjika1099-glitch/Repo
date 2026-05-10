# TICKET 022 - Prototype validation summary

## Fecha

2026-05-10

## Commit base

`db47434` - `test: close external Windows QA visual validation`

## Contexto

Validacion de prototipo KX134 dual con sesion controlada de 60 s, usando la GUI KX134 desde Python para poder fijar una carpeta de salida controlada dentro de `reports/prototype_validation/`.

El ejecutable empaquetado existe localmente y ya fue validado en TICKET 020/021B; para esta captura se uso Python porque el launcher frozen no expone `--repo-root` hacia KX134 y se queria evitar que la evidencia principal quedara dentro de `dist/`.

## Configuracion

- PC usado: PC de desarrollo.
- Modo usado: Python GUI KX134.
- Puerto COM: `COM4`.
- Baudrate: `921600`.
- Duracion configurada: `60 s`.
- Frecuencia esperada: `100 Hz`.
- Rango esperado: `8 g`.
- Session name: `ticket022_prototype_controlled`.
- Carpeta de salida: `reports/prototype_validation/TICKET_022_controlled_session_20260510_162258/`.

## Secuencia controlada

- Sensores quietos.
- Movimiento suave.
- Taps/evento comun suave.
- Sensores quietos.
- Movimiento suave adicional.
- Sensores quietos hasta finalizar.

## Artefactos

- CSV raw: `reports/prototype_validation/TICKET_022_controlled_session_20260510_162258/data/raw/kx134_dual_live/kx134_dual_live_ticket022_prototype_controlled_20260510_162412_raw.csv`
- Session JSON: `reports/prototype_validation/TICKET_022_controlled_session_20260510_162258/data/processed/kx134_dual_live/kx134_dual_live_ticket022_prototype_controlled_20260510_162412_session.json`
- Summary MD: `reports/prototype_validation/TICKET_022_controlled_session_20260510_162258/reports/analysis_outputs/kx134_dual_live/kx134_dual_live_ticket022_prototype_controlled_20260510_162412_summary.md`
- Prototype validation JSON: `reports/prototype_validation/TICKET_022_prototype_validation_output.json`
- Export bundle validation JSON: `reports/prototype_validation/TICKET_022_controlled_session_20260510_162258/TICKET_022_export_bundle_validation_output.json`

## Resultados

| Metrica | Sensor 1 | Sensor 2 |
|---|---:|---:|
| Rows | 5998 | 6000 |
| Effective Hz | 99.966656 | 100.000007 |
| Seq gaps | 2 | 0 |
| Timestamp errors | 0 | 0 |
| Receiver timestamp errors | 0 | 0 |
| Duplicate keys | 0 | 0 |

Metricas globales:

- Invalid lines: `0`.
- `pc_wall_s` positivo: `true`.
- `receiver_t_us` valido: `true`.
- Packet status counts: `{"OK": 11998}`.
- Packet error code counts: `{"OK": 11998}`.
- Campos prohibidos detectados: `false`.
- CSV KX134 v3 exacto: `true`.
- Metadata schema pass: `true`.
- Rutas de artefactos presentes: `true`.

## Graficas y eventos

- Graficas live confirmadas: `true`.
- Taps/eventos observados: `true`.
- GUI congelada: intento previo con sospecha de congelamiento; la corrida final exporto correctamente. Queda como advertencia para revisar en QA posterior si se repite.
- Observacion del usuario: inicialmente vio todo bien y solicito repetir para asegurar; luego reporto sospecha de congelamiento en un intento intermedio.

## Validacion

- `validate_kx134_export_bundle.py`: PASS con advertencia `sensor_1:seq_gaps:2`.
- `validate_prototype_session.py`: PASS con advertencia `sensor_1:seq_gaps:2`.

La GUI genero un summary interno con `decision: FAIL` por `sensor_1_seq_gaps`. Ese criterio interno es mas estricto que el criterio del TICKET 022, donde 1 a 3 gaps se documentan como advertencia no bloqueante. Por eso la decision formal de este ticket usa el validador de prototipo y conserva el summary original sin editar.

## Criterios PCB

`READY_FOR_PCB_DESIGN = NO`

Blockers:

- Fuente de alimentacion final no definida.
- Conectores finales para sensores no definidos.
- Longitudes finales de cable no definidas.
- Montaje mecanico final no definido.
- Orientacion fisica de ejes en carcasa/PCB no definida.
- Ubicacion final de receptor y nodos sensores no definida.

## Decision

- `READY_FOR_PROTOTYPE_DELIVERY = YES`
- `READY_FOR_PCB_DESIGN = NO`

Justificacion: la sesion controlada cumple filas, frecuencia, timestamps, ausencia de duplicados, ausencia de lineas invalidas, ausencia de campos prohibidos, metadata endurecida y exportacion validada. El prototipo puede entregarse como prototipo funcional con advertencia por `2` seq gaps en Sensor 1 y seguimiento de posible congelamiento visual. El diseno PCB queda bloqueado hasta cerrar decisiones fisicas/mecanicas.

## Restricciones

- Firmware no modificado.
- GUI no modificada.
- Calibraciones no modificadas.
- Empaquetado no modificado.
- Data historica no modificada.
- `dist/`, `build_work/`, `.venv`, `.exe` y `.zip` no se commitean.

## Proximos pasos

- TICKET 023 - Consolidar entrega tecnica del prototipo y documentacion final para cliente.
- Cerrar decisiones fisicas antes de PCB/baquelada.
- Probar scaling 125/150%.
- Definir icono/firma digital si se requiere.
- Evaluar envio de `sample_rate_hz` al firmware si se decide soportar frecuencias distintas.
