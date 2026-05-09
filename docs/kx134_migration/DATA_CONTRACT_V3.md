# Contrato de datos KX134 v3

## 1. Proposito

Este contrato define la forma futura de los datos para la fase SEN-17589/KX134. Reemplaza conceptualmente el contrato ADXL335 para la migracion, pero no elimina ni modifica todavia los archivos, firmware, GUI, CSV o manuales existentes de ADXL335.

## 2. Alcance

Aplica a:

- Firmware de nodos sensores.
- Receptor.
- Comunicacion serial hacia PC.
- GUI.
- Exportacion CSV.
- Metadata de sesion.
- Calibracion individual.
- Sincronizacion basica.

No aplica a:

- Analisis profundo de vibracion.
- Filtros avanzados.
- Diagnostico fisico avanzado.
- Calculo de metricas estructurales.
- Interpretacion del cliente final.

## 3. Diferencia ADXL335 vs KX134

ADXL335 era un sensor analogico: el sistema leia ADC en la ESP32, exportaba cuentas raw y milivoltios, y luego estimaba g con sensibilidad nominal en mV/g. KX134 es digital: el firmware debe leer cuentas digitales del sensor y conservarlas como dato crudo.

Para KX134 no se deben usar voltajes ni milivoltios. El flujo KX134 debe entregar cuentas crudas digitales por eje y una conversion basica a g. Los campos `mv_*` y `gx_est/gy_est/gz_est/g_norm_est` deben retirarse del flujo KX134.

## 4. Identificacion de sensores

`sensor_id=1` y `sensor_id=2` son obligatorios. `physical_label` debe mapearse a una etiqueta fisica visible en cada sensor. `node_mac` debe conservarse para asociar cada muestra con la ESP32 correcta.

`sensor_id` no debe inferirse. Una linea sin `sensor_id` debe marcarse invalida. Cada sensor tendra calibracion individual, asociada a `sensor_id`, `node_mac` y `calibration_id`.

La arquitectura fisica cerrada se documenta en `docs/kx134_migration/ARCHITECTURE_V1.md`: tres ESP32 totales, dos nodos sensores y un receptor Serial USB.

## 5. Campos del contrato

| Campo | Tipo | Fuente | Unidad | Obligatorio | Crudo/Derivado/Metadata | Descripcion |
|------|------|--------|--------|-------------|--------------------------|-------------|
| `protocol_version` | string | sensor_node | none | si | metadata | Identificador del protocolo KX134 usado por el stream o fila. |
| `session_id` | string | pc_gui | none | si | metadata | Identificador unico de la sesion de captura. |
| `sensor_id` | integer | sensor_node | none | si | metadata | Identificador logico obligatorio, solo 1 o 2. |
| `physical_label` | string | pc_gui | none | si | metadata | Etiqueta fisica visible del sensor. |
| `node_id` | string | sensor_node | none | si | metadata | Identificador logico estable de la ESP32 sensora. |
| `node_mac` | string | sensor_node | MAC address | si | metadata | MAC de la ESP32 asociada al sensor. |
| `seq` | unsigned_integer | sensor_node | count | si | metadata | Contador monotono por nodo sensor. |
| `sensor_t_us` | unsigned_integer | sensor_node | microseconds | si | metadata | Timestamp del nodo sensor cercano a la adquisicion. |
| `receiver_t_us` | unsigned_integer | receiver | microseconds | si | metadata | Timestamp del receptor al recibir el paquete. |
| `pc_wall_s` | number | pc_gui | seconds | si | metadata | Tiempo relativo del PC al parsear o escribir la muestra. |
| `sync_group_id` | string | receiver | none | si | metadata | Grupo de sincronizacion para comparar ambos sensores. |
| `pair_seq` | integer | receiver | count | si | metadata | Secuencia futura para parear muestras de sensor 1 y sensor 2. |
| `x_raw` | signed_integer | sensor_node | digital_counts | si | raw | Dato crudo digital del eje X. |
| `y_raw` | signed_integer | sensor_node | digital_counts | si | raw | Dato crudo digital del eje Y. |
| `z_raw` | signed_integer | sensor_node | digital_counts | si | raw | Dato crudo digital del eje Z. |
| `x_g` | number | derived | g | si | derived_basic_unit_conversion | Conversion basica del eje X a g. |
| `y_g` | number | derived | g | si | derived_basic_unit_conversion | Conversion basica del eje Y a g. |
| `z_g` | number | derived | g | si | derived_basic_unit_conversion | Conversion basica del eje Z a g. |
| `sample_rate_hz` | integer | sensor_node | Hz | si | metadata | Frecuencia solicitada o configurada para la muestra. |
| `odr_hz` | integer | sensor_node | Hz | si | metadata | Output data rate configurado en el KX134. |
| `range_g` | integer | sensor_node | g | si | metadata | Rango de medicion usado para convertir raw a g. |
| `calibration_id` | string | derived | none | si | metadata | Identificador de calibracion individual aplicada o declarada. |
| `calibration_applied` | boolean | derived | none | si | metadata | Indica si se aplicaron coeficientes validos. |
| `packet_status` | string | receiver | none | si | diagnostic | Estado de validacion de paquete o fila. |
| `packet_error_code` | string | receiver | none | si | diagnostic | Codigo de diagnostico conservado cuando aplique. |
| `firmware_version` | string | sensor_node | none | si | metadata | Version de firmware del nodo sensor. |
| `contract_version` | string | sensor_node | none | si | metadata | Version de contrato declarada por el emisor. |

