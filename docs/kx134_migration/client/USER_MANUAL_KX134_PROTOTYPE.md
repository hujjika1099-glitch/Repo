# Manual de usuario - Prototipo KX134 dual

## Introduccion

El Sistema de Captura de Acelerometria KX134 es un prototipo funcional para capturar datos de dos sensores SEN-17589/KX134 en tiempo real. La GUI permite seleccionar puerto, configurar duracion, observar graficas live y exportar un bundle auditable con CSV raw, session JSON y summary MD.

## Arquitectura general

- Sensor 1: ESP32 sensora con KX134, `sensor_id=1`.
- Sensor 2: ESP32 sensora con KX134, `sensor_id=2`.
- Receptor: ESP32 que recibe por ESP-NOW y retransmite por USB Serial.
- PC: ejecuta `Sistema_Captura_Acelerometria.exe`.

## Identificacion de hardware

| Nodo | Identidad | MAC |
|---|---|---|
| Sensor 1 | `sensor_id=1` | `D4:E9:F4:E9:8E:1C` |
| Sensor 2 | `sensor_id=2` | `D4:E9:F4:C3:37:14` |
| Receptor | USB Serial | `00:4B:12:96:9A:80` |

## Aplicacion Windows

La aplicacion abre un launcher principal llamado Sistema de Captura de Acelerometria. Desde alli se puede abrir:

- KX134 Dual Capture: modo actual del prototipo.
- ADXL335 historico: modulo preservado para compatibilidad.

## Pestañas KX134

- Conexion: puerto COM, baudrate `921600`, actualizacion de puertos y estado.
- Captura: duracion manual, frecuencia esperada y nombre de sesion.
- Sensores: estado de Sensor 1 y Sensor 2, muestras y continuidad.
- Graficas: ejes `x_g`, `y_g`, `z_g`, comparacion visual `|g|` y eje seleccionado.
- Diagnostico: invalid lines, duplicate keys, packet_status, packet_error_code.
- Exportacion: rutas del CSV, JSON y summary.

## Parametros operativos

- Puerto COM: use el puerto real del Receptor.
- Baudrate: `921600`.
- Duracion: cualquier valor positivo; para inicio use 10 a 20 segundos.
- Frecuencia esperada: la GUI muestra 100/200/400/800, pero la configuracion validada es `100 Hz`.
- Rango validado: `8 g`.

## Graficas

Las graficas muestran aceleracion calibrada en g:

- Sensor 1: `x_g/y_g/z_g`.
- Sensor 2: `x_g/y_g/z_g`.
- Comparacion `|g|`: solo visual.
- Comparacion de eje seleccionado: Sensor 1 vs Sensor 2.

`|g|` no se exporta como columna CSV. La visualizacion no filtra ni altera los datos crudos.

## Exportacion

Cada sesion KX134 genera:

- CSV raw KX134 v3.
- Session JSON con metadata endurecida.
- Summary MD legible.

El CSV conserva datos crudos y datos calibrados por sensor. El JSON describe identidad de sesion, configuracion, nodos, resumen y artefactos. El summary resume conteos, frecuencia efectiva, gaps, errores y rutas.

## Limites

- El prototipo no realiza analisis profundo de vibracion.
- La GUI no configura `sample_rate_hz` en firmware todavia; ese envio sigue pendiente.
- La PCB no autorizada requiere decisiones fisicas antes de avanzar.
- Si cambia `range_g`, sensor o ESP32, se debe recalibrar y revalidar.

## Procedimiento recomendado

1. Conecte y alimente Sensor 1, Sensor 2 y Receptor.
2. Abra el launcher y luego KX134 Dual Capture.
3. Seleccione COM, baudrate `921600`, duracion y `100 Hz`.
4. Haga una captura corta.
5. Confirme que Sensor 1 y Sensor 2 aparecen.
6. Observe graficas live.
7. Ejecute captura formal.
8. Guarde CSV, JSON, summary y notas de la prueba.
