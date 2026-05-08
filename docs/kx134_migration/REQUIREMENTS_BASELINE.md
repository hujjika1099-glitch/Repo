# Baseline de requisitos KX134

## Sensores y identidad

- El sistema debe trabajar con dos sensores SparkFun SEN-17589 / KX134.
- `sensor_id=1` y `sensor_id=2` son obligatorios.
- No se debe inferir `sensor_id` por defecto si falta en el stream.
- Cada sensor fisico debe tener asociacion estable:
  - `sensor_id` logico.
  - Etiqueta fisica visible.
  - ESP32 asociada.
  - MAC de la ESP32.
  - Rol dentro del sistema.
  - Archivo de calibracion individual.

## Calibracion

- La calibracion individual es obligatoria antes de pruebas de prototipo.
- Cada sensor debe tener su propio `calibration_id`.
- No se debe reutilizar calibracion entre sensores.

## Datos KX134

- Exportar datos crudos digitales por eje:
  - `x_raw`
  - `y_raw`
  - `z_raw`
- Exportar conversion basica a `g`:
  - `x_g`
  - `y_g`
  - `z_g`
- No incluir columnas de voltaje para KX134:
  - No `mv_x`
  - No `mv_y`
  - No `mv_z`
- La aplicacion no debe hacer analisis profundo. Debe capturar, convertir
  basicamente a `g`, prechequear integridad y exportar evidencia.

## Captura y sincronizacion

- La sincronizacion entre ambos sensores es requisito central.
- Debe existir precheck dual antes de aceptar capturas operativas.
- Los archivos futuros deben incluir campos de sincronizacion:
  - `sensor_id`
  - `node_mac`
  - `seq`
  - `sensor_t_us`
  - `receiver_t_us`
  - `pc_wall_s`
  - `sample_rate_hz`
  - `range_g`
  - `calibration_id`

## Parametros operativos futuros

- La duracion de captura debe ser editable manualmente en segundos.
- La duracion debe aceptar valores positivos arbitrarios, por ejemplo `10` o
  `1567`.
- La frecuencia de muestreo debe ser seleccionable.
- Frecuencias permitidas:
  - `100 Hz`
  - `200 Hz`
  - `500 Hz`
  - `1000 Hz`
- La frecuencia default debe ser `100 Hz`.

## GUI y empaquetado futuros

- La GUI debe ser adaptable, profesional y clara para captura dual.
- La GUI debe exponer duracion manual y frecuencia seleccionable.
- El empaquetado Windows debe conservar la ruta de salida junto al ejecutable.
- El empaquetado Windows debe incorporar DPI awareness en tickets posteriores.

## Topologia base

- Arquitectura inicial asumida:
  - Dos ESP32 sensoras independientes.
  - Una ESP32 receptora USB/ESP-NOW segun arquitectura existente.
  - Un KX134 por ESP32 sensora.
- Decision pendiente:
  - Confirmar si fisicamente habra tres ESP32 totales o solo dos ESP32.
  - Si solo hay dos ESP32 totales, no implementar firmware hasta cerrar la
    arquitectura.
