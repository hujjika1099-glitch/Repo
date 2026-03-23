# Reglas Operativas del Proyecto

## Principios de calibracion y validacion
1. La calibracion es por sensor individual, no por nodo.
2. Siempre se usa una sola ESP32 de referencia para comparar sensores en validacion individual.
3. No se debe asumir que dos modulos con la misma referencia comercial son equivalentes.

## Reglas de datos
1. `data/raw/` es evidencia primaria y no se sobrescribe.
2. El procesamiento se realiza sobre copias derivadas en `data/processed/`.
3. Todo analisis tecnico debe generar un reporte en `reports/`.

## Criterio de decision por sensor
- `pass`: comportamiento consistente y dentro de criterios aceptables.
- `suspect`: resultado ambiguo o con variabilidad que exige repetir prueba o revisar montaje.
- `fail`: incoherencia fisica o desviacion no aceptable.

## Politica de integridad tecnica
1. Si un sensor es fisicamente incoherente, se declara como tal.
2. No se permite maquillar por software una inconsistencia fisica del sensor.
3. Todo cambio importante en repositorio, metodologia o criterio debe registrarse en `reports/change_log.md`.

## Estado operativo vigente (resumen)
1. `sensor_B` es la fuente operativa primaria.
2. `sensor_A` queda como backup.
3. `sensor_C` queda como referencia historica/provisional.
4. `sensor_D` queda descartado.

## Regla de ejecucion live actual
1. Priorizar ejecucion en una sola instancia de MATLAB para pruebas repetidas.
2. Usar launcher interactivo:
   - `run('live_session_hub/sensorB_live_prompt_session.m')`
3. Evitar abrir nuevas instancias de MATLAB por cada corrida cuando no sea necesario.
