# Matriz de evidencias de validacion KX134

| Area | Ticket | Evidencia | Resultado | Advertencias |
|---|---|---|---|---|
| Calibracion Sensor 1 | TICKET 009 | `config/calibrations/kx134_sensor_1.json`, reportes Sensor 1 | PASS | No intercambiar sensor sin recalibrar |
| Calibracion Sensor 2 | TICKET 011 | `config/calibrations/kx134_sensor_2.json`, reportes Sensor 2 | PASS | No intercambiar sensor sin recalibrar |
| Firmware dual ESP-NOW | TICKET 013 | `reports/kx134_test_runs/TICKET_013_DUAL_ESPNOW_TEST_SUMMARY.md` | PASS | Duplicados visibles quedaron para diagnostico posterior |
| Sync precheck | TICKET 014 | `reports/kx134_test_runs/TICKET_014_DUAL_SYNC_PRECHECK_SUMMARY.md` | PASS | Se corrigio causa de duplicados en receptor |
| GUI hardware capture | TICKET 016 | `reports/kx134_gui_validation/TICKET_016_GUI_HARDWARE_VALIDATION_SUMMARY.md` | PASS | Reset receptor puede ser necesario si COM4 queda sin stream |
| Export hardening | TICKET 017 | `reports/kx134_gui_validation/TICKET_017_EXPORT_HARDENING_SUMMARY.md` | PASS | Bundles anteriores pueden ser metadata legacy |
| Visual redesign | TICKET 018 | `reports/kx134_gui_validation/TICKET_018_GUI_VISUAL_REDESIGN_SUMMARY.md` | PASS | Scaling 125/150 pendiente |
| Live plots | TICKET 019 | `reports/kx134_gui_validation/TICKET_019_GUI_LIVE_PLOTS_SUMMARY.md` | PASS | `|g|` es solo visual, no exportado |
| Windows packaging | TICKET 020 | `reports/kx134_gui_validation/TICKET_020_WINDOWS_PACKAGING_SUMMARY.md` | PASS | Icono/firma digital pendientes |
| External QA | TICKET 021/021B | `reports/kx134_gui_validation/TICKET_021_EXTERNAL_PC_QA_SUMMARY.md` | PASS visual | Hardware externo no ejecutado |
| Prototype validation | TICKET 022 | `reports/prototype_validation/TICKET_022_PROTOTYPE_VALIDATION_SUMMARY.md` | PASS | Sensor 1 tuvo 2 seq gaps, advertencia no bloqueante |

## Decision de cierre

- `PROTOTYPE_DELIVERY_PACKAGE_READY = YES`
- `PCB_DESIGN_AUTHORIZED = NO`
