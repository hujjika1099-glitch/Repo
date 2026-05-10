# TICKET 021 - External PC QA summary

## Fecha

2026-05-10

## Contexto

- Rama objetivo: `feature/kx134-dual-capture`.
- Commit base remoto verificado: `2a12912d18921cbb1d7b1d5cd93aea9d865eadda`.
- Entorno local de Codex: carpeta descomprimida del paquete, no repositorio Git local.
- `git` no disponible en PATH en este PC.
- PackageRoot probado: `C:\Users\jogoa\Downloads\Sistema_Captura_Acelerometria_dist\Sistema_Captura_Acelerometria`.
- Exe probado: `C:\Users\jogoa\Downloads\Sistema_Captura_Acelerometria_dist\Sistema_Captura_Acelerometria\Sistema_Captura_Acelerometria.exe`.

## PC externo / entorno distinto

- Hostname: `MOMOTTO_PC`.
- Windows version: `Microsoft Windows 11 Home Single Language`, version `10.0.26200`, build `26200`, `64 bits`.
- Resolucion primaria detectada: `1920x1080`.
- Scaling detectado: `100%` (`LogPixels=96`).

## Smoke del ejecutable

| Prueba | Comando | Resultado |
|---|---|---|
| Launcher smoke | `Sistema_Captura_Acelerometria.exe --smoke --close-after-ms 1000` | PASS, exit code 0 |
| KX134 smoke | `Sistema_Captura_Acelerometria.exe --mode kx134 --smoke --close-after-ms 1000` | PASS, exit code 0 |
| ADXL smoke | `Sistema_Captura_Acelerometria.exe --mode adxl --smoke --close-after-ms 1000` | PASS, exit code 0 |

## Validacion visual

- Ejecutada manualmente por el usuario en el PC externo.
- Resultado: PASS.
- Launcher visible: PASS.
- KX134 visible: PASS.
- ADXL visible: PASS.
- Controles cortados: no se observaron cortes visuales relevantes.
- Pestana Graficas KX134: visible/funcional segun validacion manual.
- Layout usable en resolucion probada: PASS; el usuario reporto que todo se ve correcto.

## Validacion hardware

- Se ejecuto con hardware: no.
- Puerto COM: no aplica.
- Baudrate: no aplica.
- Duracion: no aplica.
- Sensor 1 rows: no aplica.
- Sensor 2 rows: no aplica.
- Effective Hz Sensor 1: no aplica.
- Effective Hz Sensor 2: no aplica.
- Seq gaps: no aplica.
- Invalid lines: no aplica.
- Duplicate keys: no aplica.
- Graficas live con hardware externo: no ejecutado.
- Exportacion hardware externa: no ejecutada.
- Validacion bundle hardware externa: no ejecutada.
- Nota: No se ejecuto captura hardware en el PC externo. La captura hardware real ya fue validada en el PC de desarrollo en TICKET 016 y las graficas live en TICKET 019.

## Problemas detectados

- No se detectaron fallos en smoke automatizado.
- La validacion visual/manual externa fue cerrada como PASS por reporte del usuario.
- La captura hardware externa no se ejecuto; queda documentada como advertencia no bloqueante para este cierre visual, porque la captura/exportacion real ya fue validada previamente en el PC de desarrollo.
- Falta probar scaling 125% y 150%.
- Icono corporativo pendiente desde TICKET 020.
- Firma digital pendiente desde TICKET 020.
- Envio de `sample_rate_hz` al firmware desde GUI sigue pendiente.

## Restricciones verificadas

- Firmware no modificado.
- Calibraciones no modificadas.
- Data historica no modificada.
- ADXL335 preservado.
- `dist/`, `build_work/`, `.venv`, `.exe` y `.zip` no se commitean.

## Decision

`READY_FOR_CLIENT_PROTOTYPE_QA = YES`

Justificacion: el ejecutable del paquete pasa smoke externo para launcher, KX134 y ADXL335 en `MOMOTTO_PC`; ademas, el usuario confirmo validacion visual/manual externa satisfactoria sin cortes relevantes en `1920x1080` con scaling `100%`. La captura hardware externa no se ejecuto y queda como advertencia, no como bloqueo, porque la captura/exportacion real ya fue validada en el PC de desarrollo en TICKET 016 y las graficas live en TICKET 019.
