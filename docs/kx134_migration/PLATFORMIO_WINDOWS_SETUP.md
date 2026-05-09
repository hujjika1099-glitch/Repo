# PlatformIO en Windows sin PATH

## Problema

El usuario puede tener PlatformIO instalado pero sin el comando `pio` disponible en PATH.

## Solucion recomendada del proyecto

Usar wrappers del repositorio.

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
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action upload -Env kx134_sensor_2 -Port COMx
```

Monitor serial:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action monitor -Port COM5
```

Subir y monitor:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action upload-monitor -Env kx134_sensor_2 -Port COMx
```

## Agregar PlatformIO al PATH de usuario

Si se quiere dejar `pio` disponible globalmente:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\setup_platformio_user_path.ps1
```

Despues cerrar y abrir PowerShell.

Verificar:

```powershell
pio --version
```

## Ruta esperada de PlatformIO

```text
%USERPROFILE%\.platformio\penv\Scripts\pio.exe
```

## Puerto COM

Antes de subir firmware:

```powershell
powershell -ExecutionPolicy Bypass -File tools\platformio\kx134_single_node.ps1 -Action list-devices
```

Reemplazar `COM5` por el puerto real.
