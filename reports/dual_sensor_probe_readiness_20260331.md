# Evaluacion de Readiness - Corridas `probe1` a `probe4`

Fecha: 2026-03-31

## Objetivo
Evaluar si las corridas live dual-sensor tipo `probe` ya tienen integridad suficiente para analisis rigurosos de comparacion dinamica entre `sensor_B` y `sensor_A`.

## Evidencia encontrada
- `probe1`: sin archivos guardados en `data/raw/`, `data/processed/` o `reports/analysis_outputs/`
- `probe2`: [reports/analysis_outputs/probe2_live_20260331_111438_summary.txt](/c:/Users/JOSE%20DAVID/Desktop/-/Aplicaciones/UQ_2021_2025/AYUDA/Maestria/Repo/reports/analysis_outputs/probe2_live_20260331_111438_summary.txt)
- `probe3`: sin archivos guardados en `data/raw/`, `data/processed/` o `reports/analysis_outputs/`
- `probe4`: [reports/analysis_outputs/probe4_live_20260331_111716_summary.txt](/c:/Users/JOSE%20DAVID/Desktop/-/Aplicaciones/UQ_2021_2025/AYUDA/Maestria/Repo/reports/analysis_outputs/probe4_live_20260331_111716_summary.txt)

## Hallazgos principales
1. `probe1` y `probe3` no son utilizables como evidencia tecnica porque no dejaron artefactos persistidos.
2. `probe2` no es apta para analisis riguroso:
   - `sensor_1` (`sensor_B`) queda en `fail`.
   - `raw_y=0` y `raw_z=0` en el 100% de las muestras del sensor 1.
   - `mv_y=142` y `mv_z=142` en el 100% de las muestras del sensor 1.
   - Esto indica perdida casi total de dos ejes o un problema severo de cableado/ADC en el transmisor 1.
3. `probe4` tampoco es apta para analisis riguroso:
   - `sensor_1` queda en `fail` por saturacion.
   - `sensor_2` queda en `fail` por `g_norm_implausible`.
   - Ambos sensores muestran al menos un retroceso en `seq` y `t_us`, compatible con reinicio o reset del transmisor durante la corrida.
   - El resumen global queda con `stream_duration_s` negativo, por lo que no debe usarse como frecuencia valida de sesion.
4. La comparacion cruzada entre sensores todavia no es estable:
   - `probe2`: `sensor_2` parece razonable, pero `sensor_1` esta fisicamente incoherente.
   - `probe4`: ambos sensores presentan comportamiento anomalo dentro de la misma corrida.

## Diagnostico tecnico
La evidencia actual no soporta un uso riguroso de estas corridas para analisis dinamico fino, correlacion inter-sensor, ni extraccion de metricas comparativas confiables.

El principal bloqueo no parece estar en MATLAB sino en la integridad de adquisicion:
- `sensor_1` muestra ejes muertos o desconectados en `probe2`.
- En `probe4` hay indicios de reinicio parcial o perdida de continuidad temporal.
- La variacion observada entre corridas no es solo variabilidad de movimiento; es inconsistencia del sistema de medicion.

## Decision actual
- `sensor_B`: `suspect` a nivel de sistema dual actual, porque una corrida lo muestra con dos ejes muertos y otra con saturacion/reset.
- `sensor_A`: `suspect` a nivel de sistema dual actual, porque aunque `probe2` se ve razonable, `probe4` cae en `g_norm_implausible` y ademas presenta reset temporal.
- Estado del montaje dual para analisis riguroso: `fail`

## Recomendacion
No avanzar aun a analisis rigurosos con `probe2` y `probe4`.

Primero se debe endurecer el protocolo de captura y la verificacion previa de integridad.

## Protocolo minimo mas riguroso recomendado
1. Verificacion estatica previa de 10 s por sensor antes de toda corrida:
   - revisar que `raw_x/raw_y/raw_z` cambien
   - rechazar de inmediato cualquier eje pegado en `0` o `142 mV`
2. Verificacion de continuidad temporal por sensor:
   - `seq_jumps = 0`
   - sin retrocesos de `seq`
   - sin retrocesos de `t_us`
3. Corridas controladas por repeticion:
   - minimo 3 corridas replicadas con el mismo gesto
   - mismo montaje, misma orientacion inicial y mismo operador
4. Criterio de aceptacion previo al analisis:
   - ambos sensores con tres ejes activos
   - sin saturacion ADC relevante
   - `g_norm_median` en rango plausible por sensor
   - frecuencias por sensor cercanas a 100 Hz y estables entre corridas
5. Solo despues de pasar esos filtros:
   - comparar forma temporal entre sensores
   - calcular correlacion, retraso relativo y amplitud

## Siguiente paso recomendado
Ejecutar una fase corta de "integridad dual" antes de cualquier nueva campana de movimiento. Esa fase debe rechazar automaticamente corridas con ejes muertos, saturacion o resets, y solo guardar como candidatas las sesiones que superen esos controles.
