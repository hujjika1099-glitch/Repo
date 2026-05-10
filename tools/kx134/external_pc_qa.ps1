<#
.SYNOPSIS
    External PC QA helper for Sistema_Captura_Acelerometria.exe.

.DESCRIPTION
    Runs smoke checks against a copied/unzipped Windows onedir package and
    records host, display and optional hardware artifact information.
    The script does not install dependencies, does not require admin rights and
    does not modify PATH.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$PackageRoot,

    [string]$ExePath,

    [switch]$RunSmoke = $true,
    [switch]$RunKx134Smoke = $true,
    [switch]$RunAdxlSmoke = $true,

    [string]$Output = "reports\kx134_gui_validation\TICKET_021_external_pc_qa_output.json",

    [string]$HardwareCsv,
    [string]$HardwareSessionJson,
    [string]$HardwareSummary
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-FullPath {
    param([string]$PathValue)
    if ([string]::IsNullOrWhiteSpace($PathValue)) { return $null }
    return [System.IO.Path]::GetFullPath($PathValue)
}

function Get-ScalingInfo {
    $logPixels = $null
    $scalePercent = $null
    try {
        $desktop = Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name LogPixels -ErrorAction Stop
        $logPixels = [int]$desktop.LogPixels
        if ($logPixels -gt 0) {
            $scalePercent = [int][Math]::Round(($logPixels / 96.0) * 100)
        }
    } catch {
        $logPixels = $null
        $scalePercent = $null
    }
    return @{
        log_pixels = $logPixels
        scale_percent = $scalePercent
    }
}

function Get-PrimaryResolution {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        return @{
            width = [int]$bounds.Width
            height = [int]$bounds.Height
        }
    } catch {
        return @{
            width = $null
            height = $null
        }
    }
}

function Invoke-Smoke {
    param(
        [string]$Executable,
        [string[]]$Arguments
    )
    $started = Get-Date
    $exitCode = $null
    $errorText = $null
    try {
        $process = Start-Process -FilePath $Executable -ArgumentList $Arguments -Wait -PassThru -WindowStyle Normal
        $exitCode = $process.ExitCode
    } catch {
        $errorText = $_.Exception.Message
    }
    return @{
        command = @($Executable) + $Arguments
        exit_code = $exitCode
        pass = ($exitCode -eq 0)
        error = $errorText
        started_at = $started.ToString("o")
        ended_at = (Get-Date).ToString("o")
    }
}

$packageRootFull = Resolve-FullPath $PackageRoot
if (-not $ExePath) {
    $ExePath = Join-Path $packageRootFull "Sistema_Captura_Acelerometria.exe"
}
$exeFull = Resolve-FullPath $ExePath
$outputFull = Resolve-FullPath $Output
$outputDir = Split-Path -Parent $outputFull
if ($outputDir) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$exeExists = Test-Path -LiteralPath $exeFull
$os = Get-CimInstance Win32_OperatingSystem
$resolution = Get-PrimaryResolution
$scaling = Get-ScalingInfo

$launcherSmoke = @{
    pass = $null
    exit_code = $null
    error = "not_run"
}
$kx134Smoke = @{
    pass = $null
    exit_code = $null
    error = "not_run"
}
$adxlSmoke = @{
    pass = $null
    exit_code = $null
    error = "not_run"
}

if ($exeExists -and $RunSmoke) {
    $launcherSmoke = Invoke-Smoke -Executable $exeFull -Arguments @("--smoke", "--close-after-ms", "1000")
}
if ($exeExists -and $RunKx134Smoke) {
    $kx134Smoke = Invoke-Smoke -Executable $exeFull -Arguments @("--mode", "kx134", "--smoke", "--close-after-ms", "1000")
}
if ($exeExists -and $RunAdxlSmoke) {
    $adxlSmoke = Invoke-Smoke -Executable $exeFull -Arguments @("--mode", "adxl", "--smoke", "--close-after-ms", "1000")
}

$hardwareArtifacts = @{
    raw_csv = Resolve-FullPath $HardwareCsv
    session_json = Resolve-FullPath $HardwareSessionJson
    summary_md = Resolve-FullPath $HardwareSummary
}
$hardwareCaptureRun = -not [string]::IsNullOrWhiteSpace($HardwareCsv) -or
    -not [string]::IsNullOrWhiteSpace($HardwareSessionJson) -or
    -not [string]::IsNullOrWhiteSpace($HardwareSummary)
