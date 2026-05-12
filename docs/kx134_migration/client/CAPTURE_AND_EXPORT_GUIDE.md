# Guia de captura y exportacion KX134

## Iniciar captura

1. Abra `Sistema_Captura_Acelerometria.exe`.
2. Abra KX134 Dual Capture.
3. Seleccione puerto COM del Receptor.
4. Confirme baudrate `921600`.
5. Configure duracion.
6. Seleccione frecuencia esperada `100 Hz`.
7. Inicie captura.

## Duracion

- 10 segundos: prueba rapida.
- 20 segundos: prueba con observacion de graficas.
- 60 segundos: validacion de prototipo.
- Otros valores positivos son aceptados por la GUI.

## Frecuencia esperada

La GUI permite 100/200/400/800. La configuracion validada del prototipo es `100 Hz`, `odr_hz=100` y `range_g=8 g`.

La GUI todavia no envia configuracion `sample_rate_hz` al firmware. Ese envio GUI->firmware sigue pendiente.

## Graficas en vivo

Durante captura, revise:

- Sensor 1 `x_g/y_g/z_g`.
- Sensor 2 `x_g/y_g/z_g`.
- Comparacion visual `|g|`.
- Eje seleccionado Sensor 1 vs Sensor 2.

Los taps suaves o movimientos controlados deben verse como cambios en las graficas. No use golpes fuertes.

`|g|` es solo visual y no altera CSV, JSON ni summary.

## Al finalizar

La GUI muestra rutas de:

- CSV raw.
- Session JSON.
- Summary MD.

Revise que Sensor 1 y Sensor 2 tengan muestras, que `invalid_lines` sea idealmente 0 y que `duplicate_keys` sea idealmente 0.

## Buenas practicas

- Mantenga sensores quietos al inicio.
- Haga movimientos suaves.
- Evite cables sueltos.
- Anote puerto COM, duracion, frecuencia esperada y observaciones.

## Si no aparecen datos

- Revise alimentacion de Sensor 1 y Sensor 2.
- Revise que el Receptor este conectado al PC.
- Presione reset EN/RST del Receptor si el puerto aparece pero no hay stream.
- Cierre otros programas que usen el COM.
- Repita una captura corta.

## Estado PCB

La baquelada RevA fue completada y validada como funcional por el experto del proyecto. Esta aceptada para uso de prototipo. Si el cliente requiere fabricacion repetible o produccion industrial, se debe preparar un paquete adicional de DFM, BOM final, Gerbers y QA de manufactura.
