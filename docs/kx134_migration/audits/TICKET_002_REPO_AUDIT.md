# TICKET 002 - Auditoria tecnica del repositorio actual

## 1. Resumen ejecutivo

El repositorio auditado sigue orientado a ADXL335 analogico: el firmware lee ADC por
GPIO, serializa cuentas raw y milivoltios, y la GUI convierte esos milivoltios a una
estimacion rapida de g. La rama de migracion KX134 ya existe y conserva el baseline
documental del TICKET 001, pero aun no hay cambios funcionales para SEN-17589/KX134.

La migracion debera tocar, en tickets posteriores, firmware sensor, receptor ESP-NOW,
parser serial, contrato de datos, exportacion CSV/JSON, calibracion, GUI y empaquetado.
Los riesgos principales son la inferencia silenciosa de `sensor_id`, la persistencia de
campos `mv_*`, la falta de timestamps de receptor en filas de datos, la falta de MAC por
muestra, la calibracion no individual por KX134 y la arquitectura fisica de ESP32 aun no
cerrada.

Decisiones pendientes antes de implementar firmware: confirmar si habra tres ESP32
totales o solo dos, confirmar I2C/Qwiic o SPI para KX134, definir rango g inicial,
definir mecanismo de configuracion de frecuencia y cerrar el formato de sincronizacion.

## 2. Rama y baseline auditado

- Rama auditada: `feature/kx134-dual-capture`.
- Commit HEAD auditado antes de documentar: `1d31f2abe1cbbfee623ff73a3d889fc83fae98fc`.
- Commit base esperado del TICKET 001: `1d31f2abe1cbbfee623ff73a3d889fc83fae98fc`.
- Fecha de auditoria: 2026-05-08.
- Estado de git antes de modificar documentacion: limpio, sin cambios locales.

## 3. Mapa del repositorio

| Carpeta o archivo | Proposito probable | Archivos relevantes | Requiere cambios futuros KX134 |
|---|---|---|---|
| `firmware/` | Firmware ESP32 de captura directa y topologia ESP-NOW | `single_node_calibration/src/main.cpp`, `dual_node_espnow/include/*.h`, `dual_node_espnow/src/*.cpp` | Si. Debe cambiar ADC analogico por lectura digital KX134, contrato de paquete y sincronizacion. |
| `gui/` | Aplicacion live Python/Tkinter, parser serial, precheck, exportacion | `adxl_live_core.py`, `adxl_live_gui.py` | Si. Debe aceptar contrato KX134, duracion/frecuencia, campos nuevos y GUI adaptable. |
| `config/` | Plantillas y convenciones de sensores ADXL335 | `adxl335_module_template.json`, `sensor_C_axis_convention_phase11.json` | Si. Deben agregarse calibraciones KX134 por sensor y MAC. |
| `scripts/` | Launchers y soporte operativo | `install_gui_requirements.ps1`, `run_sensorB_live_session.ps1` | Probable. Solo en tickets futuros, si cambian nombres/argumentos. |
| `reports/` | Evidencia tecnica, change log y salidas de analisis | `change_log.md`, `analysis_outputs/` | Solo documentacion/change log en este ticket; reportes futuros deben reflejar KX134. |
| `docs/` | Documentacion principal y baseline de migracion | `kx134_migration/*`, guia/manuales existentes | Si. Debe evolucionar con contrato, firmware, GUI y validacion. |
| Empaquetado | Build Windows standalone | `adxl_captura.spec`, `build_exe.ps1` | Si. Debe renombrarse en ticket posterior y revisar icono/DPI awareness. |
| Manual existente | Manual operativo ADXL335 | `ADXL335_Captura_Manual.pdf`, `build_manual_pdf.py` | Si, pero no en este ticket. |

## 4. Auditoria de firmware

