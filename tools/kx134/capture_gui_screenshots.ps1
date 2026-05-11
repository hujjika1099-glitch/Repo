param(
    [string]$OutputDir = "docs\assets\screenshots",
    [ValidateSet("Screen", "ActiveWindow")]
    [string]$Mode = "Screen"
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class NativeWindowCapture {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
}
"@

function Save-Screenshot {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Mode
    )

    if ($Mode -eq "ActiveWindow") {
        $handle = [NativeWindowCapture]::GetForegroundWindow()
        $rect = New-Object NativeWindowCapture+RECT
        [NativeWindowCapture]::GetWindowRect($handle, [ref]$rect) | Out-Null
        $width = [Math]::Max(1, $rect.Right - $rect.Left)
        $height = [Math]::Max(1, $rect.Bottom - $rect.Top)
        $bounds = New-Object System.Drawing.Rectangle($rect.Left, $rect.Top, $width, $height)
    } else {
        $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    }

    $bitmap = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
        $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

$shots = @(
    @{ Name = "launcher_main.png"; Prompt = "Abra el launcher principal y presione Enter para capturar." },
    @{ Name = "kx134_connection_tab.png"; Prompt = "Abra KX134 en la pestana Conexion y presione Enter." },
    @{ Name = "kx134_capture_tab.png"; Prompt = "Cambie a Captura y presione Enter." },
    @{ Name = "kx134_sensors_tab.png"; Prompt = "Cambie a Sensores y presione Enter." },
    @{ Name = "kx134_live_plots_tab.png"; Prompt = "Cambie a Graficas y presione Enter." },
    @{ Name = "kx134_diagnostics_tab.png"; Prompt = "Cambie a Diagnostico y presione Enter." },
    @{ Name = "kx134_export_tab.png"; Prompt = "Cambie a Exportacion y presione Enter." },
    @{ Name = "adxl_legacy_window.png"; Prompt = "Abra ADXL335 historico si aplica y presione Enter; escriba SKIP para omitir." }
)

New-Item -ItemType Directory -Force $OutputDir | Out-Null

Write-Host "Captura guiada de screenshots KX134."
Write-Host "Modo: $Mode"
Write-Host "Salida: $OutputDir"
Write-Host "No capture informacion sensible ni rutas privadas visibles."

foreach ($shot in $shots) {
    $answer = Read-Host $shot.Prompt
    if ($answer -match "^(SKIP|skip|SALTAR|saltar)$") {
        Write-Host "Omitido: $($shot.Name)"
        continue
    }
    $path = Join-Path $OutputDir $shot.Name
    Save-Screenshot -Path $path -Mode $Mode
    $item = Get-Item $path
    Write-Host "Guardado: $path ($([Math]::Round($item.Length / 1MB, 3)) MB)"
}

Write-Host "Captura guiada finalizada."
