# Matriz de decisiones PCB KX134

| Categoria | Decision | Estado | Valor | Bloquea PCB | Responsable | Comentario |
|---|---|---|---|---|---|---|
| Alimentacion | Fuente final | pending | PENDING | si | Cliente/equipo hardware | Definir USB, fuente comun, bateria u otra |
| Alimentacion | Tension y corriente | pending | PENDING | si | Equipo hardware | Necesario para proteccion |
| Alimentacion | Proteccion electrica | pending | PENDING | si | Equipo hardware | Inversion/sobrecorriente |
| Alimentacion | Receptor por USB PC | pending | PENDING | si | Cliente/equipo hardware | Confirmar si se mantiene |
| Conectores | KX134 a ESP32 | pending | PENDING | si | Equipo hardware | Qwiic, soldado, JST, bornera, otro |
| Conectores | Desmontable/polarizado | pending | PENDING | si | Equipo hardware | Evita inversion y facilita mantenimiento |
| Conectores | Servicio/programacion | pending | PENDING | si | Equipo hardware | Acceso USB/BOOT/EN |
| Cableado | Longitud Sensor 1 | pending | PENDING | si | Cliente | Critico para I2C/mecanica |
| Cableado | Longitud Sensor 2 | pending | PENDING | si | Cliente | Critico para I2C/mecanica |
| Cableado | Longitud receptor-PC | pending | PENDING | si | Cliente | Define ubicacion |
| Cableado | Tipo/blindaje | pending | PENDING | si | Cliente/equipo hardware | Segun ambiente |
| Cableado | Alivio de tension | pending | PENDING | si | Equipo mecanico | Critico para vibracion |
| Montaje | Ubicacion Sensor 1 | pending | PENDING | si | Cliente | Critico |
| Montaje | Ubicacion Sensor 2 | pending | PENDING | si | Cliente | Critico |
| Montaje | Metodo de fijacion | pending | PENDING | si | Cliente/equipo mecanico | Tornillos, separadores, adhesivo, caja |
| Montaje | ESP32 junto a sensor o separada | pending | PENDING | si | Equipo hardware | Define cableado |
| Montaje | Caja/carcasa | pending | PENDING | si | Cliente/equipo mecanico | Proteccion |
| Orientacion | Ejes Sensor 1 | pending | PENDING | si | Cliente/equipo mecanico | Debe quedar marcado |
| Orientacion | Ejes Sensor 2 | pending | PENDING | si | Cliente/equipo mecanico | Debe quedar marcado |
| Orientacion | Coordenadas cliente | pending | PENDING | si | Cliente | Interpretacion |
| Receptor | Ubicacion fisica | pending | PENDING | si | Cliente | Distancias |
| Receptor | Caja receptor | pending | PENDING | si | Cliente/equipo mecanico | Proteccion |
| Receptor | LED externo | pending | PENDING | no | Cliente | No bloquea si no requerido |
| Ambiente | Temperatura/humedad/polvo | pending | PENDING | si | Cliente | Define caja/proteccion |
| Ambiente | Vibracion/golpes | pending | PENDING | si | Cliente | Define montaje |
| Servicio | Reprogramacion | pending | PENDING | si | Equipo hardware | Acceso requerido |
| Servicio | Reemplazo/recalibracion | pending | PENDING | si | Equipo hardware | Mantenibilidad |
| Servicio | Etiquetas fisicas | pending | PENDING | si | Cliente/equipo mecanico | Evita intercambio accidental |
| Cliente | Dimensiones/peso | pending | PENDING | si | Cliente | Requisito mecanico |
| Cliente | Estetica/material | pending | PENDING | no | Cliente | Puede bloquear entrega final |
| Cliente | Portabilidad | pending | PENDING | si | Cliente | Afecta energia/caja |
| Cliente | Cableado visible | pending | PENDING | no | Cliente | Afecta instalacion |

## Resultado

- `PCB_PHYSICAL_DECISIONS_COMPLETE = NO`
- `PCB_DESIGN_AUTHORIZED = NO`
