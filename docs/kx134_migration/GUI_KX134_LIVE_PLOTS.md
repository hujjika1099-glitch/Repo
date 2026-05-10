# GUI KX134 live plots

## Objetivo

El modo KX134 ahora muestra retroalimentacion grafica durante la captura para que el operador pueda ver cambios de aceleracion, taps suaves y presencia de ambos sensores sin esperar a que termine la sesion.

## Que se grafica

- Sensor 1: `x_g`, `y_g`, `z_g`.
- Sensor 2: `x_g`, `y_g`, `z_g`.
- Comparacion visual `|g|` entre Sensor 1 y Sensor 2.
- Comparacion de un eje seleccionado (`X`, `Y` o `Z`) entre Sensor 1 y Sensor 2.

`|g|` se calcula solo para visualizacion como `sqrt(x_g^2 + y_g^2 + z_g^2)`. No se exporta como columna CSV, no se llama `g_norm_est` y no participa en analisis profundo.

## Uso

1. Abra `python -m gui.kx134_live_gui`.
2. Configure puerto, baudrate, duracion, frecuencia esperada y nombre de sesion.
3. Abra la pestana `Graficas`.
4. Inicie captura.
5. Observe los ejes por sensor, la comparacion `|g|` y el eje comparado.
6. Use `Ventana visible` para elegir 10, 20, 30 o 60 segundos.
7. Use `Limpiar grafica` para reiniciar solo la vista.
8. Use `Pausar vista` para congelar la visualizacion sin pausar captura.

## Garantias de datos

- Las graficas no filtran datos exportados.
- Las graficas no suavizan datos exportados.
- Las graficas no agregan `g_norm`, `g_norm_est`, `mv_*`, voltajes ni milivoltios al CSV.
- La exportacion KX134 v3 endurecida se mantiene por el core.
- Los datos crudos `x_raw`, `y_raw`, `z_raw` y los valores calibrados `x_g`, `y_g`, `z_g` se conservan tal como llegan del receptor.

## Recomendaciones de prueba

- Deje los sensores quietos unos segundos para observar la linea base.
- Aplique 2 o 3 taps suaves, separados, sobre la misma superficie.
- No use golpes fuertes.
- Verifique que Sensor 1 y Sensor 2 cambien durante los taps.

## Limitaciones

- La grafica es una ayuda visual operativa, no analisis profundo de vibracion.
- El envio de configuracion `sample_rate_hz` al firmware sigue pendiente.
- El empaquetado Windows sigue pendiente.
