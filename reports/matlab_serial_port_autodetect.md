# MATLAB Serial Port Autodetect

Fecha: 2026-03-31

## Objetivo
Eliminar la dependencia de `COM5` fijo en los flujos MATLAB y permitir que el repositorio identifique automaticamente el puerto del concentrador USB activo.

## Cambio aplicado
- Se agrego `matlab/common/resolve_adxl_serial_port.m`.
- La resolucion del puerto ahora combina:
  - puertos disponibles reportados por `serialportlist`
  - inventario del sistema operativo en Windows (`Win32_SerialPort`)
  - una sonda corta del stream serial para detectar:
    - `# relay=espnow_receiver`
    - `#STAT,relay=receiver`
    - header CSV `seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z`
    - filas CSV ADXL335 validas
- Se integra en:
  - `matlab/live/run_sensorB_live_session.m`
  - `matlab/calibration/capture_single_sensor_baseline.m`
  - `matlab/calibration/capture_sensorC_selftest_pair.m`
  - `matlab/analysis/run_adxl335_fast_bringup.m`

## Criterio operativo
- Si existe una unica firma de relay, se selecciona ese puerto.
- Si no hay firma unica pero solo hay un candidato USB-UART razonable, se selecciona ese puerto.
- Si hay ambiguedad real entre varios candidatos compatibles, el script falla de forma explicita y pide fijar `port="COMx"` manualmente.
- Si el usuario define `port`, ese valor se usa como preferencia, pero el sistema aun puede validar o caer a autodeteccion.

## Uso esperado
Flujo principal sin puerto fijo:

```matlab
run('live_session_hub/sensorB_live_prompt_session.m')
```

Override manual cuando haga falta:

```matlab
port = "COM4";
run('live_session_hub/sensorB_live_prompt_session.m')
```

## Verificacion local
- Validacion CLI MATLAB de helper:
  - `resolve_adxl_serial_port` detecto `COM4`
  - modo: `relay_signature`
- Prueba corta del launcher live:
  - entro por autodeteccion en `COM4`
  - no capturo muestras en 3 s porque no habia trafico CSV activo del transmisor en ese momento
  - la apertura/resolucion del puerto quedo validada; la ausencia de muestras no apunta a fallo del autodetector

## Impacto
- El launcher live deja de romperse cuando Windows reasigna el `COM` del relay.
- El flujo base de captura y el self-test dejan de depender de `COM5`.
- Se mantiene trazabilidad en los archivos de sesion/resumen con:
  - `requested_port`
  - `port`
  - `port_resolution_mode`
  - `port_resolution_detail`
