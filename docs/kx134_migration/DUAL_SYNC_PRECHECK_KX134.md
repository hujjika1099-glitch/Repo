# Precheck de sincronizacion dual KX134

## Objetivo

Validar que el firmware KX134 dual ESP-NOW entrega dos streams paralelos de Sensor 1 y
Sensor 2 con continuidad suficiente para la siguiente etapa de integracion en GUI y
exportacion KX134.

Este precheck no reemplaza un analisis dinamico profundo. Su proposito es confirmar
integridad operativa inicial, emparejamiento temporal practico y diagnostico de
duplicados antes de conectar el stream a la aplicacion de escritorio.

## Bring-up ESP-NOW vs precheck de sincronizacion

El bring-up ESP-NOW demuestra que los nodos transmiten, que el receptor recibe, que el
contrato CSV KX134 v3 se respeta y que los contadores no presentan perdidas evidentes.

El precheck de sincronizacion agrega dos preguntas nuevas:

- si las muestras de ambos sensores pueden emparejarse razonablemente en el receptor;
- si un evento fisico comun aparece en ambos sensores con un desfase compatible con una
  primera integracion de captura dual.

## Base temporal usada

Para esta fase se usa `receiver_t_us` como base practica de emparejamiento. Ese campo
sale del reloj del receptor USB y mide cuando el paquete ya esta disponible en la ESP32
receptora para serializarlo hacia el PC.

`sensor_t_us` sigue siendo util para frecuencia efectiva y continuidad dentro de cada
sensor individual. Sin embargo, los dos sensores son ESP32 distintas y sus relojes no
estan sincronizados directamente. Por eso no se debe interpretar una resta directa entre
`sensor_t_us` de Sensor 1 y Sensor 2 como desfase fisico absoluto.

## Procedimiento estatico

1. Alimentar ambas ESP32 sensoras, cada una conectada a su KX134.
2. Conectar la ESP32 receptora al PC por USB.
3. Colocar ambos sensores quietos sobre una superficie estable, idealmente con la misma
   orientacion.
4. Capturar 30 s de Serial directo, sin PlatformIO monitor.
5. Analizar continuidad, frecuencia, duplicados y emparejamiento por `receiver_t_us`.

Criterios esperados:

- ambos sensores presentes;
- al menos 1000 filas por sensor en 30 s;
- frecuencia efectiva entre 98 y 102 Hz por sensor;
- `seq_gaps = 0` como resultado preferido;
- `receiver_t_us` monotono por sensor;
- `packet_status=OK` y `packet_error_code=OK`;
- `invalid=0` y `queue_drops=0` cuando el receptor reporte estadisticas.

## Procedimiento con evento comun

1. Colocar ambos sensores sobre la misma superficie o pieza rigida.
2. Iniciar captura de 30 s.
3. Esperar aproximadamente 5 s.
4. Aplicar 3 taps suaves, separados por unos 2 s.
5. Dejar los sensores quietos hasta terminar.

El analizador usa internamente la norma de aceleracion para detectar cambios bruscos.
No agrega `g_norm` ni columnas derivadas al CSV de transporte.

Criterios esperados:

- ambos sensores presentes;
- al menos un evento detectado en ambos sensores;
- desfase del primer evento por `receiver_t_us` menor o igual a 30 ms para esta primera
  validacion;
- documentar el valor real sin afirmar sincronizacion definitiva del sistema completo.

## Diagnostico de duplicados

Los duplicados se revisan en cuatro niveles:

- linea completa repetida;
- `sensor_id + seq`;
- `sensor_id + seq + sensor_t_us`;
- `sensor_id + seq + receiver_t_us`.

Clasificaciones usadas:

- `DUPLICATES_NOT_OBSERVED`: no aparecen duplicados en captura directa.
- `DUPLICATES_CAPTURE_ARTIFACT_LIKELY`: lineas completas repetidas con el mismo
  `receiver_t_us`, compatible con artefacto de monitor/log.
- `DUPLICATES_RECEIVER_STREAM_LIKELY`: mismo `sensor_id + seq` con `receiver_t_us`
  diferente o `pair_seq` diferente, compatible con doble emision/reprocesamiento en el
  stream del receptor.
- `DUPLICATES_UNRESOLVED`: evidencia insuficiente para clasificar.

Si los duplicados no aparecen en captura directa, o aparecen como artefacto de captura,
no se modifica firmware. La GUI/exportacion debera conservar raw logs y diagnosticar
duplicados por `sensor_id + seq + node_mac`.

Si se confirma doble emision real del receptor y la causa en firmware es clara, se puede
hacer una correccion acotada en el firmware dual y repetir la prueba.

## Criterios de aceptacion

`READY_FOR_GUI_KX134_STREAM_INTEGRATION = YES` requiere:

- prueba estatica aprobada;
- prueba con evento comun aprobada;
- duplicados diagnosticados como no bloqueantes o corregidos;
- ambos sensores conservan 100 Hz nominales;
- `receiver_t_us` valido;
- ausencia de campos ADXL335 prohibidos: `mv_x`, `mv_y`, `mv_z`, `gx_est`, `gy_est`,
  `gz_est`, `g_norm_est`, `voltage`, `millivolts`.

## Limitaciones

- El desfase por `receiver_t_us` incluye recepcion ESP-NOW, cola interna y serializacion.
- Un evento comun corto no caracteriza vibracion, fase ni respuesta dinamica fina.
- Los relojes de Sensor 1 y Sensor 2 no estan sincronizados entre si.
- La validacion no implementa todavia GUI ni exportacion KX134.

## Siguiente paso

Si el precheck aprueba, el siguiente ticket recomendado es integrar el stream Serial
KX134 v3 en la GUI sin alterar la exportacion historica ADXL335.
