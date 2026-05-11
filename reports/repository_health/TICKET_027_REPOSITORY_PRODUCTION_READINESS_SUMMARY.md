# TICKET 027 - Repository Production Readiness Summary

## Fecha

2026-05-10

## Commit Base

`b4352f9`

## Objetivo

Dejar el repositorio en estado profesional y coherente con el sistema actual
KX134 dual, preservando ADXL335 como legacy y manteniendo PCB final no
autorizada.

## Cambios Principales

- README raiz reescrito para KX134 dual.
- AGENTS.md actualizado para agentes futuros.
- `docs/README.md` creado como indice general.
- `docs/kx134_migration/INDEX.md` creado como indice tecnico.
- Documentos de estado, arquitectura, operacion, desarrollo, validacion,
  legacy y mantenimiento creados.
- Diagramas Mermaid creados.
- Script guiado de screenshots creado.
- Validador documental `validate_repository_readiness.py` creado.

## Auditoria De Referencias Obsoletas

| Archivo | Referencia | Accion | Estado |
|--------|------------|--------|--------|
| `README.md` anterior | ADXL335 como sistema principal | Reescritura completa | Corregido |
| `AGENTS.md` anterior | ADXL335 como sistema principal | Reescritura completa | Corregido |
| `reports/change_log.md` | ADXL335 historico | Conservar como historial | Permitido |
| `docs/project_master_guide_adxl335_esp32.tex` | ADXL335 historico | Conservar como legado | Permitido |
| `config/kx134_transport_contract_v3.json` | Campos ADXL/mV/g_norm | Conservar como campos prohibidos/deprecated | Permitido |
| `reports/analysis_outputs/` | Capturas ADXL historicas | Conservar como evidencia historica | Permitido |

## Estado KX134

- Dos sensores SEN-17589/KX134 calibrados.
- Dos ESP32 sensoras y una ESP32 receptora identificadas.
- ESP-NOW dual validado.
- GUI KX134 validada con hardware.
- Graficas live validadas.
- Exportacion KX134 CSV/JSON/summary validada.
- Empaquetado Windows preparado.
- QA visual externa aprobada.
- Sesion controlada de prototipo aprobada.

## Estado Baquelada RevA Y PCB

- Baquelada RevA registrada.
- Estado RevA: `under_review`.
- Aceptada para uso de prototipo: NO.
- PCB final autorizada: NO.
- Pruebas fisicas/electricas de RevA quedan fuera del alcance de CODEX y bajo
  responsabilidad experta.

## Screenshots

Estado: `PENDING`.

Motivo: no se ejecuto captura interactiva de ventanas durante el cierre. Se
agrego `tools/kx134/capture_gui_screenshots.ps1` para capturarlas de forma
guiada.

## Diagramas

- `docs/assets/diagrams/kx134_architecture.md`
- `docs/assets/diagrams/kx134_export_flow.md`
- `docs/assets/diagrams/repository_structure.md`

## Validaciones

El validador documental genero:

- `reports/repository_health/TICKET_027_repository_readiness_output.json`
- `pass = true`
- `git_hygiene_pass = true`
- `node_map_pass = true`
- `recommendation = REPOSITORY_PRODUCTION_READY=YES_WITH_SCREENSHOTS_PENDING`

## Advertencias

- Icono corporativo pendiente.
- Firma digital pendiente.
- Scaling Windows 125/150 pendiente.
- `sample_rate_hz` desde GUI hacia firmware pendiente.
- Baquelada RevA no debe energizarse sin pruebas electricas.
- PCB final no autorizada.
