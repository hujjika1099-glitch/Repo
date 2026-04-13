param(
    [string]$Port = "",
    [int]$DurationS = 12,
    [string]$PoseLabel = "operational_run"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

Write-Host ""
Write-Host "SENSOR_B_OPERATIONAL_CAPTURE_GUI" -ForegroundColor Green
Write-Host "La captura operativa ahora se ejecuta en la GUI Python." -ForegroundColor Yellow
Write-Host "Al finalizar revisa el summary/precheck generado en reports/analysis_outputs." -ForegroundColor Yellow

& (Join-Path $repoRoot "scripts\run_sensorB_live_session.ps1") `
    -Port $Port `
    -DurationS $DurationS `
    -SessionName $PoseLabel `
    -FilePrefix "sensor_B" `
    -OutputDirRelpath "data/raw/sensor_B" `
    -ProcessedDirRelpath "data/processed" `
    -AutoStart
