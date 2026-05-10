# TICKET 021 - External PC QA summary

## Fecha

2026-05-10

## Estado

`READY_FOR_CLIENT_PROTOTYPE_QA=PENDING`

CODEX se ejecuto en el PC de desarrollo, no en un PC externo. Por esa razon este ticket deja checklist, scripts y una corrida de referencia local, pero no marca la QA externa como validada.

## Paquete base

- Producto: `Sistema de Captura de Acelerometria`.
- ZIP local: `dist\Sistema_Captura_Acelerometria_dist.zip`.
- Exe local: `dist\Sistema_Captura_Acelerometria\Sistema_Captura_Acelerometria.exe`.
- Commit base: `2a12912`.

## Preparacion generada

- Checklist: `docs/kx134_migration/EXTERNAL_PC_QA_CHECKLIST.md`.
- Script PowerShell: `tools/kx134/external_pc_qa.ps1`.
- Validador Python: `tools/kx134/external_pc_qa_check.py`.
- Ticket doc: `docs/kx134_migration/tickets/TICKET_021_EXTERNAL_PC_QA.md`.

## Corrida de referencia en PC de desarrollo

- Hostname: `JOSECILLO`.
- Windows version: `Microsoft Windows NT 10.0.26200.0`.
- Resolucion: `1920x1080`.
- Scaling: `100%`.
- PackageRoot usado: `dist\Sistema_Captura_Acelerometria`.
- Launcher smoke: `pass`.
- KX134 smoke: `pass`.
- ADXL smoke: `pass`.
- Visual manual externo: `not_recorded`.
- Hardware externo: `not_run`.
- Exportacion externa: `not_run`.

Output: `reports/kx134_gui_validation/TICKET_021_external_pc_qa_output.json`.

## QA externa pendiente

Para cerrar el ticket como validado se debe ejecutar en otro PC:

1. Copiar `dist\Sistema_Captura_Acelerometria_dist.zip`.
2. Descomprimir en ruta simple.
3. Ejecutar `tools\kx134\external_pc_qa.ps1` contra el PackageRoot descomprimido.
4. Confirmar visualmente launcher, KX134 y ADXL.
5. Si hay hardware, ejecutar captura KX134 y validar exportacion.

## Node map

No se actualiza a `external_pc_qa_validated_pending_prototype_validation` porque no hay evidencia de PC externo todavia.

Status actual esperado:

`windows_packaging_prepared_pending_external_pc_qa`

## Restricciones

- Firmware no modificado.
- Calibraciones no modificadas.
- Data historica no modificada.
- `dist/`, `build_work/`, `.venv`, `.exe` y `.zip` no se commitean.
- ADXL335 preservado.

## Decision

`READY_FOR_CLIENT_PROTOTYPE_QA=PENDING`
