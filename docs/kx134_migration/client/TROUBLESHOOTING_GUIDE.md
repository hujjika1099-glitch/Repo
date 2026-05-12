# Guia de troubleshooting KX134

## No aparece puerto COM

- Revise cable USB del Receptor.
- Abra Administrador de dispositivos.
- Pruebe otro puerto USB.
- Cierre Arduino IDE, monitores seriales u otras apps que usen el COM.

## El puerto COM aparece pero no hay datos

- Presione EN/RST en el Receptor.
- Espere unos segundos y actualice puertos.
- Confirme baudrate `921600`.
- Verifique que Sensor 1 y Sensor 2 esten alimentados.

## Solo aparece un sensor

- Revise alimentacion del sensor ausente.
- Verifique que Sensor 1 y Sensor 2 no fueron intercambiados.
- Confirme MACs esperadas:
  - Sensor 1: `D4:E9:F4:E9:8E:1C`.
  - Sensor 2: `D4:E9:F4:C3:37:14`.
- Repita captura corta de 10 segundos.

## Sensor 1/Sensor 2 invertidos

- Detenga la prueba.
- Revise etiquetas fisicas.
- No edite CSV manualmente.
- Si se reemplazo hardware, actualizar `config/kx134_node_map.json` y recalibrar.

## Datos no cambian al mover

- Revise conexion fisica del KX134.
- Pruebe movimiento suave.
- Revise que la grafica activa sea del sensor correcto.
- Si cambio `range_g`, recalibrar.

## Graficas no se actualizan

- Revise que la captura este corriendo.
- Revise que la vista no este pausada.
- Confirme que llegan muestras por Sensor 1 y Sensor 2.
- Ejecute una captura corta nueva.

## Exportacion no se genera

- Revise permisos de escritura en la carpeta.
- Use una ruta simple.
- Espere a que termine la captura.
- Copie error, CSV si existe, JSON si existe y summary si existe.

## SmartScreen o antivirus

- El ejecutable no tiene firma digital todavia.
- Confirme origen del paquete antes de continuar.
- Si antivirus elimina el archivo, documente producto antivirus y mensaje exacto.

## GUI se ve cortada

- Maximice la ventana.
- Revise resolucion y scaling.
- Reporte Windows version, resolucion, scaling y captura de pantalla.
- Scaling 125/150 sigue pendiente de validacion formal.

## Secuencia con gaps

- Pocos `seq_gaps` pueden ser advertencia no bloqueante.
- Sensor 1 tuvo 2 gaps en la sesion de 60 s validada.
- Si gaps aumentan, revisar cables, alimentacion y distancia entre nodos.

## Frecuencia fuera de rango

- La configuracion validada es `100 Hz`.
- La GUI muestra 100/200/400/800, pero no configura firmware remotamente.
- Si se requiere otra frecuencia, revalidar firmware, GUI y exportacion.

## Evidencia para soporte

Copie:

- CSV.
- JSON.
- Summary.
- Captura de pantalla.
- Puerto COM.
- Windows version.
- Resolucion y scaling.
- Descripcion de Sensor 1, Sensor 2 y Receptor.

## Estado PCB

La baquelada RevA funcional esta aceptada para uso de prototipo. Si se reemplaza hardware, sensor o ESP32, debe actualizarse `node_map` y recalibrar segun corresponda.

## Cierre Final TICKET 028

- `PROJECT_FUNCTIONAL_COMPLETE = YES`
- `PROTOTYPE_RELEASE_CANDIDATE_READY = YES`
- `BAQUELADA_REVA_FUNCTIONAL_VALIDATED_BY_EXPERT = YES`
- `BAQUELADA_REVA_ACCEPTED_FOR_PROTOTYPE_USE = YES`
- `PRODUCTION_MANUFACTURING_PACKAGE_READY = NO`

La baquelada RevA fue completada fisicamente y validada como funcional por el experto del proyecto. Queda aceptada para uso de prototipo KX134 Sensor 1/Sensor 2. Esto no constituye paquete de fabricacion industrial repetible; si el cliente lo requiere, faltan DFM, BOM final, Gerbers y QA de manufactura.
