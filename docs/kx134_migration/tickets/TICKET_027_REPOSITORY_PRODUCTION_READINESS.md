# TICKET 027 - Repository Production Readiness

## Objetivo

Profesionalizar la entrada documental del repositorio para que el sistema actual
se entienda como KX134 dual, con ADXL335 preservado solo como legacy.

## Precondiciones

- TICKET 024 aprobado: documentacion cliente lista.
- TICKET 025 aprobado documentalmente: PCB sigue bloqueada.
- TICKET 026 aprobado: baquelada RevA registrada bajo revision.
- `PCB_DESIGN_AUTHORIZED = NO`.

## Auditoria De Documentacion Obsoleta

Se ejecuto busqueda de referencias ADXL335/analogicas en README, AGENTS, docs,
reports y config. Los hallazgos principales fueron:

| Archivo | Referencia | Accion | Estado |
|--------|------------|--------|--------|
| `README.md` anterior | ADXL335 como titulo y flujo principal | Reescrito a KX134 dual | Corregido |
| `AGENTS.md` anterior | ADXL335 como sistema operativo principal | Reescrito a guia actual KX134 | Corregido |
| `reports/change_log.md` | Entradas historicas ADXL335 | Mantener como historial | Permitido |
| `docs/project_master_guide_adxl335_esp32.tex` | Guia historica ADXL335 | Mantener como legacy | Permitido |
| `config/kx134_transport_contract_v3.json` | Campos prohibidos ADXL/mV en contrato | Mantener como lista de rechazo | Permitido |
| `reports/analysis_outputs/` | Capturas y analisis historicos ADXL335 | Mantener como evidencia historica | Permitido |

## Cambios Realizados

- README raiz reescrito como entrada profesional KX134.
- AGENTS.md actualizado para agentes futuros.
- Indices y documentos tecnicos KX134 agregados.
- Diagramas Mermaid agregados en `docs/assets/diagrams/`.
- Script de screenshots guiado agregado.
- Validador de readiness documental agregado.
- Node map actualizado con estado de repositorio profesionalizado.

## Screenshots

La captura automatica no se ejecuto en este cierre. Queda
`screenshots_status = PENDING` y se agrega script guiado para que un operador
capture launcher, pestanas KX134 y ADXL legacy sin herramientas externas.

## Validaciones

Validaciones esperadas del ticket:

- `python -m py_compile tools\kx134\validate_repository_readiness.py`
- `python tools\kx134\validate_repository_readiness.py --output reports\repository_health\TICKET_027_repository_readiness_output.json`
- `python -m json.tool reports\repository_health\TICKET_027_repository_readiness_output.json`
- `python -m json.tool config\kx134_node_map.json`
- pruebas unitarias KX134/app launcher;
- `git diff --check`;
- verificaciones de rutas restringidas.

## Restricciones

No se modifica firmware, GUI funcional, calibraciones, empaquetado funcional,
data historica, binarios, Gerbers, BOM ni archivos PCB finales.

## Resultado Final

- `REPOSITORY_PRODUCTION_READY = YES_WITH_SCREENSHOTS_PENDING`
- `PCB_DESIGN_AUTHORIZED = NO`

## Siguiente Paso Recomendado

TICKET 028 - Cierre fisico de baquelada RevA por experto y registro de
resultados: continuidad, shorts, escala/mirror y power-on sin sensor.
