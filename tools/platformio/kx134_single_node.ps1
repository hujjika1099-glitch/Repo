param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("build", "upload", "monitor", "upload-monitor", "list-devices", "clean")]
    [string] $Action,

    [string] $Port = "",
    [int] $Baud = 921600,
    [ValidateSet("kx134_sensor_1", "kx134_sensor_2", "esp32dev")]
    [string] $Env = "kx134_sensor_1",
    [string] $ProjectDir = "firmware\kx134_single_node_i2c"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$pioWrapper = Join-Path $PSScriptRoot "pio.ps1"
if (-not (Test-Path $pioWrapper)) {
    Write-Error "No se encontro el wrapper PlatformIO: $pioWrapper"
    exit 1
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$projectPath = Join-Path $repoRoot $ProjectDir

function Invoke-Pio {
    param([string[]] $Arguments)

    & powershell -NoProfile -ExecutionPolicy Bypass -File $pioWrapper @Arguments
    return $LASTEXITCODE
}

function Require-Port {
    if ([string]::IsNullOrWhiteSpace($Port)) {
        Write-Error "La accion '$Action' requiere -Port COMx. Ejemplo: -Port COM5"
        exit 1
    }
}

switch ($Action) {
    "build" {
        $code = Invoke-Pio -Arguments @("run", "-d", $projectPath, "-e", $Env)
        exit $code
    }
    "upload" {
        Require-Port
        $code = Invoke-Pio -Arguments @("run", "-d", $projectPath, "-e", $Env, "-t", "upload", "--upload-port", $Port)
        exit $code
    }
    "monitor" {
        Require-Port
        $code = Invoke-Pio -Arguments @("device", "monitor", "-p", $Port, "-b", [string]$Baud)
        exit $code
    }
    "upload-monitor" {
        Require-Port
        $uploadCode = Invoke-Pio -Arguments @("run", "-d", $projectPath, "-e", $Env, "-t", "upload", "--upload-port", $Port)
        if ($uploadCode -ne 0) {
            exit $uploadCode
        }
        $monitorCode = Invoke-Pio -Arguments @("device", "monitor", "-p", $Port, "-b", [string]$Baud)
        exit $monitorCode
    }
    "list-devices" {
        $code = Invoke-Pio -Arguments @("device", "list")
        exit $code
    }
    "clean" {
        $code = Invoke-Pio -Arguments @("run", "-d", $projectPath, "-e", $Env, "-t", "clean")
        exit $code
    }
}
