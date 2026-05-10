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

- Launcher visible: pendiente de confirmacion manual.
- KX134 visible: pendiente de confirmacion manual.
- ADXL visible: pendiente de confirmacion manual.
- Controles cortados: pendiente de confirmacion manual.
- Pestana Graficas visible: pendiente de confirmacion manual.
- Layout usable en resolucion probada: pendiente de confirmacion manual.

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
- Graficas live: pendiente.
- Exportacion: pendiente.
- Validacion bundle: pendiente.

## Problemas detectados

- No se detectaron fallos en smoke automatizado.
- Falta validacion visual/manual completa.
- Falta captura hardware externa y validacion de exportacion si el hardware esta disponible.
- Falta probar scaling 125% y 150%.
- Icono corporativo pendiente desde TICKET 020.
- Firma digital pendiente desde TICKET 020.

## Restricciones verificadas

- Firmware no modificado.
- Calibraciones no modificadas.
- Data historica no modificada.
- ADXL335 preservado.
- `dist/`, `build_work/`, `.venv`, `.exe` y `.zip` no se commitean.

## Decision

`READY_FOR_CLIENT_PROTOTYPE_QA = PENDING`

Justificacion: el ejecutable del paquete abre correctamente en smoke para launcher, KX134 y ADXL335 en un entorno distinto al PC de desarrollo reportado, pero aun faltan validacion visual/manual completa y captura hardware/exportacion externa.