## 6. Encabezado CSV KX134

Encabezado exacto:

```text
protocol_version,session_id,sensor_id,physical_label,node_id,node_mac,seq,sensor_t_us,receiver_t_us,pc_wall_s,sync_group_id,pair_seq,x_raw,y_raw,z_raw,x_g,y_g,z_g,sample_rate_hz,odr_hz,range_g,calibration_id,calibration_applied,packet_status,packet_error_code,firmware_version,contract_version
```

Este encabezado no debe mezclarse con encabezados ADXL335. No se permite `mv_x/mv_y/mv_z`. No se permite `gx_est/gy_est/gz_est/g_norm_est`. La GUI futura debe rechazar o marcar invalidos los streams que no cumplan el contrato.

## 7. Conversion basica a g

Raw esperado: `signed int16`.

Formula no calibrada:

```text
axis_g_uncalibrated = axis_raw * range_g / 32768.0
```

Formula calibrada:

```text
axis_g = (axis_g_uncalibrated - offset_axis_g) * scale_axis
```

La formula debe verificarse contra la libreria KX134 usada en firmware. No se deben aplicar filtros. No se debe reemplazar el dato crudo. La conversion a g no es analisis profundo.

## 8. Calibracion

La calibracion debe ser individual por sensor y debe asociarse a `sensor_id` y `node_mac`. La referencia operativa sera `calibration_id`. No se permite compartir calibracion entre sensores.

Los datos `x_raw/y_raw/z_raw` deben conservarse siempre. `calibration_applied` indica si se aplicaron coeficientes validos.

Archivos futuros esperados:

- `config/calibrations/kx134_sensor_1.json`
- `config/calibrations/kx134_sensor_2.json`

## 9. Sincronizacion

`sensor_t_us` viene del nodo sensor. `receiver_t_us` viene del receptor al recibir paquete. `pc_wall_s` viene del PC/GUI. `pc_wall_s` no debe usarse como unica base de sincronizacion.

`pair_seq` y `sync_group_id` se usaran en tickets futuros para agrupar muestras de ambos sensores. `seq` debe ser trazable por sensor.

La ruta de comunicacion cerrada para este contrato es: ESP32 sensora 1 y ESP32 sensora 2 envian por ESP-NOW a una ESP32 receptora; la receptora envia el stream a la aplicacion por Serial USB. La arquitectura de solo dos ESP32 no esta seleccionada para esta fase.

## 10. Frecuencia de muestreo

Frecuencias permitidas: 100, 200, 400 y 800 Hz. El valor default es 100 Hz.

La GUI futura debe permitir seleccionar una de esas opciones. El firmware futuro debera aceptar o reportar la frecuencia efectiva. `sample_rate_hz` debe exportarse.

La opcion 800 Hz queda permitida por contrato, pero su configuracion final debe validarse en firmware y puede requerir modo High-Performance segun la libreria KX134 usada.

## 11. Duracion de captura

La duracion de sesion futura debe ser manual. Debe aceptar enteros positivos en segundos, por ejemplo 10 y 1567. No debe depender exclusivamente de tiempos predefinidos. Debe guardarse en metadata de sesion como `capture_duration_s`.

## 12. Reglas de validacion

- `sensor_id` obligatorio.
- `node_mac` obligatorio.
- `seq` obligatorio.
- Timestamps obligatorios.
- `sample_rate_hz` debe pertenecer a 100, 200, 400 o 800.
- `range_g` debe pertenecer a 8, 16, 32 o 64.
- No inferir `sensor_id`.
- No inferir `node_mac`.
- No aceptar campos ADXL335 en stream KX134.
- Conservar errores de paquete.
- Marcar lineas incompletas.
- `pc_wall_s` no debe ser la unica fuente de sincronizacion.

## 13. Campos prohibidos para KX134

- `mv_x`
- `mv_y`
- `mv_z`
- `gx_est`
- `gy_est`
- `gz_est`
- `g_norm_est`
- `voltage_x`
- `voltage_y`
- `voltage_z`
- `millivolts_x`
- `millivolts_y`
- `millivolts_z`

## 14. Implicaciones para proximos tickets

- Firmware: debe emitir contrato KX134 v3, raw digital, conversion basica a g, identidad y timestamps.
- Receptor: debe preservar `node_mac`, agregar `receiver_t_us`, validar paquetes y no desalinear headers.
- GUI: debe rechazar streams sin `sensor_id`, no inferir identidad y dejar de usar mV para KX134.
- Exportacion CSV: debe usar el encabezado KX134 exacto y metadata de sesion futura.
- Calibracion: debe usar archivos individuales por sensor y MAC.
- Empaquetado: debe esperar a que la GUI y nombres KX134 esten estabilizados antes de renombrar o ajustar distribucion.

## 15. Decisiones pendientes

- Confirmar MAC fisica de ESP32 sensora 1.
- Confirmar MAC fisica de ESP32 sensora 2.
- Confirmar MAC fisica de ESP32 receptora.
- Confirmar rango g inicial.
- Confirmar libreria KX134 a usar.
- Confirmar si GUI configurara firmware en tiempo real o solo guardara configuracion esperada inicialmente.
- Confirmar etiquetas fisicas de sensores.
- Confirmar estrategia exacta de `pair_seq` y `sync_group_id`.

Decision cerrada: se usaran tres ESP32 totales, con I2C/Qwiic como interfaz objetivo inicial para cada SEN-17589/KX134. SPI queda como alternativa no seleccionada salvo decision futura explicita.