| Archivo | Hallazgo | Evidencia archivo:linea | Impacto en migracion KX134 | Accion futura |
|---|---|---|---|---|
| `firmware/single_node_calibration/src/main.cpp` | Firmware single-node documenta cableado ADXL335 a GPIO ADC. | `firmware/single_node_calibration/src/main.cpp:5-9` | KX134 no usa salidas analogicas X/Y/Z. | Reemplazar por driver KX134 I2C/Qwiic o SPI. |
| `firmware/single_node_calibration/src/main.cpp` | Frecuencia fija de 100 Hz. | `firmware/single_node_calibration/src/main.cpp:16-18` | La fase KX134 requiere opciones ODR vigentes de 100, 200, 400 y 800 Hz; 500 y 1000 Hz fueron retiradas en TICKET 005. | Definir configuracion de frecuencia y validacion real. |
| `firmware/single_node_calibration/src/main.cpp` | Usa `analogReadResolution` y atenuacion ADC. | `firmware/single_node_calibration/src/main.cpp:32-43` | Dependencia directa de ADC ESP32. | Eliminar ruta ADC para KX134. |
| `firmware/single_node_calibration/src/main.cpp` | Encabezado serial actual sin `sensor_id`. | `firmware/single_node_calibration/src/main.cpp:107-115` | Riesgo de inferir sensor por defecto. | Exigir `sensor_id` en todo stream KX134. |
| `firmware/single_node_calibration/src/main.cpp` | Lee `raw_*` con `analogRead` y `mv_*` con `analogReadMilliVolts`. | `firmware/single_node_calibration/src/main.cpp:144-150` | `mv_*` es incompatible con KX134. | Serializar `x_raw/y_raw/z_raw` digitales y `x_g/y_g/z_g`. |
| `firmware/single_node_calibration/src/main.cpp` | Imprime `seq`, `t_us`, raw y mV por serial. | `firmware/single_node_calibration/src/main.cpp:152-167` | Falta `node_mac`, `receiver_t_us`, `sample_rate_hz`, `range_g`, `calibration_id`. | Crear contrato KX134 v3 antes de firmware. |
| `firmware/dual_node_espnow/include/transport_packet.h` | Contrato ESP-NOW fija header ADXL con `mv_x/mv_y/mv_z`. | `firmware/dual_node_espnow/include/transport_packet.h:9-13` | Contrato de paquete incompatible con regla sin voltajes. | Redefinir paquete binario y CSV. |
| `firmware/dual_node_espnow/include/transport_packet.h` | `TransportPacket` incluye `sensor_id`, `seq`, `t_us`, raw y mV. | `firmware/dual_node_espnow/include/transport_packet.h:15-27` | Parcialmente util, pero faltan MAC y tiempos de receptor. | Agregar campos/metadata de sincronizacion. |
| `firmware/dual_node_espnow/include/transport_config.h` | Peer broadcast para bring-up. | `firmware/dual_node_espnow/include/transport_config.h:7-11` | Riesgo de identidad ambigua en sistema dual real. | Definir unicast/receptor y registro de MAC. |
| `firmware/dual_node_espnow/include/transport_config.h` | Identidad manual: `kSensorId = 1`, `sensor_B`; segundo transmisor debe editarse a 2. | `firmware/dual_node_espnow/include/transport_config.h:13-19` | Riesgo alto de dos nodos con mismo `sensor_id`. | Separar configuracion por nodo y validar precheck dual. |
| `firmware/dual_node_espnow/src/sensor_node_main.cpp` | Nodo sensor usa pines ADXL y ADC. | `firmware/dual_node_espnow/src/sensor_node_main.cpp:11-14`, `31-42` | No aplica a KX134 digital. | Implementar lectura digital KX134 en ticket posterior. |
| `firmware/dual_node_espnow/src/sensor_node_main.cpp` | Inicializa ESP-NOW, WiFi STA y canal fijo. | `firmware/dual_node_espnow/src/sensor_node_main.cpp:73-97` | Base reutilizable si se conserva ESP-NOW. | Revisar latencia, timestamp y peer real. |
| `firmware/dual_node_espnow/src/sensor_node_main.cpp` | Metadatos incluyen `local_mac`, `peer_mac`, `sensor_id`, `sample_hz`. | `firmware/dual_node_espnow/src/sensor_node_main.cpp:100-124` | Util, pero no queda por muestra. | Incluir `node_mac` en stream final o sesion por sensor. |
| `firmware/dual_node_espnow/src/sensor_node_main.cpp` | Paquete se llena con raw ADC y mV. | `firmware/dual_node_espnow/src/sensor_node_main.cpp:138-158` | Incompatible con KX134. | Sustituir por raw digital KX134 y conversion basica a g. |
| `firmware/dual_node_espnow/src/receiver_node_main.cpp` | Receptor guarda MAC de origen en cola interna. | `firmware/dual_node_espnow/src/receiver_node_main.cpp:11-23`, `64-90` | Base util para `node_mac`, pero no se exporta por fila. | Emitir MAC por fila o metadata inequivoca por sensor. |
| `firmware/dual_node_espnow/src/receiver_node_main.cpp` | Startup imprime `kCsvHeader` con `sensor_id`. | `firmware/dual_node_espnow/src/receiver_node_main.cpp:121-137` | El header promete `sensor_id`. | Corregir contrato antes de migrar. |
| `firmware/dual_node_espnow/src/receiver_node_main.cpp` | `print_packet_csv` no imprime `sensor_id`, empieza en `seq`. | `firmware/dual_node_espnow/src/receiver_node_main.cpp:175-190` | Error critico de contrato; la GUI puede interpretar columnas desplazadas. | Documentar para TICKET 003/firmware, no corregir aqui. |
| `firmware/dual_node_espnow/src/receiver_node_main.cpp` | No imprime `receiver_t_us`. | `firmware/dual_node_espnow/src/receiver_node_main.cpp:175-190` | Falta campo central de sincronizacion. | Agregar timestamp del receptor en contrato KX134. |