$artifactPathsExist = @{
    raw_csv = ($hardwareArtifacts.raw_csv -and (Test-Path -LiteralPath $hardwareArtifacts.raw_csv))
    session_json = ($hardwareArtifacts.session_json -and (Test-Path -LiteralPath $hardwareArtifacts.session_json))
    summary_md = ($hardwareArtifacts.summary_md -and (Test-Path -LiteralPath $hardwareArtifacts.summary_md))
}

$hardwareValidation = @{
    attempted = $false
    pass = $null
    output = $null
    error = $null
}
$validator = Join-Path $PSScriptRoot "validate_kx134_export_bundle.py"
$python = Get-Command python -ErrorAction SilentlyContinue
if ($hardwareCaptureRun -and $python -and (Test-Path -LiteralPath $validator) -and
    $artifactPathsExist.raw_csv -and $artifactPathsExist.session_json -and $artifactPathsExist.summary_md) {
    $hardwareValidationOutput = Join-Path (Split-Path -Parent $outputFull) "TICKET_021_external_hardware_validation.json"
    $hardwareValidation.attempted = $true
    $hardwareValidation.output = $hardwareValidationOutput
    try {
        & $python.Source $validator `
            --session-json $hardwareArtifacts.session_json `
            --raw-csv $hardwareArtifacts.raw_csv `
            --summary-md $hardwareArtifacts.summary_md `
            --output $hardwareValidationOutput
        $hardwareValidation.pass = ($LASTEXITCODE -eq 0)
    } catch {
        $hardwareValidation.pass = $false
        $hardwareValidation.error = $_.Exception.Message
    }
}

$packageSmokePass = ($exeExists -and $launcherSmoke.pass -and $kx134Smoke.pass -and $adxlSmoke.pass)
$result = [ordered]@{
    pass = $false
    package_smoke_pass = $packageSmokePass
    decision = "PENDING"
    created_at = (Get-Date).ToString("o")
    package_root = $packageRootFull
    exe = $exeFull
    exe_exists = $exeExists
    hostname = $env:COMPUTERNAME
    windows_version = @{
        caption = $os.Caption
        version = $os.Version
        build_number = $os.BuildNumber
        architecture = $os.OSArchitecture
    }
    resolution = $resolution
    scaling = $scaling
    launcher_smoke = $launcherSmoke
    kx134_smoke = $kx134Smoke
    adxl_smoke = $adxlSmoke
    launcher_smoke_pass = [bool]$launcherSmoke.pass
    kx134_smoke_pass = [bool]$kx134Smoke.pass
    adxl_smoke_pass = [bool]$adxlSmoke.pass
    visual_layout_pass = $null
    visual_manual_result = "pending"
    hardware_capture_run = $hardwareCaptureRun
    hardware_capture_pass = $null
    export_validation_pass = $hardwareValidation.pass
    hardware_artifacts = $hardwareArtifacts
    hardware_artifact_paths_exist = $artifactPathsExist
    hardware_validation = $hardwareValidation
    failures = @()
    warnings = @("visual_manual_pending", "hardware_capture_not_run_or_not_validated")
}

if (-not $exeExists) { $result.failures += "exe_missing" }
if ($RunSmoke -and -not $launcherSmoke.pass) { $result.failures += "launcher_smoke_failed" }
if ($RunKx134Smoke -and -not $kx134Smoke.pass) { $result.failures += "kx134_smoke_failed" }
if ($RunAdxlSmoke -and -not $adxlSmoke.pass) { $result.failures += "adxl_smoke_failed" }
if ($result.failures.Count -gt 0) {
    $result.decision = "NO"
} elseif ($result.visual_manual_result -eq "pass" -and $hardwareCaptureRun -and $hardwareValidation.pass -eq $true) {
    $result.decision = "YES"
    $result.pass = $true
} else {
    $result.decision = "PENDING"
}
$result.ready_for_client_prototype_qa = $result.decision

$jsonText = $result | ConvertTo-Json -Depth 12
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($outputFull, $jsonText, $utf8NoBom)
Write-Host "QA output: $outputFull"
if ($result.failures.Count -gt 0) {
    exit 1
}
exit 0
