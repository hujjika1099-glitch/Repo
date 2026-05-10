# GUI visual redesign KX134/ADXL

## Objetivo

Preparar la aplicacion para presentacion profesional y para el empaquetado Windows posterior, sin modificar firmware, calibraciones, exportacion KX134 endurecida ni datos historicos.

## Estructura nueva

### Launcher principal

Entrada:

```powershell
python -m gui.app_launcher
```

El launcher muestra dos rutas:

- `KX134 Dual Capture`: flujo actual validado con hardware real y exportacion endurecida.
- `ADXL335 historico`: modulo previo preservado para continuidad operativa.

### GUI KX134

Entrada:

```powershell
python -m gui.kx134_live_gui
```

La ventana KX134 queda organizada en cinco pestañas:

- `Conexion`: puerto, baudrate, estado de enlace y carpeta de salida.
- `Captura`: duracion manual, frecuencia esperada, nombre de sesion e inicio de captura.
- `Sensores`: Sensor 1 y Sensor 2 con MAC, muestras, gaps y estado.
- `Diagnostico`: invalid lines, duplicados, `receiver_t_us`, `pc_wall_s`, packet status y mensajes.
- `Exportacion`: CSV raw, session JSON, summary MD y acciones para copiar/abrir carpeta.

## Criterios responsive

- Tamano inicial: `1180x760`.
- Tamano minimo: `980x640`.
- Layout con `grid` y pesos en contenedores principales.
- Pestañas con `ScrollableFrame` para evitar cortes en pantallas comunes.
- Rutas largas en entradas readonly, no en labels expansivos.
- Botones principales visibles en 1366x768.
- DPI awareness best effort en Windows mediante `ctypes`.

El diseno apunta a:

- 1366x768.
- 1920x1080.
- Windows scaling 125%.
- Windows scaling 150%.

La validacion visual manual en otros PC queda para el ticket de empaquetado/QA.

## Comandos de validacion

```powershell
python -m gui.kx134_live_gui --smoke --close-after-ms 1000
python -m gui.app_launcher --smoke --close-after-ms 1000
python tools\kx134\gui_smoke_test.py --output reports\kx134_gui_validation\TICKET_018_gui_smoke_output.json
```

## Limitaciones

- No se genero `.exe`.
- No se modifico empaquetado.
- No se implemento envio de `sample_rate_hz` al firmware.
- No se cambio firmware.
- No se cambio core/exportacion ADXL335.
- Puede requerir ajuste visual fino despues de pruebas en otros PC y monitores.
