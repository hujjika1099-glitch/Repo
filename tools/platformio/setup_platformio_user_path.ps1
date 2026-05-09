Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$pioScriptsDir = Join-Path $env:USERPROFILE ".platformio\penv\Scripts"
$pioExe = Join-Path $pioScriptsDir "pio.exe"

if (-not (Test-Path $pioExe)) {
    Write-Error @"
No se encontro PlatformIO en:
  $pioExe

No se modifico el PATH de usuario.
"@
    exit 1
}

$currentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ([string]::IsNullOrWhiteSpace($currentUserPath)) {
    $currentUserPath = ""
}

$entries = $currentUserPath -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
$alreadyPresent = $false
foreach ($entry in $entries) {
    if ($entry.TrimEnd("\") -ieq $pioScriptsDir.TrimEnd("\")) {
        $alreadyPresent = $true
        break
    }
}

if ($alreadyPresent) {
    Write-Host "PlatformIO ya esta en el PATH de usuario:"
    Write-Host "  $pioScriptsDir"
    Write-Host "Cierre y abra PowerShell si la sesion actual aun no lo reconoce."
    exit 0
}

$newUserPath = if ($currentUserPath) {
    "$pioScriptsDir;$currentUserPath"
} else {
    $pioScriptsDir
}

[Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")

Write-Host "PlatformIO fue agregado al PATH de usuario:"
Write-Host "  $pioScriptsDir"
Write-Host "Cierre y abra PowerShell para que el cambio tome efecto."