## 5. Auditoria de contrato de datos

Contratos y encabezados encontrados:

- Single-node serial: `seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z`.
- Dual ESP-NOW header: `sensor_id,seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z`.
- GUI acepta 8 u 9 columnas y si recibe 8 columnas antepone `sensor_id=1`.
- CSV raw de GUI: `sensor_id,seq,t_us,wall_s,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z`.
- CSV processed de GUI: raw + `gx_est,gy_est,gz_est,g_norm_est`.

| Campo actual | Estado para KX134 | Evidencia | Nota |
|---|---|---|---|
| `sensor_id` | Compatible, obligatorio | `gui/adxl_live_core.py:47-58`, `264-298` | No debe inferirse por defecto. |
| `seq` | Compatible | `firmware/dual_node_espnow/include/transport_packet.h:15-27` | Debe mantenerse por nodo sensor. |
| `t_us` | Requiere renombrado/revision | `gui/adxl_live_core.py:47-58` | Debe quedar claro como `sensor_t_us`. |
| `wall_s` | Requiere renombrado | `gui/adxl_live_core.py:64-76` | Requisito futuro: `pc_wall_s`. |
| `raw_x`, `raw_y`, `raw_z` | Requiere renombrado | `gui/adxl_live_core.py:64-76` | Para KX134 se pidio `x_raw/y_raw/z_raw`; semantica digital, no ADC ESP32. |
| `mv_x`, `mv_y`, `mv_z` | Incompatible, requiere eliminacion | `gui/adxl_live_core.py:64-76`, `1279-1298` | KX134 no debe exportar voltajes ni milivoltios. |
| `gx_est`, `gy_est`, `gz_est` | Requiere renombrado/revision | `gui/adxl_live_core.py:78-87`, `1309-1315` | Futuro: `x_g/y_g/z_g`, conversion basica desde KX134. |
| `g_norm_est` | Requiere revision | `gui/adxl_live_core.py:78-87` | Puede servir a precheck, pero no es requisito de exportacion KX134. |
| `node_mac` | Faltante | `firmware/dual_node_espnow/src/receiver_node_main.cpp:159-162` | Solo aparece como metadata `source_mac`, no por fila. |
| `receiver_t_us` | Faltante | `firmware/dual_node_espnow/src/receiver_node_main.cpp:175-190` | Requisito de sincronizacion. |
| `sample_rate_hz` | Faltante por fila/sesion formal | `firmware/dual_node_espnow/include/transport_packet.h:9-13` | Existe constante, falta contrato exportado. |
| `range_g` | Faltante | busqueda de contrato | Debe venir de configuracion KX134. |
| `calibration_id` | Faltante | busqueda de calibracion | Debe asociar archivo/version de calibracion. |

