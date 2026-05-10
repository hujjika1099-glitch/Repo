# TICKET 016 - Validacion GUI KX134 con hardware real

## Objetivo

Validar que el modo GUI KX134 agregado en TICKET 015 puede capturar el stream Serial real del receptor ESP-NOW KX134, exportar una sesion auditable y preservar el flujo historico ADXL335.

La decision esperada del ticket es:

`READY_FOR_GUI_EXPORT_HARDENING = YES/NO`

## Precondiciones

- Rama activa: `feature/kx134-dual-capture`.
- TICKET 015 aprobado con `READY_FOR_GUI_HARDWARE_VALIDATION = YES`.
- Receptor KX134 conectado al PC por USB.
- Puerto esperado: `COM4`.
- Baudrate KX134: `921600`.
- Firmware receptor: `kx134_dual_espnow.0.1.0`.
- Sensor 1:
  - `sensor_id=1`
  - MAC `D4:E9:F4:E9:8E:1C`
  - calibrado
- Sensor 2:
  - `sensor_id=2`
  - MAC `D4:E9:F4:C3:37:14`
  - calibrado
- Configuracion actual:
  - `sample_rate_hz=100`
  - `odr_hz=100`
  - `range_g=8`

## Procedimiento interactivo

1. Ejecutar prechecks Python:
   - compilar modulos KX134;
   - compilar modulos ADXL335;
   - ejecutar pruebas `test_kx134*.py`;
   - confirmar disponibilidad de `pyserial`.
2. Validar controles sin captura larga:
   - duracion `10` aceptada;
   - duracion `1567` aceptada;
   - frecuencias `100`, `200`, `400`, `800` aceptadas;
   - frecuencias `500`, `1000` rechazadas.
3. Preparar hardware:
   - conectar y alimentar ambas ESP32 sensoras;
   - conectar receptor al PC;
   - colocar ambos sensores quietos sobre superficie estable.
4. Listar puertos y confirmar `COM4` o puerto real del receptor.
5. Crear carpeta controlada de salida:
   - `reports/kx134_gui_validation/TICKET_016_hw_capture_<timestamp>/`
6. Abrir GUI KX134 con:
   - `--repo-root` apuntando a la carpeta controlada;
   - puerto confirmado;
   - baudrate `921600`;
   - duracion `10`;
   - frecuencia esperada `100`;
   - sesion `ticket016_hw_gui`.
7. Desde la GUI, iniciar captura KX134 y mantener los sensores quietos.
8. Al terminar, localizar artefactos exportados:
   - CSV raw KX134;
   - JSON de sesion;
   - summary.
9. Ejecutar `tools/kx134/validate_gui_hardware_capture.py` sobre los artefactos.
10. Documentar resultado y decision.

## Criterios de aceptacion

- La GUI abre correctamente.
- La captura real termina correctamente.
- Sensor 1 y Sensor 2 aparecen en los archivos exportados.
- El CSV tiene exactamente el encabezado KX134 v3.
- El CSV no contiene `mv_*`, `gx_est`, `gy_est`, `gz_est` ni `g_norm_est`.
- `pc_wall_s` queda positivo en la captura real.
- `receiver_t_us` es valido.
- Ambos sensores tienen al menos 500 filas en la captura de 10 s.
- Frecuencia efectiva por sensor entre 98 y 102 Hz.
- `packet_status=OK`.
- `packet_error_code=OK`.
- La metadata JSON existe y apunta a artefactos presentes.
- El summary existe.
- No se modifica firmware.
- No se modifican calibraciones.
- No se modifica empaquetado.
- No se modifica data historica.
- El flujo ADXL335 compila y queda preservado.

## Restricciones

- No modificar `firmware/`.
- No modificar calibraciones KX134.
- No modificar reportes de calibracion.
- No modificar `adxl_captura.spec`.
- No modificar `build_exe.ps1`.
- No modificar `dist/`.
- No modificar `build_work/`.
- No modificar `.venv/`.
- No crear ejecutable.
- No alterar CSV historicos.
- No redisenar visualmente la GUI.
- No instalar dependencias globales.
- No usar `git reset --hard`.
- No usar `git clean -fd`.

## Archivos esperados

- `tools/kx134/validate_gui_hardware_capture.py`
- `docs/kx134_migration/GUI_KX134_HARDWARE_VALIDATION.md`
- `reports/kx134_gui_validation/TICKET_016_GUI_HARDWARE_VALIDATION_SUMMARY.md`
- `reports/kx134_gui_validation/TICKET_016_gui_hardware_validation_output.json`
- `reports/kx134_gui_validation/TICKET_016_hw_capture_<timestamp>/...`

## Resultado

`READY_FOR_GUI_EXPORT_HARDENING = YES`

La captura final desde GUI KX134 con hardware real paso validacion de artefactos:

- Carpeta final: `reports/kx134_gui_validation/TICKET_016_hw_capture_20260510_124537/`
- Rows Sensor 1: `1001`
- Rows Sensor 2: `999`
- Effective Hz Sensor 1: `100.0`
- Effective Hz Sensor 2: `100.00002004008418`
- Seq gaps Sensor 1: `0`
- Seq gaps Sensor 2: `0`
- Invalid lines: `0`
- Duplicate keys Sensor 1: `0`
- Duplicate keys Sensor 2: `0`
- `receiver_t_us` valido: `true`
- `pc_wall_s` positivo: `true`
- Packet status: `OK`
- Packet error code: `OK`
- Campos prohibidos detectados: `false`
- CSV header exacto KX134 v3: `true`

Se documento un diagnostico operativo: el receptor puede quedar sin emitir hasta un reset fisico, aunque COM4 siga visible. Tras presionar `EN/RST`, el stream directo volvio a emitir y la GUI capturo correctamente. Tambien se aplico un bugfix acotado al core KX134 para absorber el reinicio al abrir serial y conservar `pc_wall_s` con resolucion suficiente. No se modifico firmware, calibraciones, GUI ADXL335, empaquetado ni data historica.
