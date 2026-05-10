# Validacion GUI KX134 con hardware real

## Objetivo

Validar que el modo GUI KX134 creado en TICKET 015 abre correctamente, captura
el stream real del receptor ESP-NOW KX134 y exporta una sesion auditable sin
alterar el flujo historico ADXL335.

## Precondiciones de hardware

- Sensor 1 KX134 alimentado y transmitiendo como `sensor_id=1`.
- Sensor 2 KX134 alimentado y transmitiendo como `sensor_id=2`.
- Receptor ESP32 conectado por USB al PC.
- Puerto esperado: `COM4`.
- Baudrate: `921600`.
- Firmware reportado: `kx134_dual_espnow.0.1.0`.
- Frecuencia actual del firmware: `100 Hz`.
- Rango actual: `8 g`.

## Comando para abrir GUI

La prueba debe usar una carpeta controlada como raiz de salida:

```powershell
python -m gui.kx134_live_gui --repo-root reports\kx134_gui_validation\TICKET_016_hw_capture_<timestamp> --port COM4 --baud 921600 --duration-s 10 --expected-sample-rate 100 --session-name ticket016_hw_gui
```

Si el modo `-m` no abre por entorno/import, usar:

```powershell
python gui\kx134_live_gui.py --repo-root reports\kx134_gui_validation\TICKET_016_hw_capture_<timestamp> --port COM4 --baud 921600 --duration-s 10 --expected-sample-rate 100 --session-name ticket016_hw_gui
```

## Configuracion usada

- Puerto: `COM4` o puerto confirmado por inventario serial.
- Baudrate: `921600`.
- Duracion: `10 s`.
- Frecuencia esperada: `100 Hz`.
- Carpeta de salida: `reports/kx134_gui_validation/TICKET_016_hw_capture_<timestamp>/`.

## Criterios de aceptacion

- La GUI abre correctamente.
- La captura termina y muestra archivos generados.
- CSV KX134 existe.
- Metadata JSON existe.
- Summary existe.
- CSV tiene encabezado exacto KX134 v3.
- CSV no contiene `mv_*`, `gx_est`, `gy_est`, `gz_est`, `g_norm_est`, `voltage` ni `millivolts`.
- Ambos sensores tienen al menos 500 filas.
- Frecuencia efectiva por sensor entre 98 y 102 Hz.
- `receiver_t_us` valido.
- `pc_wall_s` positivo durante la captura real.
- `packet_status=OK` y `packet_error_code=OK`.

## Archivos generados

- `reports/kx134_gui_validation/TICKET_016_hw_capture_<timestamp>/data/raw/kx134_dual_live/*_raw.csv`
- `reports/kx134_gui_validation/TICKET_016_hw_capture_<timestamp>/data/processed/kx134_dual_live/*_session.json`
- `reports/kx134_gui_validation/TICKET_016_hw_capture_<timestamp>/reports/analysis_outputs/kx134_dual_live/*_summary.md`
- `reports/kx134_gui_validation/TICKET_016_gui_hardware_validation_output.json`
- `reports/kx134_gui_validation/TICKET_016_GUI_HARDWARE_VALIDATION_SUMMARY.md`

## Limitaciones

- La GUI no envia configuracion de frecuencia al firmware todavia.
- El redisenio visual profesional queda pendiente.
- El empaquetado Windows queda pendiente.
- Esta prueba valida captura/exportacion; no realiza analisis profundo de vibracion.

## Resultado TICKET 016

- Decision: `READY_FOR_GUI_EXPORT_HARDENING = YES`.
- Captura final: `reports/kx134_gui_validation/TICKET_016_hw_capture_20260510_124537/`.
- Rows Sensor 1: `1001`.
- Rows Sensor 2: `999`.
- Effective Hz Sensor 1: `100.0`.
- Effective Hz Sensor 2: `100.00002004008418`.
- Seq gaps Sensor 1: `0`.
- Seq gaps Sensor 2: `0`.
- Invalid lines: `0`.
- Duplicate keys Sensor 1: `0`.
- Duplicate keys Sensor 2: `0`.
- `receiver_t_us` valido: `true`.
- `pc_wall_s` positivo: `true`.
- Campos prohibidos detectados: `false`.
- CSV header exacto KX134 v3: `true`.

Durante la validacion se diagnostico que abrir el puerto `COM4` puede resetear la ESP32 receptora y hacer que una captura inmediata arranque mientras el receptor aun no esta estabilizado. Se aplico un bugfix acotado al core KX134: warmup serial interno de `2 s`, uso de `time.perf_counter()` para cronometraje de alta resolucion y mayor precision de `pc_wall_s`. No se modifico firmware, calibraciones, empaquetado ni GUI ADXL335.
