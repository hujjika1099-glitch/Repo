param(
    [string]$Port = "",
    [int]$DurationS = 20,
    [string]$SessionName = "live",
    [string]$FilePrefix = "sensor_B_live",
    [string]$OutputDirRelpath = "data/raw/sensor_B_live",
    [string]$ProcessedDirRelpath = "data/processed",
    [double]$PrecheckDurationS = 10,
    [double]$PlotWindowS = 30,
    [switch]$AutoStart
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$pythonExe = Join-Path $repoRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $pythonExe)) {
    throw "No se encontro .venv\\Scripts\\python.exe. Ejecute scripts\\install_gui_requirements.ps1 si aun no preparo el entorno."
}

$guiScript = Join-Path $repoRoot "gui\adxl_live_gui.py"
if (-not (Test-Path $guiScript)) {
    throw "No se encontro la GUI en gui\\adxl_live_gui.py."
}

$args = @(
    $guiScript,
    "--duration-s", "$DurationS",
    "--session-name", $SessionName,
    "--file-prefix", $FilePrefix,
    "--output-dir-relpath", $OutputDirRelpath,
    "--processed-dir-relpath", $ProcessedDirRelpath,
    "--precheck-duration-s", "$PrecheckDurationS",
    "--plot-window-s", "$PlotWindowS"
)

if ($Port) {
    $args += @("--port", $Port)
}

if ($AutoStart) {
    $args += "--autostart"
}

& $pythonExe @args