Problema critico observado: `parse_adxl335_stream_line` permite 8 columnas y agrega
`sensor_id=1` automaticamente (`gui/adxl_live_core.py:285-298`). Esta compatibilidad
historica debe eliminarse para KX134 porque el ticket baseline prohibe inferir
`sensor_id` si falta en el stream.

## 6. Auditoria de GUI

| Archivo | Hallazgo | Evidencia archivo:linea | Riesgo | Accion futura |
|---|---|---|---|---|
| `gui/adxl_live_gui.py` | Titulo y copy principales siguen nombrando ADXL335. | `gui/adxl_live_gui.py:387`, `472`, `1020` | Confusion de producto/sensor. | Renombrar interfaz cuando exista contrato KX134. |
| `gui/adxl_live_core.py` | Parser serial conserva nombre ADXL335 y acepta stream sin `sensor_id`. | `gui/adxl_live_core.py:264-298` | Alta: identidad silenciosa incorrecta. | Exigir encabezado y filas KX134 v3. |
| `gui/adxl_live_core.py` | Modelo `Sample` depende de `mv_x/y/z` y `gx_est`. | `gui/adxl_live_core.py:47-88` | Alta: contrato incompatible. | Definir modelo KX134 con raw digital y g basico. |
| `gui/adxl_live_core.py` | Estimacion de g usa bias y sensibilidad mV/g. | `gui/adxl_live_core.py:226-261`, `520-543` | Alta: propio de ADXL335 analogico. | Usar conversion KX134 segun rango y sensibilidad digital. |
| `gui/adxl_live_core.py` | Precheck dual requiere sensores 1 y 2. | `gui/adxl_live_core.py:1137-1168` | Medio: buena base, pero los criterios son ADC/mV. | Rehacer sanidad para KX134 digital. |
| `gui/adxl_live_gui.py` | Duracion visible usa combobox con opciones 10-90, aunque se parsea float editable. | `gui/adxl_live_gui.py:487-495`, `748-760` | Medio: debe admitir positivos arbitrarios como `1567`. | Validar positividad y UX de duracion manual. |
| `gui/adxl_live_gui.py` | No hay selector de frecuencia de muestreo. | busqueda GUI `duration/sample/rate` | Medio/alto: requisito futuro 100/200/400/800 Hz; 500 y 1000 Hz fueron retiradas en TICKET 005. | Agregar control y contrato con firmware. |
| `gui/adxl_live_gui.py` | Graficas de ejes se etiquetan `mV`. | `gui/adxl_live_gui.py:348-363`, `840-850` | Alto: KX134 no debe mostrar/exportar mV. | Cambiar a raw digital/g basico. |
| `gui/adxl_live_gui.py` | Geometria fija y minsize alto. | `gui/adxl_live_gui.py:321-389` | Medio: posible recorte en otros PC/DPI. | Redisenar layout adaptable y DPI-aware. |
| `gui/adxl_live_gui.py` | Sidebar con ancho fijo y `grid_propagate(False)`. | `gui/adxl_live_gui.py:458-465` | Medio: posible corte visual. | Hacer layout responsivo con scroll o breakpoints. |

## 7. Auditoria de exportacion CSV/archivos

La GUI genera nombres con patron `{file_prefix}_{session_name}_{YYYYMMDD_HHMMSS}_{tipo}`
en `ensure_output_paths` (`gui/adxl_live_core.py:316-334`). Las ubicaciones actuales son:

- Raw: `data/raw/sensor_B_live/*_raw.csv`.
- Processed: `data/processed/*_processed.csv`.
- Metadata: `data/processed/*_session.json`.
- Reportes: `reports/analysis_outputs/*_precheck.txt` y `*_summary.txt`.

