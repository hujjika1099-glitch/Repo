<#
.SYNOPSIS
    Build Windows package for Sistema de Captura de Acelerometria.

.DESCRIPTION
    Creates an onedir PyInstaller package and optional ZIP distribution without
    staging or committing generated binaries.
#>

param(
    [switch]$Clean,
    [switch]$CreateVenv,
    [switch]$SkipZip,
    [switch]$RunSmoke = $true,
    [switch]$OneDir = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = $PSScriptRoot
$VenvPy = Join-Path $RepoRoot ".venv\Scripts\python.exe"
$VenvPip = Join-Path $RepoRoot ".venv\Scripts\pip.exe"
$PyInstaller = Join-Path $RepoRoot ".venv\Scripts\pyinstaller.exe"
$SpecFile = Join-Path $RepoRoot "sistema_captura_acelerometria.spec"
$DistDir = Join-Path $RepoRoot "dist"
$BuildWork = Join-Path $RepoRoot "build_work"
$ProductDir = Join-Path $DistDir "Sistema_Captura_Acelerometria"
$ExePath = Join-Path $ProductDir "Sistema_Captura_Acelerometria.exe"
$ZipPath = Join-Path $DistDir "Sistema_Captura_Acelerometria_dist.zip"

Write-Host ""
Write-Host "=== Sistema de Captura de Acelerometria - Windows Build ===" -ForegroundColor Cyan
Write-Host "Repo: $RepoRoot"

if (-not (Test-Path $VenvPy)) {
    if (-not $CreateVenv) {
        Write-Error "No se encontro .venv\Scripts\python.exe. Crea el venv con: python -m venv .venv; .venv\Scripts\python.exe -m pip install -r requirements-gui.txt. O ejecuta este script con -CreateVenv."
    }
    Write-Host "[1/6] Creando venv local..." -ForegroundColor Yellow
    python -m venv (Join-Path $RepoRoot ".venv")
}

Write-Host "[2/6] Instalando/verificando dependencias en venv..." -ForegroundColor Yellow
& $VenvPy -m pip install --upgrade pip --quiet
& $VenvPy -m pip install -r (Join-Path $RepoRoot "requirements-gui.txt") --quiet
& $VenvPy -m pip install pyinstaller --quiet
if ($LASTEXITCODE -ne 0) { Write-Error "Fallo instalando dependencias de build." }

if ($Clean) {
    Write-Host "[3/6] Limpiando solo artefactos de build Windows..." -ForegroundColor Yellow
    if (Test-Path $ProductDir) { Remove-Item -LiteralPath $ProductDir -Recurse -Force }
    if (Test-Path $ZipPath) { Remove-Item -LiteralPath $ZipPath -Force }
    if (Test-Path $BuildWork) { Remove-Item -LiteralPath $BuildWork -Recurse -Force }
} else {
    Write-Host "[3/6] Clean omitido." -ForegroundColor Yellow
}

Write-Host "[4/6] Ejecutando PyInstaller..." -ForegroundColor Yellow
& $PyInstaller $SpecFile --distpath "$DistDir" --workpath "$BuildWork" --noconfirm
if ($LASTEXITCODE -ne 0) { Write-Error "PyInstaller termino con errores." }
if (-not (Test-Path $ExePath)) { Write-Error "No se encontro el ejecutable esperado: $ExePath" }

$ExeSizeMb = [Math]::Round((Get-Item $ExePath).Length / 1MB, 2)
Write-Host "      Exe: $ExePath ($ExeSizeMb MB)" -ForegroundColor Green

$SmokeLauncher = "not_run"
$SmokeKx134 = "not_run"
if ($RunSmoke) {
    Write-Host "[5/6] Ejecutando smoke del launcher..." -ForegroundColor Yellow
    & $ExePath --smoke --close-after-ms 1000
    if ($LASTEXITCODE -ne 0) { Write-Error "Smoke launcher fallo." }
    $SmokeLauncher = "pass"

    Write-Host "      Ejecutando smoke KX134..." -ForegroundColor Yellow
    & $ExePath --mode kx134 --smoke --close-after-ms 1000
    if ($LASTEXITCODE -ne 0) { Write-Error "Smoke KX134 fallo." }
    $SmokeKx134 = "pass"
}

if (-not $SkipZip) {
    Write-Host "[6/6] Creando ZIP de distribucion..." -ForegroundColor Yellow
    if (Test-Path $ZipPath) { Remove-Item -LiteralPath $ZipPath -Force }
    $zipCreated = $false
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        try {
            Start-Sleep -Seconds 2
            Compress-Archive -Path $ProductDir -DestinationPath $ZipPath -CompressionLevel Optimal
            $zipCreated = $true
            break
        } catch {
            if ($attempt -eq 5) { throw }
            if (Test-Path $ZipPath) { Remove-Item -LiteralPath $ZipPath -Force }
            Write-Host "      Reintentando ZIP por archivo temporalmente bloqueado ($attempt/5)..." -ForegroundColor Yellow
        }
    }
    if (-not $zipCreated) { Write-Error "No se pudo crear el ZIP de distribucion." }
    $ZipSizeMb = [Math]::Round((Get-Item $ZipPath).Length / 1MB, 2)
    Write-Host "      ZIP: $ZipPath ($ZipSizeMb MB)" -ForegroundColor Green
} else {
    Write-Host "[6/6] ZIP omitido por -SkipZip." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Build completado." -ForegroundColor Green
Write-Host "Ejecutable : $ExePath"
Write-Host "Distribucion: $ZipPath"
Write-Host "Smoke launcher: $SmokeLauncher"
Write-Host "Smoke KX134: $SmokeKx134"
Write-Host ""
Write-Host "Para distribuir: copiar la carpeta dist\Sistema_Captura_Acelerometria o el ZIP dist\Sistema_Captura_Acelerometria_dist.zip." -ForegroundColor Cyan
