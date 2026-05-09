# PlatformIO helper scripts

## Proposito

Permitir usar PlatformIO en Windows aunque `pio` no este en el PATH.

## Scripts

- `pio.ps1`: wrapper PowerShell general.
- `pio.cmd`: wrapper CMD general.
- `kx134_single_node.ps1`: wrapper especifico para `firmware/kx134_single_node_i2c`.
- `setup_platformio_user_path.ps1`: agrega PlatformIO al PATH de usuario si ya esta instalado.

## Comandos principales

Compilar:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action build -Env kx134_sensor_1
```

Compilar Sensor 2:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action build -Env kx134_sensor_2
```

Listar dispositivos:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action list-devices
```

Subir firmware:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action upload -Env kx134_sensor_1 -Port COM5
```

Subir firmware Sensor 2:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action upload -Env kx134_sensor_2 -Port COM5
```

Monitor serial:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action monitor -Port COM5
```

Subir y abrir monitor:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action upload-monitor -Env kx134_sensor_2 -Port COM5
```

## Nota

Reemplazar `COM5` por el puerto real de la ESP32.

Entornos validos:

- `kx134_sensor_1`
- `kx134_sensor_2`
- `esp32dev` como alias compatible de Sensor 1.
