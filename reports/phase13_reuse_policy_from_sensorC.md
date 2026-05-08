# Fase 13 - Politica de Reuso desde sensor_C

## Se reutiliza
- Flujo de adquisicion serial y parser estable.
- Pinout estandar ADXL335->ESP32 sobre ADC1.
- Convencion operativa general documentada en Fase 11.
- Criterios de aceptacion rapida de Fase 12 (sanidad, frecuencia, saturacion, secuencia).
- Estructura de trazabilidad (`data/raw`, `reports/analysis_outputs`, registros).

## No se reutiliza ciegamente
- No transferir como verdad fisica la calibracion especifica de `sensor_C` a `sensor_B`.
- No imponer `identity_closed` de `sensor_C` como gate para `sensor_B`.
- No reutilizar decisiones de remapeo/signo de `sensor_C` como si aplicaran automaticamente a otro modulo.

## Regla operativa
`sensor_B` se usa por su estado propio (`ready_for_operational_use`), no por herencia de calibracion detallada de `sensor_C`.
