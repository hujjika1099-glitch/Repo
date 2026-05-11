# Mantenimiento Del Repositorio

## Que Se Commitea

- Codigo fuente permitido por ticket.
- Documentacion Markdown.
- Configuracion documental JSON.
- Reportes de validacion.
- Herramientas de validacion.
- Artefactos pequenos de evidencia cuando el ticket lo autoriza.

## Que No Se Commitea

- `dist/`
- `build_work/`
- `.venv/`
- `.exe`
- `.zip`
- Data runtime generada por capturas.
- Archivos PCB finales, Gerbers o BOM sin ticket explicito.

## Change Log

Todo cambio relevante debe agregar una entrada a `reports/change_log.md` con:

- fecha;
- rama/ticket;
- archivos afectados;
- motivo;
- impacto;
- restricciones respetadas.

## README Y Documentacion

Actualizar README cuando cambie:

- estado del prototipo;
- ejecutable;
- flujo operativo principal;
- decision PCB;
- ubicacion de documentos principales.

No dejar documentos principales describiendo ADXL335 como flujo actual.

## Nuevas Validaciones

Toda nueva validacion debe indicar:

- herramienta usada;
- hardware usado;
- puerto/baudrate si aplica;
- archivos generados;
- decision formal;
- restricciones verificadas.

## Capturas Grandes

Las capturas crudas o datos extensos deben mantenerse fuera de git salvo que un
ticket lo autorice explicitamente. Preferir reportes resumidos y JSON de
validacion.