La escritura CSV usa `csv.DictWriter` con las claves de la primera fila
(`gui/adxl_live_core.py:871-877`). El raw actual exporta `sensor_id`, `seq`, `t_us`,
`wall_s`, `raw_x/y/z` y `mv_x/y/z` (`gui/adxl_live_core.py:64-76`). El processed agrega
`gx_est/gy_est/gz_est/g_norm_est` (`gui/adxl_live_core.py:78-87`). El session JSON guarda
configuracion, metadata serial, resumen de sensores, integridad y rutas
(`gui/adxl_live_core.py:993-1036`).

Para KX134 sera necesaria una estructura de exportacion que no incluya `mv_*`, que use
campos inequivocos `x_raw/y_raw/z_raw` y `x_g/y_g/z_g`, y que agregue por muestra o por
registro sincronizado: `sensor_id`, `node_mac`, `seq`, `sensor_t_us`, `receiver_t_us`,
`pc_wall_s`, `sample_rate_hz`, `range_g` y `calibration_id`.

## 8. Auditoria de calibracion

El flujo actual de g estimado esta atado a ADXL335 analogico:

- `LiveBiasEstimator` acumula bias en mV y divide por sensibilidad mV/g
  (`gui/adxl_live_core.py:226-261`).
- `estimate_sensor_accel_g` calcula `g = (mv - bias) / sens_mv_per_g`
  (`gui/adxl_live_core.py:520-543`).
- `LiveSessionConfig` conserva `nominal_sens_mv_per_g` y `sensorB_sens_mv_per_g`
  (`gui/adxl_live_core.py:180-206`).
- `config/adxl335_module_template.json` documenta cableado ADXL335 y umbrales ADC
  (`config/adxl335_module_template.json:1-38`).
- `hardware/sensor_registry.csv` contiene roles ADXL335 y un archivo historico de
  calibracion para `sensor_C` (`hardware/sensor_registry.csv:1-5`).

No se encontro una calibracion KX134 individual por `sensor_id` y `node_mac`. Para la
migracion se esperan archivos futuros como:

- `config/calibrations/kx134_sensor_1.json`
- `config/calibrations/kx134_sensor_2.json`

Cada archivo deberia incluir `sensor_id`, etiqueta fisica visible, `node_mac`,
`calibration_id`, fecha, rango g, sample rate usado, offsets/scale por eje y estado de
validacion.

## 9. Auditoria de empaquetado

El empaquetado actual esta nombrado para ADXL335:

- `adxl_captura.spec` declara la configuracion de PyInstaller para
  `ADXL335_Captura.exe` (`adxl_captura.spec:1-7`).
- El ejecutable se llama `ADXL335_Captura` y no tiene icono (`adxl_captura.spec:52-73`).
- No se observo manifiesto DPI-aware en el spec (`adxl_captura.spec:17-73`).
- `hiddenimports` se limitan a `pyserial` y modulos de puertos serie
  (`adxl_captura.spec:22-29`).
- `build_exe.ps1` genera `dist/ADXL335_Captura.exe` y
  `dist/ADXL335_Captura_dist.zip` (`build_exe.ps1:1-31`, `68-85`).
- `_resolve_repo_root()` guarda datos junto al `.exe` cuando corre congelado por
  PyInstaller (`gui/adxl_live_gui.py:1006-1015`).

Posibles causas de mala apariencia en otros PC: ventana y popout con geometria fija,
minsize alto, ausencia de manifiesto DPI-aware, sidebar fijo y falta de pruebas
visuales en resoluciones/DPI variados. No se modifico empaquetado en este ticket.

## 10. Riesgos tecnicos principales

