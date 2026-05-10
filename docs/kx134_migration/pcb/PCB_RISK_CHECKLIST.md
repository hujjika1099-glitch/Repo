# Checklist de riesgos fisicos/electricos para PCB KX134

| Riesgo | Severidad | Mitigacion | Estado |
|---|---|---|---|
| Sensor fisico intercambiado | alta | Etiquetas fisicas, `node_map`, checklist pre-prueba | abierto |
| ESP32 sensora intercambiada | alta | Mantener MAC visible y actualizar `node_map` | abierto |
| Longitud I2C excesiva | alta | Definir longitudes, mantener cable corto o integrar sensor | abierto |
| Cable flojo en vibracion | alta | Alivio de tension, conectores seguros, caja | abierto |
| Alimentacion inestable | alta | Definir fuente, corriente y proteccion | abierto |
| GND no comun donde aplique | alta | Regla electrica de diseno y revision previa | abierto |
| Orientacion de eje no marcada | alta | Marcas X/Y/Z en carcasa o PCB | abierto |
| Recalibracion omitida tras cambio fisico | alta | Procedimiento obligatorio de recalibracion | abierto |
| Acceso a USB/BOOT bloqueado | media | Definir ventanas/conectores de servicio | abierto |
| Caja impide disipacion o conexion | media | Validar caja antes de PCB | abierto |
| Conector sin polarizacion | media | Usar conector con muesca/seguro si aplica | abierto |
| Montaje mecanico altera medicion | alta | Definir fijacion rigida y reproducible | abierto |
| Cliente cambia `range_g` | alta | Recalibrar y revalidar | abierto |
| Cliente cambia frecuencia | media | Revalidar firmware, GUI y exportacion | abierto |
| Sensor expuesto a golpes/humedad | alta | Caja, sellado o proteccion definida por ambiente | abierto |

## Riesgo global

El riesgo global para iniciar PCB es alto mientras alimentacion, conectores, cableado, montaje, orientacion y ubicacion sigan `pending`.
