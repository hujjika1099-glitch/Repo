# Runbook Final de Banco - Fase 11.1 (ADXL335 + ESP32)

## 1. Preparacion fisica
- Colocar el ADXL335 en orientacion fija y estable.
- Tener listo un cable dedicado para el pad lateral ST.
- Confirmar alimentacion de ESP32 por USB estable.

## 2. Cableado exacto
| ADXL335 pin | ESP32 pin | Funcion | Nota |
|---|---|---|---|
| VCC | 3V3 | Alimentacion | No usar 5V |
| GND | GND | Referencia comun | Obligatorio |
| X-OUT | GPIO32 (ADC1_CH4) | Analog X | ADC1 (compatible Wi-Fi/ESP-NOW) |
| Y-OUT | GPIO33 (ADC1_CH5) | Analog Y | ADC1 (compatible Wi-Fi/ESP-NOW) |
| Z-OUT | GPIO34 (ADC1_CH6) | Analog Z | GPIO34 es input-only pero valido para ADC |
| ST (pad lateral) | GPIO23 | Control self-test | ST no esta en header principal |

Advertencias fisicas obligatorias:
- ST es pad lateral, no header principal.
- ST no debe ir a GPIO34-39.
- Alimentar el modulo a 3V3.
- No mover orientacion entre ST_OFF y ST_ON.

## 3. Verificacion previa de firmware
- Confirmar que firmware actual incluye control ST por serial:
  - `ST_ON`
  - `ST_OFF`
  - `STATUS`
- Confirmar logica:
  - LOW = ST_OFF
  - HIGH = ST_ON
  - arranque en ST_OFF.

## 4. Flash del firmware
- Compilar y subir firmware al ESP32.
- Si upload falla por bootloader, repetir con secuencia BOOT/EN de tu placa.

## 5. Prueba rapida de comandos seriales ST
- Abrir monitor serial y enviar en este orden:
  1. `STATUS`
  2. `ST_ON`
  3. `STATUS`
  4. `ST_OFF`
  5. `STATUS`
- Debes ver ACK y estado ST coherentes (ver seccion "Respuestas esperadas").

Respuestas esperadas del firmware:
- `STATUS` -> linea tipo `# status st=OFF seq=...` o `# status st=ON seq=...`
- `ST_ON` -> `# cmd=ST_ON ack=ok st=ON`
- `ST_OFF` -> `# cmd=ST_OFF ack=ok st=OFF`

## 6. Captura ST_OFF / ST_ON
- Ejecutar captura ST pair en modo firmware-controlled.
- El script hace:
  - `ST_OFF` -> captura `st_off`
  - `ST_ON` -> captura `st_on`
  - `ST_OFF` de restauracion
- Debe generar manifest de 2 filas (`st_off`, `st_on`).

## 7. Cierre de identidad desde manifest
- Ejecutar helper de cierre.
- El helper encadena:
  - chequeo ST (`run_sensorC_selftest_identity_check.m`)
  - orquestador Fase 11 (`run_sensorC_phase11_axis_identity_and_convention.m`)

## 8. Interpretacion del resultado
- Objetivo primario:
  - `identity_closed`
- Resultado aceptable no cerrado:
  - `identity_not_closed` con evidencia real (no `selftest_data_missing`).
- Si hay cierre, revisar si el orquestador eleva estado operativo.

## 9. Que hacer si falla
- Si ST no responde por serial:
  - revisar cable ST pad lateral -> GPIO23
  - verificar firmware subido correcto
  - repetir sanidad serial.
- Si no se genera pair:
  - verificar COM, baud, cableado, orientacion fija, reintentar captura.
- Si ST queda ambiguo Y/Z:
  - ejecutar fallback minimo (1 corrida corta `pos_z`) y rerun de cierre.
