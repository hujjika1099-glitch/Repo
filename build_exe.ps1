<#
.SYNOPSIS
    Compila ADXL335_Captura.exe con PyInstaller y genera el ZIP de distribucion.

.DESCRIPTION
    Ejecutar desde la raiz del repositorio (donde esta este archivo):
        .\build_exe.ps1

    Resultado:
        dist\ADXL335_Captura.exe     -- ejecutable standalone
        dist\ADXL335_Captura_dist.zip -- ZIP listo para distribuir

    Estructura de datos que se crea automaticamente junto al .exe al primer uso:
        data\raw\sensor_B_live\
        data\processed\
        reports\analysis_outputs\

.NOTES
    Requiere que .venv este creado con Python 3.10+ y pyserial instalado.
    PyInstaller se instala automaticamente en el venv si no esta presente.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot  = $PSScriptRoot
$VenvPy    = Join-Path $RepoRoot ".venv\Scripts\python.exe"
$DistDir   = Join-Path $RepoRoot "dist"
$SpecFile  = Join-Path $RepoRoot "adxl_captura.spec"
$ExeName   = "ADXL335_Captura.exe"
$ZipName   = "ADXL335_Captura_dist.zip"

# --------------------------------------------------------------------------- #
# 1. Verificar entorno
# --------------------------------------------------------------------------- #
if (-not (Test-Path $VenvPy)) {
    Write-Error "No se encontro el entorno virtual en .venv\Scripts\python.exe`nCrea el venv primero: python -m venv .venv && .venv\Scripts\pip install -r requirements-gui.txt"
}

Write-Host ""
Write-Host "=== ADXL335 Captura - Build ===" -ForegroundColor Cyan
Write-Host "Repo: $RepoRoot"
Write-Host ""

# --------------------------------------------------------------------------- #
# 2. Instalar / verificar PyInstaller
# --------------------------------------------------------------------------- #
Write-Host "[1/4] Verificando PyInstaller..." -ForegroundColor Yellow
& $VenvPy -m pip install pyinstaller --quiet
if ($LASTEXITCODE -ne 0) { Write-Error "Fallo la instalacion de PyInstaller." }
Write-Host "      PyInstaller listo." -ForegroundColor Green

# --------------------------------------------------------------------------- #
# 3. Compilar el ejecutable
# --------------------------------------------------------------------------- #
Write-Host ""
Write-Host "[2/4] Compilando ejecutable (esto puede tardar 1-2 minutos)..." -ForegroundColor Yellow

$PyInstaller = Join-Path $RepoRoot ".venv\Scripts\pyinstaller.exe"

& $PyInstaller $SpecFile `
    --distpath "$DistDir" `
    --workpath (Join-Path $RepoRoot "build_work") `
    --noconfirm

if ($LASTEXITCODE -ne 0) { Write-Error "PyInstaller termino con errores." }

$ExePath = Join-Path $DistDir $ExeName
if (-not (Test-Path $ExePath)) {
    Write-Error "No se encontro el ejecutable en: $ExePath"
}

Write-Host "      Ejecutable generado: $ExePath" -ForegroundColor Green

# --------------------------------------------------------------------------- #
# 4. Crear ZIP de distribucion
# --------------------------------------------------------------------------- #
Write-Host ""
Write-Host "[3/4] Creando ZIP de distribucion..." -ForegroundColor Yellow

$ZipPath = Join-Path $DistDir $ZipName
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }

Compress-Archive -Path $ExePath -DestinationPath $ZipPath -CompressionLevel Optimal

Write-Host "      ZIP creado: $ZipPath" -ForegroundColor Green

# --------------------------------------------------------------------------- #
# 5. Resumen
# --------------------------------------------------------------------------- #
Write-Host ""
Write-Host "[4/4] Build completado." -ForegroundColor Green
Write-Host ""
Write-Host "Archivos generados:" -ForegroundColor Cyan
Write-Host "  Ejecutable : $ExePath"
Write-Host "  Distribucion: $ZipPath"
Write-Host ""
Write-Host "Para distribuir: copiar $ZipName a cualquier PC con Windows." -ForegroundColor Cyan
Write-Host "Al ejecutar ADXL335_Captura.exe por primera vez se crearan automaticamente:" -ForegroundColor Cyan
Write-Host "  data\raw\sensor_B_live\"
Write-Host "  data\processed\"
Write-Host "  reports\analysis_outputs\"
Write-Host ""
