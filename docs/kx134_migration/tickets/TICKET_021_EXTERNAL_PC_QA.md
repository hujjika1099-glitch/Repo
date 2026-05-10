# TICKET 021 - QA externo del ejecutable Windows

## Objetivo

Validar `Sistema_Captura_Acelerometria_dist.zip` en un PC externo o en un entorno distinto al PC de desarrollo.

## Precondiciones

- TICKET 020 aprobado.
- Paquete local existente:
  - `dist\Sistema_Captura_Acelerometria_dist.zip`
- Firmware y calibraciones congelados para este ticket.
- No commitear `dist/`, `build_work/`, `.venv`, `.exe` ni `.zip`.

## Archivos del paquete

- `Sistema_Captura_Acelerometria.exe`
- Carpeta `_internal` de PyInstaller.
- Configuracion KX134 incluida en `_internal\config\`.

## Procedimiento sin hardware

1. Descomprimir el ZIP en una ruta simple, por ejemplo:
   - `C:\UQ_KX134_QA\Sistema_Captura_Acelerometria\`
2. Ejecutar:
   - `Sistema_Captura_Acelerometria.exe`
3. Verificar launcher.
4. Abrir KX134.
5. Abrir ADXL335 historico.
6. Revisar resolucion, scaling y cortes visuales.
7. Ejecutar smoke:
   - `tools\kx134\external_pc_qa.ps1 -PackageRoot "<PackageRoot>"`

## Procedimiento con hardware

1. Conectar receptor ESP32 al PC externo.
2. Alimentar Sensor 1 y Sensor 2.
3. Identificar puerto COM.
4. Abrir KX134.
5. Configurar 921600 baud, 100 Hz esperado y 10-20 s.
6. Capturar.
7. Confirmar datos en Sensor 1 y Sensor 2.
8. Confirmar graficas live y taps suaves.
9. Copiar artefactos exportados de vuelta a `reports/kx134_gui_validation/TICKET_021_external_hw_capture_<timestamp>/`.
10. Validar bundle con `tools/kx134/validate_kx134_export_bundle.py`.

## Criterios de aceptacion

- Launcher smoke pass.
- KX134 smoke pass.
- ADXL smoke pass.
- Visual layout pass en PC externo.
- Hardware capture pass si hay hardware disponible.
- Export validation pass si hay captura hardware.

## Restricciones

- Firmware no modificado.
- Calibraciones no modificadas.
- Data historica no modificada.
- Sin dependencias globales.
- Sin cambios de PATH.
- Sin commit de binarios.

## Reportes esperados

- `reports/kx134_gui_validation/TICKET_021_external_pc_qa_output.json`
- `reports/kx134_gui_validation/TICKET_021_EXTERNAL_PC_QA_SUMMARY.md`

## Decision

Si no se ejecuta en PC externo, el estado debe quedar `READY_FOR_CLIENT_PROTOTYPE_QA=PENDING`.
