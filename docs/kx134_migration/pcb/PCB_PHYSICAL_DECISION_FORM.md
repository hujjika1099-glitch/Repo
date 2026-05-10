# Formulario de decisiones fisicas para PCB/baquelada KX134

## Instruccion de uso

Vamos a cerrar decisiones fisicas para PCB/baquelada. Si una decision no esta definida, responda `PENDING`. No se autorizara PCB si quedan decisiones criticas pendientes.

Este formulario registra el estado actual del levantamiento. En esta ejecucion no se recibieron respuestas cerradas del usuario para las decisiones criticas, por lo que se documentan como `pending`.

## Preguntas minimas realizadas

### A. Alimentacion

1. La alimentacion final sera por USB en cada ESP32, por fuente externa comun o por otra opcion?
2. El receptor seguira alimentado por el USB del PC?
3. Las ESP32 sensoras tendran alimentacion independiente o compartida?
4. Se requiere proteccion contra inversion de polaridad o sobrecorriente?
5. Hay tension/corriente objetivo definida?

### B. Conectores

6. Que conector se usara entre KX134 y ESP32 sensora?
7. Se conservara Qwiic/I2C cableado o se soldara directo a PCB?
8. Se requiere conector desmontable?
9. Hay preferencia por tornillos, JST, Dupont, bornera u otro?

### C. Cableado

10. Longitud estimada del cable Sensor 1?
11. Longitud estimada del cable Sensor 2?
12. Longitud entre receptor y PC?
13. Se requiere cable blindado?
14. Debe haber alivio de tension?

### D. Montaje

15. Donde se fijara Sensor 1?
16. Donde se fijara Sensor 2?
17. Como se fijara cada sensor?
18. La ESP32 sensora ira junto al sensor o separada?
19. Se usara caja?
20. Debe quedar acceso fisico a EN/BOOT/USB?

### E. Orientacion

21. Cual sera la orientacion fisica final del eje X/Y/Z para Sensor 1?
22. Cual sera la orientacion fisica final del eje X/Y/Z para Sensor 2?
23. Se requiere marcar ejes en carcasa o PCB?
24. La orientacion debe coincidir con coordenadas del cliente?

### F. Receptor

25. Donde estara el receptor?
26. El receptor estara conectado siempre al PC?
27. Se requiere caja para receptor?
28. Se requiere indicador LED externo?

### G. Cliente/uso

29. El cliente requiere dimensiones maximas?
30. El cliente requiere acabado o estetica particular?
31. El sistema debe ser portatil?
32. Se espera operar en ambiente con polvo/humedad/golpes?

## Tabla de decisiones

