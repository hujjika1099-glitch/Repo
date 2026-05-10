param(
    [string]$Port = "COM4",
    [int]$Baud = 921600,
    [int]$Seconds = 30,
    [string]$OutputPath = "",
    [int]$WarmupSeconds = 2
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputPath = "reports\kx134_test_runs\capture_serial_direct_$timestamp.txt"
}

$resolvedOutput = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
$outputDir = Split-Path -Parent $resolvedOutput
if (-not [string]::IsNullOrWhiteSpace($outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

$serial = New-Object System.IO.Ports.SerialPort
$serial.PortName = $Port
$serial.BaudRate = $Baud
$serial.Parity = [System.IO.Ports.Parity]::None
$serial.DataBits = 8
$serial.StopBits = [System.IO.Ports.StopBits]::One
$serial.Handshake = [System.IO.Ports.Handshake]::None
$serial.ReadTimeout = 200
$serial.WriteTimeout = 200
$serial.DtrEnable = $false
$serial.RtsEnable = $false
$serial.Encoding = [System.Text.Encoding]::ASCII
$writer = $null
$lineCount = 0

try {
    Write-Host "=== KX134 Serial Direct Capture ==="
    Write-Host "Port: $Port"
    Write-Host "Baud: $Baud"
    Write-Host "WarmupSeconds: $WarmupSeconds"
    Write-Host "CaptureSeconds: $Seconds"
    Write-Host "OutputPath: $resolvedOutput"
    Write-Host ""

    $writer = New-Object System.IO.StreamWriter($resolvedOutput, $false, [System.Text.Encoding]::UTF8)

    $serial.Open()
    $serial.DiscardInBuffer()
    if ($WarmupSeconds -gt 0) {
        Write-Host "Warmup iniciado. Si el receptor se reinicia al abrir el puerto, este periodo lo deja estabilizar."
        Start-Sleep -Seconds $WarmupSeconds
        $serial.DiscardInBuffer()
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $buffer = ""
    Write-Host "Capturando... no cierre esta ventana hasta que termine."

    while ($stopwatch.Elapsed.TotalSeconds -lt $Seconds) {
        $chunk = $serial.ReadExisting()
        if (-not [string]::IsNullOrEmpty($chunk)) {
            $buffer += $chunk
            while ($true) {
                $newlineIndex = $buffer.IndexOf("`n")
                if ($newlineIndex -lt 0) {
                    break
                }
                $line = $buffer.Substring(0, $newlineIndex).TrimEnd("`r", "`n")
                $buffer = $buffer.Substring($newlineIndex + 1)
                $writer.WriteLine($line)
                $lineCount++
                if (($lineCount % 500) -eq 0) {
                    $writer.Flush()
                    Write-Host "Lineas capturadas: $lineCount"
                }
            }
        }
        Start-Sleep -Milliseconds 20
    }

    if (-not [string]::IsNullOrWhiteSpace($buffer)) {
        $writer.WriteLine($buffer.TrimEnd("`r", "`n"))
        $lineCount++
    }
    $writer.Flush()

    Write-Host "Captura terminada."
    Write-Host "Lineas capturadas: $lineCount"
    Write-Host "Archivo: $resolvedOutput"
} catch {
    Write-Host "ERROR: no se pudo capturar desde $Port a $Baud." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
} finally {
    if ($writer -ne $null) {
        $writer.Flush()
        $writer.Close()
    }
    if ($serial -ne $null -and $serial.IsOpen) {
        $serial.Close()
        $serial.Dispose()
    }
}
