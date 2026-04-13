param(
    [string]$SensorId = "sensor_C",
    [string]$Port = "COM5",
    [int]$DurationS = 8
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pio = Join-Path $env:USERPROFILE ".platformio\penv\Scripts\pio.exe"
$fwDir = Join-Path $repoRoot "firmware\single_node_calibration"

if (-not (Test-Path $pio)) {
    throw "No se encontro PlatformIO en: $pio"
}

Write-Host "[1/5] Build firmware..." -ForegroundColor Cyan
& $pio run --environment esp32dev --project-dir $fwDir

Write-Host "[2/5] Upload firmware..." -ForegroundColor Cyan
& $pio run --target upload --environment esp32dev --project-dir $fwDir

Write-Host "[3/5] Sanidad serial (manual)" -ForegroundColor Yellow
$monitorCmd = "$pio device monitor --environment esp32dev --project-dir `"$fwDir`""
Write-Host "Ejecuta en otra terminal:"
Write-Host "  $monitorCmd"
Write-Host "Luego envia: STATUS, ST_ON, STATUS, ST_OFF, STATUS"
Read-Host "Presiona Enter cuando termines la sanidad serial"

Write-Host "[4/5] Captura ST pair..." -ForegroundColor Cyan
$captureBatch = "sensor_id='$SensorId'; port='$Port'; st_activation_mode='firmware_controlled'; duration_s=$DurationS; run('matlab/calibration/capture_sensorC_selftest_pair.m')"
matlab -batch $captureBatch

Write-Host "[5/5] Cierre de identidad desde manifest..." -ForegroundColor Cyan
$closeBatch = "sensor_id='$SensorId'; run('matlab/analysis/run_sensorC_phase11_1_close_identity_from_manifest.m')"
matlab -batch $closeBatch

Write-Host "Flujo Fase 11.1 completado." -ForegroundColor Green