| Prioridad | Riesgo | Severidad | Impacto | Mitigacion futura |
|---|---|---|---|---|
| 1 | Inferencia silenciosa de `sensor_id=1` cuando faltan columnas. | Alta | Datos de sensor equivocado o fusion incorrecta. | Exigir `sensor_id` obligatorio en parser KX134. |
| 2 | Contrato ESP-NOW con header `sensor_id` pero receptor no imprime `sensor_id`. | Alta | Desalineacion de columnas y precheck invalido. | Corregir contrato firmware/receptor en ticket dedicado. |
| 3 | Persistencia de `mv_x/mv_y/mv_z`. | Alta | Exportacion incompatible con KX134. | Eliminar campos de firmware, GUI y CSV KX134. |
| 4 | Falta `receiver_t_us` y `node_mac` por fila. | Alta | Sincronizacion y trazabilidad insuficientes. | Agregar timestamps y MAC al contrato v3. |
| 5 | Calibracion no individual por KX134. | Alta | Conversion a g no trazable por sensor. | Crear calibraciones por `sensor_id` y MAC. |
| 6 | Frecuencia fija o solo estimada. | Media/alta | No cumple 200/400/800 Hz seleccionables; 500 y 1000 Hz fueron retiradas en TICKET 005. | Definir comando/configuracion firmware-GUI. |
| 7 | Arquitectura ESP32 no cerrada. | Alta | Firmware equivocado si solo hay dos ESP32 totales. | Confirmar topologia antes de TICKET 004/005. |
| 8 | GUI con geometria rigida. | Media | Cortes visuales en PCs con DPI/resolucion distintos. | Redisenar layout y empaquetado DPI-aware. |
| 9 | Nombres ADXL335 en exe, UI y docs. | Media | Confusion operativa en la fase KX134. | Renombrar en ticket de GUI/empaquetado. |
| 10 | Precheck actual basado en ADC/mV/g_norm. | Media | Falsos positivos/negativos para KX134. | Redefinir criterios KX134. |

## 11. Decisiones pendientes antes de implementar firmware

- Confirmar si habra tres ESP32 totales: sensor 1 + sensor 2 + receptor.
- Confirmar si cada SEN-17589/KX134 estara conectado a una ESP32 independiente.
- Confirmar si, en caso de solo dos ESP32 totales, una ESP32 tambien actuara como
  receptor o si se redisenara la topologia.
- Confirmar interfaz fisica KX134: I2C/Qwiic o SPI.
- Confirmar rango g inicial: +/-8 g, +/-16 g, +/-32 g o +/-64 g.
- Confirmar si la frecuencia seleccionable sera configurada desde GUI hacia firmware o
  solo por firmware inicialmente.
- Confirmar formato final de sincronizacion: campos por fila, metadata por sesion o
  ambos.
- Confirmar nombres fisicos de sensores y etiquetas visibles.
- Confirmar si se requiere guardar MAC de cada ESP32 en cada fila o en metadata
  validada por sesion.
- Confirmar politica de broadcast/unicast ESP-NOW para prototipo dual.

## 12. Propuesta de proximos tickets

Orden recomendado despues de esta auditoria:

- TICKET 003: Contrato de datos KX134 v3.
- TICKET 004: Firmware KX134 de un nodo sensor.
- TICKET 005: Firmware dual dos ESP32 + receptor.
- TICKET 006: Sincronizacion y precheck.
- TICKET 007: Calibracion individual.
- TICKET 008: GUI duracion manual y frecuencia.
- TICKET 009: Exportacion CSV KX134.
- TICKET 010: GUI adaptable/profesional.
- TICKET 011: Empaquetado Windows profesional.
- TICKET 012: Validacion de prototipo.
- TICKET 013: Criterios para baquelada/PCB.

## 13. Archivos candidatos a modificar en proximos tickets

