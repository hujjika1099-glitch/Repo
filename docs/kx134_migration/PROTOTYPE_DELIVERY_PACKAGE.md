# Paquete de entrega tecnica del prototipo KX134 dual

## Decision

- `PROTOTYPE_DELIVERY_PACKAGE_READY = YES`
- `PCB_DESIGN_AUTHORIZED = NO`

## Que se entrega como prototipo

- Firmware KX134 dual ESP-NOW.
- Dos sensores SparkFun SEN-17589/KX134 calibrados.
- Tres ESP32 identificadas: Sensor 1, Sensor 2 y receptor.
- Receptor ESP-NOW a Serial USB.
- Aplicacion Windows empaquetada como `Sistema_Captura_Acelerometria.exe`.
- GUI KX134 con graficas en vivo.
- Flujo ADXL335 historico preservado.
- Exportacion CSV/JSON/summary auditable para KX134 v3.
- Documentacion de calibracion y validacion.
- Criterios para avanzar a PCB/baquelada.

## Que no se entrega todavia

- PCB/baquelada final.
- Firma digital del ejecutable.
- Icono corporativo final.
- Configuracion remota de `sample_rate_hz` desde GUI hacia firmware.
- Validacion externa con hardware en otro PC.
- Validacion visual en scaling Windows 125% y 150%.

## Configuracion validada

- `sample_rate_hz`: 100.
- `odr_hz`: 100.
- `range_g`: 8.
- Baudrate: 921600.
- ESP-NOW channel: 1.
- Sensor 1 MAC: `D4:E9:F4:E9:8E:1C`.
- Sensor 2 MAC: `D4:E9:F4:C3:37:14`.
- Receptor MAC: `00:4B:12:96:9A:80`.

## Resultado de sesion controlada

Sesion: `reports/prototype_validation/TICKET_022_controlled_session_20260510_162258/`

| Metrica | Sensor 1 | Sensor 2 |
|---|---:|---:|
| Rows | 5998 | 6000 |
| Effective Hz | 99.966656 | 100.000007 |
| Seq gaps | 2 | 0 |
| Duplicate keys | 0 | 0 |

Resultados globales:

- `invalid_lines`: 0.
- `pc_wall_s` positivo: true.
- `receiver_t_us` valido: true.
- `packet_status`: OK.
- `packet_error_code`: OK.
- Campos prohibidos detectados: false.
- Graficas live confirmadas: true.
- Taps/eventos observados: true.
- Exportacion validada: true.

## Advertencias

- Sensor 1 tuvo 2 `seq_gaps`; es advertencia no bloqueante segun TICKET 022.
- Hubo sospecha de congelamiento visual en un intento previo; la corrida final exporto correctamente.
- La PCB queda bloqueada por decisiones fisicas/mecanicas.
- Hardware externo no se probo con captura; la captura con hardware ya fue validada en PC de desarrollo.

## Proximo paso

Elegir uno de dos caminos:

- TICKET 024 - Documentacion de usuario/cliente y guia de operacion.
- TICKET 024 - Definicion fisica para PCB/baquelada: alimentacion, conectores, montaje y orientacion.
