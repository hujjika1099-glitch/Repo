Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PioArgs = $args

function Invoke-PioExecutable {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ExecutablePath,
        [string[]] $Arguments = @()
    )

    & $ExecutablePath @Arguments
    exit $LASTEXITCODE
}

$pathCommand = Get-Command "pio.exe" -ErrorAction SilentlyContinue
if ($pathCommand) {
    Invoke-PioExecutable -ExecutablePath $pathCommand.Source -Arguments $PioArgs
}

$pioExe = Join-Path $env:USERPROFILE ".platformio\penv\Scripts\pio.exe"
if (Test-Path $pioExe) {
    Invoke-PioExecutable -ExecutablePath $pioExe -Arguments $PioArgs
}

$platformioExe = Join-Path $env:USERPROFILE ".platformio\penv\Scripts\platformio.exe"
if (Test-Path $platformioExe) {
    Invoke-PioExecutable -ExecutablePath $platformioExe -Arguments $PioArgs
}

$pythonCommand = Get-Command "python.exe" -ErrorAction SilentlyContinue
if ($pythonCommand) {
    & $pythonCommand.Source -m platformio @PioArgs
    if ($LASTEXITCODE -eq 0) {
        exit 0
    }
}

Write-Error @"
PlatformIO no esta disponible.

Ruta esperada:
  %USERPROFILE%\.platformio\penv\Scripts\pio.exe

Si PlatformIO ya esta instalado pero pio no esta en PATH, puede ejecutar:
  powershell -ExecutionPolicy Bypass -File tools\platformio\setup_platformio_user_path.ps1
"@
exit 1