| Decision | Valor actual | Estado | Responsable | Evidencia | Comentario |
|---|---|---|---|---|---|
| Fuente final de alimentacion | PENDING | pending | Cliente/equipo hardware | Sin respuesta cerrada | Critico para PCB |
| Tension objetivo | PENDING | pending | Cliente/equipo hardware | Sin respuesta cerrada | Critico para seleccion electrica |
| Corriente estimada | PENDING | pending | Equipo hardware | Sin respuesta cerrada | Critico para proteccion |
| Proteccion inversion/sobrecorriente | PENDING | pending | Cliente/equipo hardware | Sin respuesta cerrada | Critico si hay fuente externa |
| Conector de alimentacion | PENDING | pending | Cliente/equipo hardware | Sin respuesta cerrada | Critico |
| Alimentacion USB por ESP32 o fuente comun | PENDING | pending | Cliente/equipo hardware | Sin respuesta cerrada | Critico |
| Receptor alimentado por USB del PC | PENDING | pending | Cliente/equipo hardware | Sin respuesta cerrada | Critico |
| Tres ESP32 separadas | Mantener arquitectura actual | closed | Proyecto | `config/kx134_node_map.json` | Arquitectura validada |
| Cada nodo sensor tendra caja propia | PENDING | pending | Cliente/equipo mecanico | Sin respuesta cerrada | Critico mecanico |
| Receptor en caja separada | PENDING | pending | Cliente/equipo mecanico | Sin respuesta cerrada | Critico mecanico |
| Sensores integrados a ESP32 o separados por cable | PENDING | pending | Cliente/equipo hardware | Sin respuesta cerrada | Critico por I2C/montaje |
| Conector KX134-ESP32 | PENDING | pending | Cliente/equipo hardware | Sin respuesta cerrada | Critico |
| Conector USB | Mantener USB de desarrollo por ahora | pending | Cliente/equipo hardware | Prototipo actual | Falta definir version final |
| Conector de servicio | PENDING | pending | Cliente/equipo hardware | Sin respuesta cerrada | Critico para mantenimiento |
| Polarizacion/muesca/seguro mecanico | PENDING | pending | Cliente/equipo hardware | Sin respuesta cerrada | Critico para evitar inversion |
| Longitud cable Sensor 1 | PENDING | pending | Cliente | Sin respuesta cerrada | Critico |
| Longitud cable Sensor 2 | PENDING | pending | Cliente | Sin respuesta cerrada | Critico |
| Longitud receptor-PC | PENDING | pending | Cliente | Sin respuesta cerrada | Critico |
| Tipo de cable | PENDING | pending | Cliente/equipo hardware | Sin respuesta cerrada | Critico |
| Blindaje | PENDING | pending | Cliente/equipo hardware | Sin respuesta cerrada | Depende del ambiente |
| Alivio de tension | PENDING | pending | Cliente/equipo mecanico | Sin respuesta cerrada | Critico para vibracion |
| Superficie de montaje | PENDING | pending | Cliente | Sin respuesta cerrada | Critico |
| Tornillos/separadores/adhesivo/caja | PENDING | pending | Cliente/equipo mecanico | Sin respuesta cerrada | Critico |
| Proteccion contra vibracion | PENDING | pending | Cliente/equipo mecanico | Sin respuesta cerrada | Critico |
| Acceso a reset/boot/USB | PENDING | pending | Cliente/equipo mecanico | Sin respuesta cerrada | Critico para servicio |
| Orientacion final Sensor 1 | PENDING | pending | Cliente/equipo mecanico | Sin respuesta cerrada | Critico |
| Orientacion final Sensor 2 | PENDING | pending | Cliente/equipo mecanico | Sin respuesta cerrada | Critico |
| Marca visible X/Y/Z | PENDING | pending | Cliente/equipo mecanico | Sin respuesta cerrada | Critico |
| Relacion con estructura del cliente | PENDING | pending | Cliente | Sin respuesta cerrada | Critico |
| Ubicacion Sensor 1 | PENDING | pending | Cliente | Sin respuesta cerrada | Critico |
| Ubicacion Sensor 2 | PENDING | pending | Cliente | Sin respuesta cerrada | Critico |
| Ubicacion receptor | PENDING | pending | Cliente | Sin respuesta cerrada | Critico |
| Distancia entre sensores | PENDING | pending | Cliente | Sin respuesta cerrada | Critico |
| Distancia receptor-PC | PENDING | pending | Cliente | Sin respuesta cerrada | Critico |
| Reprogramacion ESP32 | Mantener acceso USB/BOOT requerido | pending | Equipo hardware | Regla de mantenimiento | Falta forma mecanica final |
| Reemplazo sensor | Debe permitir recalibracion | pending | Equipo hardware | Criterios PCB | Falta mecanismo final |
| Identificacion fisica | Etiquetas Sensor 1/Sensor 2/Receptor requeridas | pending | Cliente/equipo mecanico | Reglas del proyecto | Falta diseno final |
| Temperatura esperada | PENDING | pending | Cliente | Sin respuesta cerrada | Ambiental |
| Humedad/polvo/golpes | PENDING | pending | Cliente | Sin respuesta cerrada | Ambiental |
| Dimensiones maximas | PENDING | pending | Cliente | Sin respuesta cerrada | Critico |
| Peso | PENDING | pending | Cliente | Sin respuesta cerrada | Cliente |
| Estetica/material de caja | PENDING | pending | Cliente | Sin respuesta cerrada | Cliente |
| Cableado visible/no visible | PENDING | pending | Cliente | Sin respuesta cerrada | Cliente |
