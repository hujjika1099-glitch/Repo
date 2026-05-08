# Migracion SEN-17589 / KX134

## Proposito

Esta carpeta define la base documental para migrar el sistema actual de captura
ADXL335 analogico hacia una arquitectura con dos acelerometros digitales
SparkFun SEN-17589 / KX134.

El objetivo de esta fase es preparar la ruta de trabajo, no implementar firmware,
GUI ni empaquetado. Los cambios funcionales deben llegar en tickets posteriores y
mantenerse separados por responsabilidad.

## Diferencia tecnica principal

El sistema actual ADXL335 trabaja con salidas analogicas leidas por ADC de la
ESP32. Por eso existen columnas como `raw_x`, `raw_y`, `raw_z` y conversiones a
mV (`mv_x`, `mv_y`, `mv_z`).

El KX134 es un acelerometro digital. La lectura base no debe tratarse como
voltaje sino como muestra digital del sensor. Para KX134, el contrato futuro debe
exportar datos crudos digitales por eje y una conversion basica a `g`.

## Regla de voltajes

Para KX134 no se deben crear ni reutilizar columnas de voltaje:

- No `mv_x`
- No `mv_y`
- No `mv_z`

Las columnas esperadas para la muestra del sensor son:

- `x_raw`
- `y_raw`
- `z_raw`
- `x_g`
- `y_g`
- `z_g`

## Conservacion de datos crudos

Los datos crudos digitales son evidencia primaria. No deben sobrescribirse,
promediarse ni reemplazarse por datos derivados. Cualquier procesamiento debe
quedar en archivos derivados con trazabilidad hacia la captura original.

## Calibracion individual

Cada sensor KX134 debe tener calibracion individual obligatoria antes de pruebas
de prototipo. No se debe compartir calibracion entre sensores aunque sean del
mismo modelo.

Cada sensor fisico debe quedar asociado a:

- `sensor_id` logico.
- Etiqueta fisica visible.
- MAC de la ESP32 asociada.
- Rol dentro del sistema.
- Archivo de calibracion individual.

## Sincronizacion dual

La sincronizacion entre ambos sensores es un requisito central. El contrato de
datos futuro debe incluir campos que permitan reconstruir el orden temporal entre
sensor, receptor y PC:

- `sensor_id`
- `node_mac`
- `seq`
- `sensor_t_us`
- `receiver_t_us`
- `pc_wall_s`
- `sample_rate_hz`
- `range_g`
- `calibration_id`

## Topologia asumida

La arquitectura inicial asumida para esta migracion es:

1. Dos sensores fisicos SEN-17589 / KX134.
2. Dos ESP32 sensoras independientes, una por cada KX134.
3. Receptor USB/ESP-NOW segun la arquitectura existente del repositorio.
4. Exportacion inequivoca por `sensor_id=1` y `sensor_id=2`.

No se debe inferir `sensor_id` por defecto si falta en el stream. Una muestra sin
identidad explicita debe considerarse invalida para captura dual.

## Decisiones pendientes

- Confirmar si el montaje fisico final tendra tres ESP32 totales
  (dos sensoras + receptor) o solo dos ESP32.
- Si fisicamente solo existen dos ESP32 totales, la arquitectura debe decidirse
  antes de implementar firmware.
- Definir el contrato de datos KX134 v3.
- Definir flujo de calibracion individual.
- Definir politica de sincronizacion y criterios minimos de precheck dual.
- Definir rediseño GUI para duracion manual y frecuencia seleccionable.
