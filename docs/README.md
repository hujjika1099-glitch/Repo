# Documentacion Del Repositorio

Este indice separa la documentacion vigente KX134 de la documentacion historica
ADXL335.

## Entrada Principal

- [README raiz](../README.md): estado ejecutivo, arquitectura y uso rapido.
- [Indice KX134](kx134_migration/INDEX.md): mapa tecnico completo.
- [Estado del repositorio](kx134_migration/REPOSITORY_STATUS.md): decisiones
  actuales y pendientes.

## Documentacion De Usuario

- [Guia rapida](kx134_migration/client/QUICK_START_GUIDE.md)
- [Manual de usuario](kx134_migration/client/USER_MANUAL_KX134_PROTOTYPE.md)
- [Instalacion Windows](kx134_migration/client/WINDOWS_INSTALLATION_GUIDE.md)
- [Conexion hardware](kx134_migration/client/HARDWARE_CONNECTION_GUIDE.md)
- [Captura y exportacion](kx134_migration/client/CAPTURE_AND_EXPORT_GUIDE.md)
- [Referencia de archivos](kx134_migration/client/OUTPUT_FILES_REFERENCE.md)
- [Troubleshooting](kx134_migration/client/TROUBLESHOOTING_GUIDE.md)
- [Limitaciones](kx134_migration/client/LIMITATIONS_AND_WARNINGS.md)

## Documentacion Tecnica

- [Arquitectura](kx134_migration/ARCHITECTURE_OVERVIEW.md)
- [Operacion](kx134_migration/OPERATIONS_OVERVIEW.md)
- [Desarrollo](kx134_migration/DEVELOPMENT_GUIDE.md)
- [Validacion](kx134_migration/VALIDATION_SUMMARY.md)
- [Paquete de entrega](kx134_migration/PROTOTYPE_DELIVERY_PACKAGE.md)
- [Matriz de evidencias](kx134_migration/VALIDATION_EVIDENCE_MATRIX.md)
- [Pendientes y riesgos](kx134_migration/OPEN_ITEMS_AND_RISKS.md)

## Firmware

- `firmware/kx134_dual_espnow/`: flujo actual KX134 dual.
- `firmware/kx134_single_node_i2c/`: bring-up y calibracion KX134.
- `firmware/kx134_receiver_identity/`: captura de identidad MAC del receptor.
- Firmware ADXL335 historico: conservar como legacy, no usar como ruta actual.

## GUI Y Empaquetado

- `gui/app_launcher.py`: launcher actual.
- `gui/kx134_live_gui.py`: GUI KX134.
- `gui/adxl_live_gui.py`: GUI ADXL335 legacy.
- [Empaquetado Windows](kx134_migration/WINDOWS_PACKAGING_KX134.md)

## PCB/Baquelada

- [Criterios PCB](kx134_migration/PCB_BAQUELADA_CRITERIA.md)
- [Revision baquelada RevA](../hardware/pcb/baquelada_revA/BAQUELADA_REVA_REVIEW.md)
- PCB final: no autorizada.

## Assets

- [Assets README](assets/README.md)
- [Diagramas](assets/diagrams/)
- [Screenshots](assets/screenshots/)

## Reportes

- `reports/kx134_gui_validation/`: GUI, empaquetado y QA.
- `reports/prototype_validation/`: prototipo, cliente, PCB/baquelada.
- `reports/repository_health/`: readiness documental del repositorio.
- `reports/change_log.md`: registro tecnico de cambios.
