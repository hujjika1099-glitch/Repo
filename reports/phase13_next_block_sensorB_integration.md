# Siguiente Bloque Real - Integracion Operativa con sensor_B

## Objetivo inmediato
Pasar de validacion de modulo a integracion real de uso continuo con `sensor_B` como fuente primaria.

## Alcance minimo (sin caracterizacion nueva)
1. Ejecutar captura operativa de referencia con `sensor_B` (60-120 s).
2. Generar artefacto raw trazable en `data/raw/sensor_B/`.
3. Consumir ese CSV en el modulo de aplicacion/siguiente etapa del proyecto (lectura y transformacion base).
4. Verificar que el pipeline aguas abajo corre sin depender de ST ni de Fase 11.

## Entregable tecnico del bloque
- Script o tarea de integracion que tome el CSV de `sensor_B` y produzca salida util para el siguiente modulo del proyecto (sin recalibrar).

## Criterio de cierre del bloque
- Integracion ejecutada de extremo a extremo al menos una vez con `sensor_B`.
- Si `sensor_B` falla sanidad corta en una corrida puntual, cambiar a `sensor_A` y continuar sin detener avance.
