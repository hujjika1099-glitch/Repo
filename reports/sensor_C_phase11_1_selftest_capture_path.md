# Fase 11.1 - Minimal Self-Test Acquisition Path (sensor_C)

Fecha: 2026-03-22

## A) Diagnostico operativo actualizado
1. Modulo exacto usado:
   - Header principal: VCC, X-OUT, Y-OUT, Z-OUT, GND.
   - Pad lateral separado: ST.
2. ST no esta en el header principal, por lo que requiere cable dedicado al pad lateral.
3. Firmware baseline ahora define ST control en GPIO23 y comandos minimos seriales.
4. X/Y/Z permanecen en ADC1 (GPIO32/33/34), evitando ADC2 por compatibilidad futura Wi-Fi/ESP-NOW.

## B) Ruta elegida
Ruta principal: **firmware-controlled ST**.

Razon pragmatica:
- un solo cable extra (ST pad lateral -> GPIO23),
- elimina conmutacion manual durante captura,
- reduce errores de operador,
- deja trazabilidad explicita de estado ST por comando/ACK.

## C) Mapa final de pines (obligatorio)
- VCC -> 3V3
- GND -> GND
- X-OUT -> GPIO32 (ADC1_CH4)
- Y-OUT -> GPIO33 (ADC1_CH5)
- Z-OUT -> GPIO34 (ADC1_CH6)
- ST (pad lateral) -> GPIO23 (digital output)

## D) Reglas tecnicas aplicadas
1. X/Y/Z solo en ADC1.
2. ADC2 evitado para salidas analogicas del ADXL335.
3. ST no usa GPIO34-39 (input-only).
4. Logica ST en firmware:
   - LOW = ST_OFF
   - HIGH = ST_ON
   - arranque seguro en LOW.

## E) Flujo operativo ultracorto (5-10 min)
1. Cablear modulo con mapa final.
2. Flashear firmware actualizado con control ST (GPIO23).
3. Ejecutar captura pair:
   - `run('matlab/calibration/capture_sensorC_selftest_pair.m')`
4. El script ejecuta automaticamente:
   - `ST_OFF` -> captura `st_off`
   - `ST_ON` -> captura `st_on`
   - `ST_OFF` de restauracion
5. Ejecutar cierre desde manifest:
   - `run('matlab/analysis/run_sensorC_phase11_1_close_identity_from_manifest.m')`

## F) Criterios de exito
1. ACK de comandos ST (`ST_OFF` y `ST_ON`) o `STATUS` consistente.
2. Dos archivos generados (`st_off` y `st_on`) + manifest de protocolo.
3. Self-test decision distinta de `selftest_data_missing`.
4. Rerun Fase 11 con decision actualizada (`identity_closed` o `identity_not_closed`).

## G) Fallback minimo
1. Si firmware ST no responde:
   - usar `st_activation_mode='manual_assisted'` en el mismo script,
   - mantener solo 2 corridas (st_off/st_on).
2. Si ST no separa Y/Z:
   - agregar solo 1 corrida corta `pos_z`,
   - rerun de chequeo, sin multipose largo.

## H) Compatibilidad futura ESP-NOW
Esta ruta es compatible con Wi-Fi/ESP-NOW porque las salidas analogicas del ADXL335 quedan en ADC1 (GPIO32/33/34) y ADC2 no se usa para X/Y/Z.

## I) Referencia operativa final
- Ejecutar en banco siguiendo:
  - `reports/sensor_C_phase11_1_bank_runbook.md`
