param(
    [string]$ModuleId = "sensor_D",
    [string]$Port = "COM5",
    [int]$DurationS = 8,
    [switch]$SkipCapture
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

if ($SkipCapture) {
    throw "SkipCapture requiere ejecutar MATLAB manual con quickcheck_run_file explicito."
}

$batch = "module_id='$ModuleId'; port='$Port'; duration_s=$DurationS; run_capture=true; run('matlab/analysis/run_adxl335_fast_bringup.m')"
matlab -batch $batch
