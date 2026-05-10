# Plan de validacion de prototipo KX134

## Objetivo

Validar el sistema completo antes de entrega de prototipo y antes de iniciar baquelada/PCB.

## Arquitectura validada

- ESP32 Sensor 1 + SEN-17589/KX134 Sensor 1.
- ESP32 Sensor 2 + SEN-17589/KX134 Sensor 2.
- ESP32 receptora.
- Comunicacion sensores -> receptor: ESP-NOW.
- Comunicacion receptor -> PC: Serial USB.
- Aplicacion: `Sistema_Captura_Acelerometria.exe`.

## Configuracion actual de validacion

- `sample_rate_hz`: 100.
- `odr_hz`: 100.
- `range_g`: 8.
- Baudrate: 921600.
- Sensor 1 MAC: `D4:E9:F4:E9:8E:1C`.
- Sensor 2 MAC: `D4:E9:F4:C3:37:14`.
- Receptor MAC: `00:4B:12:96:9A:80`.

## Prueba controlada recomendada

Duracion minima: 60 segundos.

Secuencia:

1. 10 s sensores quietos.
2. 10 s movimiento suave.
3. 10 s evento comun/taps suaves.
4. 10 s sensores quietos.
5. 10 s movimiento suave adicional.
6. 10 s sensores quietos.

El objetivo no es analisis profundo; solo confirmar captura, continuidad, grafica en vivo y exportacion.

## Criterios de aceptacion

- Ambos sensores presentes.
- Sensor 1 rows >= 5500 para 60 s a 100 Hz.
- Sensor 2 rows >= 5500 para 60 s a 100 Hz.
- Effective Hz por sensor entre 98 y 102 Hz.
- Seq gaps por sensor:
  - 0 ideal.
  - 1 a 3 advertencia.
  - >3 fallo.
- `invalid_lines = 0` ideal.
- `duplicate_keys = 0` ideal.
- `receiver_t_us` valido.
- `pc_wall_s` positivo.
- CSV KX134 v3 exacto.
- Sin campos ADXL335/mV/g_norm.
- Metadata JSON endurecida.
- Summary generado.
- Graficas live visibles durante captura.
- Exportacion validada con `validate_kx134_export_bundle.py`.

## Criterios de no aceptacion

- Falta Sensor 1 o Sensor 2.
- `sensor_id` incorrecto.
- MAC incorrecta.
- `sample_rate_hz` inesperado.
- `range_g` inesperado.
- CSV con `mv_*` o `g_norm`.
- GUI congelada.
- Exportacion incompleta.
- Metadata invalida.
- Errores de paquete recurrentes.

## Resultado esperado

- `READY_FOR_PROTOTYPE_DELIVERY = YES/NO`.
- `READY_FOR_PCB_DESIGN = YES/NO`.
