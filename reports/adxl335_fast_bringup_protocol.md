# Fase 12 - Fast Bring-Up Operativo para Nuevos Modulos ADXL335

## Objetivo
Clasificar un modulo nuevo en 5-15 minutos sin repetir campanas largas de calibracion.

## Flujo minimo
1. Cablear segun `hardware/adxl335_standard_wiring.md`.
2. Confirmar firmware baseline con stream serial valido.
3. Ejecutar una captura corta (`quickcheck_static`, 8 s por defecto).
4. Correr evaluacion automatica de quickcheck.
5. Registrar estado final del modulo en el registro liviano.

## Estados de salida
- `ready_for_operational_use`
- `ready_for_operational_use_provisional`
- `hardware_review_needed`
- `rejected_module`

## Ejecucion recomendada (MATLAB)
```matlab
module_id = "sensor_D";
port = "COM5";
run_capture = true;
run('matlab/analysis/run_adxl335_fast_bringup.m')
```

## Ejecucion sobre corrida existente (sin nueva captura)
```matlab
module_id = "sensor_D";
run_capture = false;
quickcheck_run_file = "sensor_D_quickcheck_static_20260322_180000.csv";
run('matlab/analysis/run_adxl335_fast_bringup.m')
```

## Salidas esperadas
- `PHASE12_QUICKCHECK_OK`
- `PHASE12_FAST_BRINGUP_OK`
- Resumen quickcheck en `reports/analysis_outputs/*_phase12_quickcheck_*.txt`
- Resumen bring-up en `reports/analysis_outputs/*_phase12_fast_bringup_*.txt`
- Registro actualizado en `hardware/module_registry_fast_bringup.csv`

## Regla de escalamiento
Si el estado es `hardware_review_needed` o `rejected_module`, la siguiente accion es minima:
- revisar cableado/energia/canal saturado,
- repetir solo una corrida quickcheck,
- usar ST como diagnostico opcional si persiste la anomalia.
