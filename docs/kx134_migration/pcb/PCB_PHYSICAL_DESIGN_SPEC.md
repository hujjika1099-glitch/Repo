# Especificacion fisica preliminar PCB/baquelada KX134

## Estado

Esta especificacion consolida el estado fisico antes de iniciar esquematico o layout. El prototipo funcional esta listo para entrega, pero la PCB no autorizada sigue bloqueada porque no existen decisiones fisicas/mecanicas cerradas.

## Configuracion validada

- `sample_rate_hz`: 100.
- `odr_hz`: 100.
- `range_g`: 8 g.
- Baudrate: 921600.
- ESP-NOW channel: 1.
- Total ESP32: 3.
- Sensor 1 MAC: `D4:E9:F4:E9:8E:1C`.
- Sensor 2 MAC: `D4:E9:F4:C3:37:14`.
- Receptor MAC: `00:4B:12:96:9A:80`.

## Arquitectura validada

- Sensor 1 KX134 + ESP32 sensora.
- Sensor 2 KX134 + ESP32 sensora.
- Receptor ESP32.
- Sensor 1/Sensor 2 hacia Receptor por ESP-NOW.
- Receptor hacia PC por USB Serial.

La arquitectura de tres ESP32 se mantiene como base.

## Decisiones cerradas

| Area | Decision |
|---|---|
| Arquitectura | Tres ESP32: dos nodos sensores y un receptor |
| Frecuencia validada | 100 Hz |
| Rango validado | 8 g |
| Receptor-PC | USB Serial a 921600 en prototipo |
| Identidad | MACs y sensor_id definidos en `config/kx134_node_map.json` |

## Decisiones pendientes criticas

- Alimentacion final.
- Tension/corriente objetivo.
- Proteccion electrica.
- Conectores de sensores y alimentacion.
- Si KX134 se mantiene con Qwiic/I2C cableado o se integra/suelda a PCB.
- Longitudes de cable Sensor 1, Sensor 2 y receptor-PC.
- Alivio de tension y proteccion mecanica.
- Montaje fisico de Sensor 1 y Sensor 2.
- Caja/carcasa.
- Orientacion fisica X/Y/Z de ambos sensores.
- Ubicacion de receptor y sensores.
- Acceso a USB/BOOT/EN.
- Dimensiones y restricciones del cliente.
- Ambiente: polvo, humedad, golpes, vibracion y temperatura.

## Alimentacion

Estado: `pending`.

No se definio si la alimentacion final sera USB por ESP32, fuente comun, bateria u otra opcion. Sin esta decision no se pueden fijar conectores, protecciones ni criterios electricos de PCB.

## Conectores

Estado: `pending`.

No se definio familia de conector, si sera desmontable, polarizado, Qwiic/I2C cableado, soldado directo o integrado a PCB.

## Cableado

Estado: `pending`.

No se definieron longitudes finales, tipo de cable, blindaje ni alivio de tension.

## Montaje

Estado: `pending`.

No se definio superficie, metodo de fijacion, tornillos, separadores, adhesivo, caja ni proteccion contra vibracion.

## Orientacion de ejes

Estado: `pending`.

No se definio orientacion final X/Y/Z para Sensor 1 ni Sensor 2. Esta decision es critica porque afecta interpretacion, etiquetado y recalibracion.

## Receptor

Estado: `pending`.

No se definio ubicacion fisica final, caja, indicador LED externo ni si permanecera siempre conectado al PC.

## Servicio

Estado: `pending`.

La PCB debe permitir reprogramacion, reemplazo, recalibracion y acceso a USB/BOOT/EN. Aun falta cerrar como se garantizara mecanicamente.

## Ambiente

Estado: `pending`.

No se definieron temperatura, humedad, polvo, vibracion, golpes ni necesidad final de caja.

## Reglas de recalibracion

- Si se cambia `range_g`, recalibrar.
- Si se reemplaza sensor fisico, recalibrar.
- Si se reemplaza ESP32 sensora, actualizar `node_map` y validar.
- Si cambia montaje/orientacion, documentar y evaluar recalibracion.
- Si se cambia frecuencia, validar firmware, GUI y exportacion.

## Decision PCB

- `PCB_PHYSICAL_DECISIONS_COMPLETE = NO`
- `PCB_DESIGN_AUTHORIZED = NO`

Justificacion: existen decisiones fisicas criticas pendientes y no se recibieron respuestas cerradas del usuario para autorizacion de PCB.
