# Pendientes y riesgos abiertos

## Bloqueantes para PCB

- Alimentacion final no definida.
- Conectores finales para sensores no definidos.
- Longitudes finales de cable no definidas.
- Montaje mecanico final no definido.
- Orientacion fisica de ejes no definida en carcasa/PCB.
- Ubicacion final de receptor y nodos sensores no definida.

## No bloqueantes para prototipo

- Icono corporativo pendiente.
- Firma digital pendiente.
- Scaling Windows 125/150% pendiente.
- Captura hardware en PC externo no ejecutada.
- `sample_rate_hz` no configurable desde GUI hacia firmware.
- Sensor 1 tuvo 2 `seq_gaps` en la sesion controlada de 60 s.

## Riesgos

- Intercambio fisico accidental de sensores.
- Reemplazo de ESP32 sin actualizar MAC en `node_map`.
- Cambio de `range_g` sin recalibrar.
- Cambio de frecuencia sin revalidar firmware/GUI/exportacion.
- Cables sueltos durante pruebas dinamicas.
- Alimentacion inestable.
- Montaje mecanico que cambie la orientacion de ejes sin documentarlo.

## Mitigaciones

- Etiquetas fisicas Sensor 1 / Sensor 2 / Receptor.
- Mantener `config/kx134_node_map.json` como fuente de verdad.
- Recalibrar si cambia sensor, rango o montaje.
- Ejecutar validacion de sesion despues de cambios fisicos.
- Definir fijacion mecanica antes de PCB.
- Usar checklist de PCB antes de baquelada.
