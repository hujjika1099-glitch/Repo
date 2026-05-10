# Checklist de continuidad - Baquelada RevA

## Antes de alimentar

- [ ] Confirmar escala 1:1 impresa.
- [ ] Confirmar mirror correcto segun cara de cobre.
- [ ] Confirmar separacion real de headers con calibre.
- [ ] Confirmar taladros correctos.
- [ ] Confirmar que no hay corto entre 3V3 y GND.
- [ ] Confirmar continuidad de GND.
- [ ] Confirmar continuidad de 3V3.
- [ ] Confirmar continuidad SDA GPIO21 hacia pin correcto.
- [ ] Confirmar continuidad SCL GPIO22 hacia pin correcto.
- [ ] Confirmar que SDA no esta en corto con SCL.
- [ ] Confirmar que SDA/SCL no estan en corto a 3V3/GND.
- [ ] Confirmar que no hay puentes entre pads adyacentes.
- [ ] Confirmar que las pistas coinciden con el pinout del footprint.
- [ ] Confirmar orientacion fisica del ESP32.
- [ ] Confirmar orientacion fisica del KX134 o conector.
- [ ] Confirmar etiquetas Sensor 1/Sensor 2/Receptor si aplica.

## Prueba con multimetro

| Prueba | Punto A | Punto B | Resultado esperado | Resultado medido | Estado |
|---|---|---|---|---|---|
| Corto alimentacion | 3V3 | GND | Sin continuidad | PENDING | PENDING |
| GND comun | GND ESP32 | GND KX134/conector | Continuidad | PENDING | PENDING |
| 3V3 | 3V3 ESP32 | 3V3 KX134/conector | Continuidad | PENDING | PENDING |
| SDA | GPIO21 ESP32 | SDA KX134/conector | Continuidad | PENDING | PENDING |
| SCL | GPIO22 ESP32 | SCL KX134/conector | Continuidad | PENDING | PENDING |
| SDA-SCL | SDA | SCL | Sin continuidad | PENDING | PENDING |
| SDA-3V3 | SDA | 3V3 | Sin corto directo | PENDING | PENDING |
| SDA-GND | SDA | GND | Sin corto directo | PENDING | PENDING |
| SCL-3V3 | SCL | 3V3 | Sin corto directo | PENDING | PENDING |
| SCL-GND | SCL | GND | Sin corto directo | PENDING | PENDING |
| Pads adyacentes | Pad N | Pad N+1 | Sin puentes no esperados | PENDING | PENDING |

## Decision

- `BAQUELADA_REVA_ELECTRICAL_TEST_READY = NO`

La baquelada no debe alimentarse hasta completar este checklist.
