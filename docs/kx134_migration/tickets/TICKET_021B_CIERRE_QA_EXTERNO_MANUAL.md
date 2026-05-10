# TICKET 021B - Cierre QA externo visual/manual

## Objetivo

Cerrar formalmente la validacion visual/manual externa del ejecutable Windows `Sistema_Captura_Acelerometria.exe`, usando la evidencia reportada por el usuario despues de ejecutar el paquete en un PC externo.

## Contexto

El TICKET 021 dejo la decision `READY_FOR_CLIENT_PROTOTYPE_QA = PENDING` porque CODEX no podia inspeccionar visualmente la GUI ni ejecutar una captura hardware en el PC externo.

Posteriormente, el usuario ejecuto la QA manual externa con el ZIP del ejecutable y reporto:

- El ejecutable abre.
- El launcher funciona.
- La GUI KX134 se ve bien.
- La GUI ADXL335 historica se ve bien.
- No se observaron cortes visuales relevantes.
- El resultado visual general fue satisfactorio.

El smoke automatizado externo ya habia pasado:

- Launcher smoke: PASS.
- KX134 smoke: PASS.
- ADXL smoke: PASS.

## PC externo reportado

- Windows: Windows 11 Home Single Language 10.0.26200 build 26200, 64 bits.
- Resolucion: 1920x1080.
- Scaling: 100%.
- PackageRoot: `C:\Users\jogoa\Downloads\Sistema_Captura_Acelerometria_dist\Sistema_Captura_Acelerometria`.
- Exe: `Sistema_Captura_Acelerometria.exe`.

## Smoke vs validacion visual manual

El smoke automatizado confirma que los entrypoints del ejecutable arrancan y cierran sin error.

La validacion visual manual confirma que las ventanas principales son usables en el PC externo probado y que no se observaron cortes relevantes en launcher, modo KX134 ni modo ADXL335.

## Hardware externo

No se ejecuto captura hardware en el PC externo.

Esto queda como advertencia no bloqueante para el cierre visual externo, porque la captura real con hardware desde la GUI ya fue validada previamente en el PC de desarrollo en TICKET 016, y las graficas live KX134 fueron validadas con hardware en TICKET 019.

## Decision

`READY_FOR_CLIENT_PROTOTYPE_QA = YES`

## Restricciones

- Firmware no modificado.
- Calibraciones no modificadas.
- GUI no modificada.
- Empaquetado no modificado.
- Data historica no modificada.
- `dist/`, `build_work/`, `.venv`, `.exe` y `.zip` no se commitean.

## Archivos modificados

- `reports/kx134_gui_validation/TICKET_021_EXTERNAL_PC_QA_SUMMARY.md`
- `reports/kx134_gui_validation/TICKET_021_external_pc_qa_output.json`
- `config/kx134_node_map.json`
- `docs/kx134_migration/TICKET_BACKLOG.md`
- `reports/change_log.md`
- `docs/kx134_migration/tickets/TICKET_021B_CIERRE_QA_EXTERNO_MANUAL.md`

## Siguiente paso recomendado

TICKET 022 - Validacion de prototipo con sesion controlada y criterios para entrega/baquelada.
