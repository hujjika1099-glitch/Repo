param(
    [string]$Port = "",
    [int]$DurationS = 20,
    [string]$SessionName = "live",
    [string]$FilePrefix = "sensor_B_live",
    [switch]$AutoStart
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
& (Join-Path $repoRoot "scripts\run_sensorB_live_session.ps1") `
    -Port $Port `
    -DurationS $DurationS `
    -SessionName $SessionName `
    -FilePrefix $FilePrefix `
    -AutoStart:$AutoStart
