<#
.SYNOPSIS
    Ejecuta smoke QA sobre el paquete Windows descomprimido.

.DESCRIPTION
    No instala dependencias, no modifica PATH y no requiere permisos de admin.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$PackageRoot,
    [string]$ExePath = "",
    [bool]$RunSmoke = $true,
    [bool]$RunKx134Smoke = $true,
    [bool]$RunAdxlSmoke = $true,
    [string]$Output = "reports\kx134_gui_validation\TICKET_021_external_pc_qa_output.json",
    [string]$HardwareCsv = "",
    [string]$HardwareSessionJson = "",
    [string]$HardwareSummary = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-Smoke {
    param(
        [string]$Exe,
        [string[]]$Arguments
    )
    $process = Start-Process -FilePath $Exe -ArgumentList $Arguments -Wait -PassThru -WindowStyle Hidden
    return $process.ExitCode
}

function Get-PrimaryResolution {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $screen = [System.Windows.Forms.Screen]::PrimaryScreen
        return "$($screen.Bounds.Width)x$($screen.Bounds.Height)"
    } catch {
        return "unavailable"
    }
}

function Get-ScalingPercent {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $graphics = [System.Drawing.Graphics]::FromHwnd([System.IntPtr]::Zero)
        $scale = [Math]::Round(($graphics.DpiX / 96.0) * 100)
        $graphics.Dispose()
        return $scale
    } catch {
        return $null
    }
}

$packagePath = (Resolve-Path $PackageRoot).Path
if ([string]::IsNullOrWhiteSpace($ExePath)) {
    $ExePath = Join-Path $packagePath "Sistema_Captura_Acelerometria.exe"
}

$exeExists = Test-Path $ExePath
$launcherExit = $null
$kx134Exit = $null
$adxlExit = $null

if ($exeExists -and $RunSmoke) {
    $launcherExit = Invoke-Smoke -Exe $ExePath -Arguments @("--smoke", "--close-after-ms", "1000")
}
if ($exeExists -and $RunKx134Smoke) {
    $kx134Exit = Invoke-Smoke -Exe $ExePath -Arguments @("--mode", "kx134", "--smoke", "--close-after-ms", "1000")
}
if ($exeExists -and $RunAdxlSmoke) {
    $adxlExit = Invoke-Smoke -Exe $ExePath -Arguments @("--mode", "adxl", "--smoke", "--close-after-ms", "1000")
}

$hardwareArtifacts = @{
    csv = $HardwareCsv
    session_json = $HardwareSessionJson
    summary = $HardwareSummary
    csv_exists = (-not [string]::IsNullOrWhiteSpace($HardwareCsv)) -and (Test-Path $HardwareCsv)
    session_json_exists = (-not [string]::IsNullOrWhiteSpace($HardwareSessionJson)) -and (Test-Path $HardwareSessionJson)
    summary_exists = (-not [string]::IsNullOrWhiteSpace($HardwareSummary)) -and (Test-Path $HardwareSummary)
}

$payload = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    hostname = $env:COMPUTERNAME
    username = $env:USERNAME
    windows_version = [System.Environment]::OSVersion.VersionString
    resolution = Get-PrimaryResolution
    scaling_percent = Get-ScalingPercent
    package_root = $packagePath
    exe = $ExePath
    exe_exists = $exeExists
    launcher_smoke_exit_code = $launcherExit
    kx134_smoke_exit_code = $kx134Exit
    adxl_smoke_exit_code = $adxlExit
    launcher_smoke_pass = ($launcherExit -eq 0)
    kx134_smoke_pass = ($kx134Exit -eq 0)
    adxl_smoke_pass = ($adxlExit -eq 0)
    visual_manual_result = "not_recorded"
    visual_layout_pass = $false
    hardware_capture_run = $false
    hardware_capture_pass = $false
    export_validation_pass = $false
    hardware_artifacts = $hardwareArtifacts
    failures = @()
    warnings = @()
}

if (-not $exeExists) { $payload.failures += "exe_missing" }
if ($RunSmoke -and $launcherExit -ne 0) { $payload.failures += "launcher_smoke_failed" }
if ($RunKx134Smoke -and $kx134Exit -ne 0) { $payload.failures += "kx134_smoke_failed" }
if ($RunAdxlSmoke -and $adxlExit -ne 0) { $payload.failures += "adxl_smoke_failed" }

$payload.pass = ($payload.failures.Count -eq 0)
$payload.ready_for_client_prototype_qa = "PENDING"
$payload.decision = if ($payload.pass) { "SMOKE_PASS_MANUAL_VISUAL_AND_HARDWARE_PENDING" } else { "FAIL" }

$outputPath = Join-Path (Get-Location) $Output
$outputDir = Split-Path -Parent $outputPath
if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }
$jsonText = $payload | ConvertTo-Json -Depth 8
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($outputPath, $jsonText + [Environment]::NewLine, $utf8NoBom)
Write-Host $outputPath

if (-not $payload.pass) { exit 1 }
