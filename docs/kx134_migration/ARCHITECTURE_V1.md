# Arquitectura fisica KX134 v1

## 1. Decision cerrada

El sistema KX134/SEN-17589 usara tres ESP32 totales:

- ESP32 sensora 1.
- ESP32 sensora 2.
- ESP32 receptora.

La arquitectura seleccionada es:

```text
Sensor KX134 1 -> ESP32 sensora 1 -> ESP-NOW -> ESP32 receptora -> Serial USB -> Aplicacion PC

Sensor KX134 2 -> ESP32 sensora 2 -> ESP-NOW -> ESP32 receptora -> Serial USB -> Aplicacion PC
```

## 2. Roles de hardware

### ESP32 sensora 1

- Rol: nodo sensor.
- Sensor asociado: SEN-17589/KX134 numero 1.
- `sensor_id`: 1.
- Comunicacion hacia receptor: ESP-NOW.
- Interfaz local hacia KX134: I2C/Qwiic como objetivo inicial.
- Archivo de calibracion futuro: `config/calibrations/kx134_sensor_1.json`.

### ESP32 sensora 2

- Rol: nodo sensor.
- Sensor asociado: SEN-17589/KX134 numero 2.
- `sensor_id`: 2.
- Comunicacion hacia receptor: ESP-NOW.
- Interfaz local hacia KX134: I2C/Qwiic como objetivo inicial.
- Archivo de calibracion futuro: `config/calibrations/kx134_sensor_2.json`.

### ESP32 receptora

- Rol: receptor.
- No tiene sensor KX134 asociado.
- Recibe paquetes ESP-NOW de `sensor_id=1` y `sensor_id=2`.
- Agrega timestamp de recepcion `receiver_t_us` cuando aplique.
- Envia datos a la aplicacion por Serial USB.
- No debe inferir `sensor_id` si el paquete llega incompleto.

## 3. Reglas de identificacion

Cada muestra futura debe conservar:

- `sensor_id`.
- `node_mac`.
- `seq`.
- `sensor_t_us`.
- `receiver_t_us`.
- `x_raw`.
- `y_raw`.
- `z_raw`.
- `x_g`.
- `y_g`.
- `z_g`.
- `sample_rate_hz`.
- `range_g`.
- `calibration_id`.

`sensor_id` solo puede ser:

- 1 para el sensor fisico 1.
- 2 para el sensor fisico 2.

El receptor no debe asignar `sensor_id` por defecto.

## 4. Comunicacion

La comunicacion seleccionada es:

- Nodos sensores a receptor: ESP-NOW.
- Receptor a aplicacion: Serial USB.

Esto conserva la arquitectura conceptual actual del repositorio.

## 5. Interfaz del sensor KX134

La interfaz objetivo inicial para cada SEN-17589/KX134 sera I2C/Qwiic.

Notas:

- Cada sensor estara conectado a una ESP32 diferente.
- Al haber un sensor por ESP32 sensora, no se requiere resolver conflicto de direcciones entre dos KX134 en el mismo bus.
- SPI queda como alternativa tecnica no seleccionada, salvo decision futura explicita.

## 6. Frecuencia de muestreo

El sistema futuro debe soportar:

- 100 Hz.
- 200 Hz.
- 500 Hz.
- 1000 Hz.

La frecuencia default documental seguira siendo 100 Hz.

La frecuencia efectiva debe reportarse en datos futuros.

## 7. Rango g

El contrato permite:

- +/-8 g.
- +/-16 g.
- +/-32 g.
- +/-64 g.

El rango inicial de pruebas sigue pendiente de confirmacion y no debe fijarse en este ticket.

## 8. Calibracion

Cada sensor debe calibrarse de manera individual:

- Sensor 1: calibracion propia.
- Sensor 2: calibracion propia.

No se permite compartir calibracion entre sensores.

## 9. Decisiones cerradas

- Arquitectura con tres ESP32: cerrada.
- Dos sensores fisicos SEN-17589/KX134: cerrada.
- Un sensor por ESP32 sensora: cerrada.
- Receptor por ESP-NOW y salida Serial USB hacia aplicacion: cerrada.
- No usar arquitectura de dos ESP32 totales: cerrada para esta fase.

## 10. Decisiones pendientes

- Confirmar MAC fisica de ESP32 sensora 1.
- Confirmar MAC fisica de ESP32 sensora 2.
- Confirmar MAC fisica de ESP32 receptora.
- Confirmar etiquetas fisicas visibles para Sensor 1 y Sensor 2.
- Confirmar rango g inicial.
- Confirmar libreria KX134 a usar en firmware.
- Confirmar mecanismo exacto de cambio de frecuencia desde GUI hacia firmware.
- Confirmar estrategia final de `pair_seq`/`sync_group_id`.