| Proximo ticket | Archivos candidatos | Tipo de cambio | Riesgo |
|---|---|---|---|
| TICKET 003 | `docs/kx134_migration/*`, posible contrato JSON nuevo | Definir contrato de datos KX134 v3 | Bajo si es documental. |
| TICKET 004 | `firmware/dual_node_espnow/src/sensor_node_main.cpp`, `include/*.h`, nuevo config KX134 | Lectura digital de un KX134 | Alto por hardware y libreria/driver. |
| TICKET 005 | `firmware/dual_node_espnow/src/*.cpp`, `transport_packet.h`, `transport_config.h` | Dual sensor + receptor + MAC/timestamps | Alto por sincronizacion. |
| TICKET 006 | `firmware/dual_node_espnow/src/receiver_node_main.cpp`, `gui/adxl_live_core.py` | Sincronizacion y precheck KX134 | Alto por criterios de validez. |
| TICKET 007 | `config/calibrations/*.json`, `gui/adxl_live_core.py`, docs | Calibracion individual | Medio/alto por trazabilidad. |
| TICKET 008 | `gui/adxl_live_gui.py`, `gui/adxl_live_core.py` | Duracion manual y frecuencia seleccionable | Medio. |
| TICKET 009 | `gui/adxl_live_core.py`, docs/contratos | Export CSV/JSON KX134 | Alto por compatibilidad de datos. |
| TICKET 010 | `gui/adxl_live_gui.py` | Redisenio adaptable/profesional | Medio por QA visual. |
| TICKET 011 | `adxl_captura.spec`, `build_exe.ps1`, manual/docs | Empaquetado Windows profesional | Medio por distribucion. |
| TICKET 012 | `reports/`, datos nuevos de validacion | Validacion de prototipo | Medio/alto por evidencia fisica. |
| TICKET 013 | `docs/`, `hardware/` | Criterios baquelada/PCB | Medio por decisiones de hardware. |

## 14. Evidencia de comandos ejecutados

| Comando | Resultado resumido |
|---|---|
| `git status --short --branch` | Rama `feature/kx134-dual-capture` tracking `origin/feature/kx134-dual-capture`, limpia antes de editar. |
| `git branch --show-current` | `feature/kx134-dual-capture`. |
| `git log --oneline -5` | HEAD inicial `1d31f2a docs: add KX134 migration baseline and working branch plan`. |
| `git status --short` | Sin cambios locales antes de modificar documentacion. |
| `rg -n "ADXL335|ADXL|adxl" .` | Multiples referencias ADXL335 en firmware, GUI, docs, empaquetado y reportes. |
| `rg -n "analogRead|analogReadMilliVolts|ADC|adc|millivolt|mV|mv_" firmware gui config scripts docs reports` | Dependencias ADC/mV en firmware, GUI, config y documentacion. |
| `rg -n "raw_x|raw_y|raw_z|mv_x|mv_y|mv_z|gx_est|gy_est|gz_est|g_norm|sensor_id|seq|t_us" firmware gui config scripts docs reports` | Contrato actual raw/mV/g_est localizado en firmware y GUI. |
| `rg -n "esp_now|ESP-NOW|Serial|baud|receiver|receptor|peer|MAC|mac" firmware gui config scripts docs reports` | Arquitectura ESP-NOW/serial localizada en `dual_node_espnow`. |
| `rg -n "csv|writerow|DictWriter|to_csv|_raw|_processed|header|columns" gui scripts firmware docs reports` | Exportacion CSV y headers localizados en GUI/firmware. |
| `rg -n "duration|duracion|duración|tiempo|seconds|segundos|session|sesion|sesión|capture|captura" gui scripts firmware docs reports` | Duracion GUI y sesion localizadas. |
| `rg -n "sample|sampling|rate|Hz|hz|100|200|500|1000|period|interval|delayMicroseconds|millis|micros" firmware gui scripts config docs reports` | Frecuencia fija 100 Hz y estimaciones encontradas. |
| `rg -n "calib|calibration|calibracion|calibración|offset|scale|bias" firmware gui scripts config docs reports` | Calibracion actual basada en bias/sensibilidad ADXL335. |
| `rg -n "PyInstaller|pyinstaller|spec|exe|icon|manifest|DPI|dpi|build|dist|onedir|onefile" .` | Empaquetado PyInstaller ADXL335 localizado. |
| `rg -n "geometry|minsize|maxsize|wm_geometry|place\\(|pack\\(|grid\\(|Tk\\(|Toplevel|FigureCanvas|dpi|scaling" gui` | Geometrias fijas y layout Tkinter localizados. |
