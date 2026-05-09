param(
    [string] $Port = "COM5",
    [int] $Baud = 921600,
    [int] $SensorId = 1,
    [string] $ExpectedMac = "D4:E9:F4:E9:8E:1C",
    [int] $SampleRateHz = 100,
    [int] $OdrHz = 100,
    [int] $RangeG = 8,
    [int] $CaptureSeconds = 20,
    [int] $SettleSeconds = 3,
    [int] $MinSamples = 1500,
    [string] $OutputRoot = "",
    [string] $PhysicalLabel = "",
    [string] $NodeId = "",
    [bool] $ForceAcceptWarnings = $false,
    [ValidateSet("Auto", "SerialPort", "PlatformIO")]
    [string] $CaptureBackend = "Auto",
    [string] $ResumeSession = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ExpectedHeader = "protocol_version,session_id,sensor_id,physical_label,node_id,node_mac,seq,sensor_t_us,receiver_t_us,pc_wall_s,sync_group_id,pair_seq,x_raw,y_raw,z_raw,x_g,y_g,z_g,sample_rate_hz,odr_hz,range_g,calibration_id,calibration_applied,packet_status,packet_error_code,firmware_version,contract_version"
$ExpectedFields = $ExpectedHeader.Split(",")
$ForbiddenFields = @(
    "mv_x", "mv_y", "mv_z",
    "gx_est", "gy_est", "gz_est", "g_norm_est",
    "voltage_x", "voltage_y", "voltage_z",
    "millivolts_x", "millivolts_y", "millivolts_z"
)
$InvariantCulture = [System.Globalization.CultureInfo]::InvariantCulture

if ($SensorId -ne 1 -and $SensorId -ne 2) {
    throw "SensorId debe ser 1 o 2. Valor recibido: $SensorId"
}

if ([string]::IsNullOrWhiteSpace($PhysicalLabel)) {
    $PhysicalLabel = "KX134_SENSOR_$SensorId"
}
if ([string]::IsNullOrWhiteSpace($NodeId)) {
    $NodeId = "sensor_node_$SensorId"
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = "reports/kx134_calibration/sensor_$SensorId"
}
if ([string]::IsNullOrWhiteSpace($ExpectedMac) -and $SensorId -eq 1) {
    $ExpectedMac = "D4:E9:F4:E9:8E:1C"
}
if ([string]::IsNullOrWhiteSpace($ExpectedMac) -and $SensorId -eq 2) {
    throw "ExpectedMac es obligatorio para SensorId=2."
}

$CalibrationFile = "config/calibrations/kx134_sensor_$SensorId.json"
$CalibrationDecisionName = "SENSOR_${SensorId}_CALIBRATION_VALID"
$TicketTitle = if ($SensorId -eq 2) { "TICKET 011 - KX134 Sensor 2 six-position calibration" } else { "KX134 Sensor 1 six-position calibration" }

function Write-Section {
    param([string] $Text)
    Write-Host ""
    Write-Host "=== $Text ==="
}

function Convert-ToDouble {
    param([string] $Value)
    return [double]::Parse($Value, $InvariantCulture)
}

function Convert-ToInt64 {
    param([string] $Value)
    return [int64]::Parse($Value, $InvariantCulture)
}

function Get-Mean {
    param([double[]] $Values)
    if ($Values.Count -eq 0) { return 0.0 }
    return (($Values | Measure-Object -Average).Average)
}

function Get-StdDev {
    param([double[]] $Values)
    if ($Values.Count -le 1) { return 0.0 }
    $mean = Get-Mean -Values $Values
    $sum = 0.0
    foreach ($value in $Values) {
        $sum += [math]::Pow(($value - $mean), 2)
    }
    return [math]::Sqrt($sum / ($Values.Count - 1))
}

function Format-Number {
    param([double] $Value, [int] $Digits = 6)
    return $Value.ToString("F$Digits", $InvariantCulture)
}

function Write-Utf8NoBom {
    param(
        [string] $Path,
        [string] $Text
    )
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText((Resolve-Path -LiteralPath (Split-Path $Path -Parent)).Path + "\" + (Split-Path $Path -Leaf), $Text, $encoding)
}

function Write-LinesUtf8NoBom {
    param(
        [string] $Path,
        [string[]] $Lines
    )
    Write-Utf8NoBom -Path $Path -Text (($Lines -join [Environment]::NewLine) + [Environment]::NewLine)
}

function New-RecordFromCsvLine {
    param([string] $Line)
    $clean = $Line.Trim()
    if ($clean -eq $ExpectedHeader) {
        return $null
    }
    if (-not $clean.StartsWith("kx134.v3,")) {
        return $null
    }
    $parts = $clean.Split(",")
    if ($parts.Count -ne $ExpectedFields.Count) {
        return $null
    }
    $record = [ordered]@{}
    for ($i = 0; $i -lt $ExpectedFields.Count; $i++) {
        $record[$ExpectedFields[$i]] = $parts[$i].Trim()
    }
    return [pscustomobject]$record
}

function Read-SerialPortLines {
    param(
        [string] $PortName,
        [int] $BaudRate,
        [int] $Seconds
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $sp = New-Object System.IO.Ports.SerialPort $PortName, $BaudRate, "None", 8, "One"
    $sp.ReadTimeout = 500
    $sp.DtrEnable = $false
    $sp.RtsEnable = $false

    try {
        $sp.Open()
        $deadline = (Get-Date).AddSeconds($Seconds)
        while ((Get-Date) -lt $deadline) {
            try {
                $line = $sp.ReadLine()
                if ($null -ne $line) {
                    $clean = $line.Trim()
                    if ($clean.Length -gt 0) {
                        $lines.Add($clean)
                    }
                }
            } catch [System.TimeoutException] {
                # Continue until deadline.
            }
        }
    }
    finally {
        if ($sp.IsOpen) {
            $sp.Close()
        }
    }
    return ,$lines.ToArray()
}

function Stop-PlatformIoMonitorChildren {
    param([string] $PortName)
    try {
        $escapedPort = [regex]::Escape($PortName)
        $children = Get-CimInstance Win32_Process |
            Where-Object { $_.CommandLine -match "device\s+monitor" -and $_.CommandLine -match $escapedPort }
        foreach ($child in $children) {
            try {
                Stop-Process -Id $child.ProcessId -Force -ErrorAction SilentlyContinue
            } catch {
                # Best effort cleanup.
            }
        }
    } catch {
        # Best effort cleanup.
    }
}

function Read-PlatformIOLines {
    param(
        [string] $PortName,
        [int] $BaudRate,
        [int] $Seconds
    )

    $pioWrapper = Join-Path (Get-Location) "tools\platformio\pio.ps1"
    if (-not (Test-Path $pioWrapper)) {
        throw "No existe tools\platformio\pio.ps1; no se puede usar backend PlatformIO."
    }

    $tempBase = Join-Path $env:TEMP ("kx134_monitor_{0}_{1}" -f $PortName, ([guid]::NewGuid().ToString("N")))
    $stdoutPath = "$tempBase.out.txt"
    $stderrPath = "$tempBase.err.txt"
    $argList = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$pioWrapper`"",
        "device", "monitor",
        "-p", $PortName,
        "-b", $BaudRate.ToString($InvariantCulture),
        "--rts", "0",
        "--dtr", "0",
        "--raw",
        "--quiet"
    ) -join " "

    $process = Start-Process -FilePath "powershell.exe" -ArgumentList $argList -NoNewWindow -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
    Start-Sleep -Seconds $Seconds
    if (-not $process.HasExited) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    }
    Stop-PlatformIoMonitorChildren -PortName $PortName
    Start-Sleep -Milliseconds 300

    $lines = @()
    if (Test-Path $stdoutPath) {
        $lines += Get-Content -Path $stdoutPath -ErrorAction SilentlyContinue
    }
    if (Test-Path $stderrPath) {
        $lines += Get-Content -Path $stderrPath -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath $stdoutPath, $stderrPath -ErrorAction SilentlyContinue
    return ,$lines
}

function Get-ValidRecords {
    param([string[]] $Lines)
    $records = New-Object System.Collections.Generic.List[object]
    $headerSeen = $false
    foreach ($line in $Lines) {
        $clean = $line.Trim()
        if ($clean -eq $ExpectedHeader) {
            $headerSeen = $true
            continue
        }
        $record = New-RecordFromCsvLine -Line $clean
        if ($null -ne $record) {
            $records.Add($record)
        }
    }
    return [pscustomobject]@{
        HeaderSeen = $headerSeen
        Records = @($records.ToArray())
    }
}

function Read-Capture {
    param([int] $Seconds)

    if ($script:ActiveBackend -eq "SerialPort") {
        return Read-SerialPortLines -PortName $Port -BaudRate $Baud -Seconds $Seconds
    }
    if ($script:ActiveBackend -eq "PlatformIO") {
        return Read-PlatformIOLines -PortName $Port -BaudRate $Baud -Seconds $Seconds
    }

    throw "Backend activo desconocido: $script:ActiveBackend"
}

function Confirm-CaptureBackend {
    Write-Section "Verificacion de stream"
    Write-Host "Puerto: $Port"
    Write-Host "Baudrate: $Baud"
    Write-Host "Backend solicitado: $CaptureBackend"

    if ($CaptureBackend -eq "SerialPort") {
        $script:ActiveBackend = "SerialPort"
        return
    }
    if ($CaptureBackend -eq "PlatformIO") {
        $script:ActiveBackend = "PlatformIO"
        return
    }

    Write-Host "Probando System.IO.Ports.SerialPort durante 5 s..."
    $script:ActiveBackend = "SerialPort"
    try {
        $probeLines = Read-Capture -Seconds 5
        $probe = Get-ValidRecords -Lines $probeLines
        if ($probe.Records.Count -gt 0) {
            Write-Host "SerialPort recibio $($probe.Records.Count) filas validas."
            return
        }
        Write-Host "SerialPort no entrego filas CSV validas. Cambiando a PlatformIO monitor."
    } catch {
        Write-Host "SerialPort fallo: $($_.Exception.Message)"
        Write-Host "Cambiando a PlatformIO monitor."
    }

    $script:ActiveBackend = "PlatformIO"
}

function Confirm-ActiveCsvStream {
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        Write-Section "Confirmacion de CSV activo"
        Write-Host "Intento $attempt de 3 con backend $script:ActiveBackend."
        if ($script:ActiveBackend -eq "PlatformIO") {
            Write-Host "Al presionar Enter se abrira el monitor por 8 s."
            Write-Host "Justo despues de Enter, presione EN/RST una sola vez y sueltelo."
            Write-Host "NO presione BOOT."
            Read-Host "Presione Enter para verificar stream"
        }

        $probeLines = Read-Capture -Seconds 8
        $probe = Get-ValidRecords -Lines $probeLines
        if ($probe.HeaderSeen) {
            $script:HeaderGlobalSeen = $true
        }
        if ($probe.Records.Count -gt 0) {
            Write-Host "Stream confirmado: $($probe.Records.Count) filas CSV validas."
            return
        }

        Write-Host "No se recibieron filas CSV validas en este intento."
        if ($attempt -lt 3) {
            Write-Host "Revise que ningun monitor serial este abierto y que COM5 siga conectado."
        }
    }

    throw "No se pudo confirmar stream CSV KX134 v3 activo. No se inicia calibracion."
}

function Test-Header {
    param([bool] $HeaderSeen)
    if ($HeaderSeen) {
        return [pscustomobject]@{
            HeaderDetected = $true
            HeaderFallbackUsed = $false
            ForbiddenDetected = $false
            Message = "Encabezado KX134 v3 detectado."
        }
    }

    return [pscustomobject]@{
        HeaderDetected = $false
        HeaderFallbackUsed = $true
        ForbiddenDetected = $false
        Message = "Encabezado no visto en esta ventana; se usa fallback porque las filas tienen 27 campos."
    }
}

function Test-ForbiddenHeaderFields {
    $headerFields = $ExpectedHeader.Split(",")
    foreach ($field in $ForbiddenFields) {
        if ($headerFields -contains $field) {
            return $true
        }
    }
    return $false
}

function Analyze-Position {
    param(
        [object[]] $Records,
        [string] $PositionName,
        [string] $ExpectedAxis,
        [int] $ExpectedSign,
        [bool] $HeaderSeen
    )

    $failures = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]
    $samples = $Records.Count

    if ($samples -lt $MinSamples) {
        $failures.Add("samples_count_below_minimum")
    }

    $xG = New-Object System.Collections.Generic.List[double]
    $yG = New-Object System.Collections.Generic.List[double]
    $zG = New-Object System.Collections.Generic.List[double]
    $xRaw = New-Object System.Collections.Generic.List[double]
    $yRaw = New-Object System.Collections.Generic.List[double]
    $zRaw = New-Object System.Collections.Generic.List[double]
    $gNorm = New-Object System.Collections.Generic.List[double]
    $seqValues = New-Object System.Collections.Generic.List[int64]
    $timeValues = New-Object System.Collections.Generic.List[int64]
    $firmwareVersions = New-Object System.Collections.Generic.HashSet[string]
    $macValues = New-Object System.Collections.Generic.HashSet[string]

    $sensorIdInvalid = 0
    $labelInvalid = 0
    $nodeInvalid = 0
    $macInvalid = 0
    $sampleRateInvalid = 0
    $odrInvalid = 0
    $rangeInvalid = 0
    $protocolInvalid = 0
    $contractInvalid = 0
    $sensorInitErrors = 0
    $sensorReadErrors = 0
    $unknownErrors = 0
    $otherStatusErrors = 0

    foreach ($record in $Records) {
        $x = Convert-ToDouble $record.x_g
        $y = Convert-ToDouble $record.y_g
        $z = Convert-ToDouble $record.z_g
        $xG.Add($x)
        $yG.Add($y)
        $zG.Add($z)
        $xRaw.Add((Convert-ToDouble $record.x_raw))
        $yRaw.Add((Convert-ToDouble $record.y_raw))
        $zRaw.Add((Convert-ToDouble $record.z_raw))
        $gNorm.Add([math]::Sqrt(($x * $x) + ($y * $y) + ($z * $z)))
        $seqValues.Add((Convert-ToInt64 $record.seq))
        $timeValues.Add((Convert-ToInt64 $record.sensor_t_us))
        [void]$firmwareVersions.Add($record.firmware_version)
        [void]$macValues.Add($record.node_mac)

        if ([int]$record.sensor_id -ne $SensorId) { $sensorIdInvalid++ }
        if ($record.physical_label -ne $PhysicalLabel) { $labelInvalid++ }
        if ($record.node_id -ne $NodeId) { $nodeInvalid++ }
        if ([string]::IsNullOrWhiteSpace($record.node_mac) -or ($record.node_mac.ToUpperInvariant() -ne $ExpectedMac.ToUpperInvariant())) { $macInvalid++ }
        if ([int]$record.sample_rate_hz -ne $SampleRateHz) { $sampleRateInvalid++ }
        if ([int]$record.odr_hz -ne $OdrHz) { $odrInvalid++ }
        if ([int]$record.range_g -ne $RangeG) { $rangeInvalid++ }
        if ($record.protocol_version -ne "kx134.v3") { $protocolInvalid++ }
        if ($record.contract_version -ne "kx134.v3") { $contractInvalid++ }

        if ($record.packet_status -eq "SENSOR_INIT_ERROR" -or $record.packet_error_code -eq "SENSOR_INIT_ERROR") { $sensorInitErrors++ }
        if ($record.packet_status -eq "SENSOR_READ_ERROR" -or $record.packet_error_code -eq "SENSOR_READ_ERROR") { $sensorReadErrors++ }
        if ($record.packet_status -eq "UNKNOWN_ERROR" -or $record.packet_error_code -eq "UNKNOWN_ERROR") { $unknownErrors++ }
        $allowedStatuses = @("CALIBRATION_MISSING", "OK", "NONE")
        if (($allowedStatuses -notcontains $record.packet_status) -or ($allowedStatuses -notcontains $record.packet_error_code)) {
            if ($record.packet_status -ne "SENSOR_INIT_ERROR" -and $record.packet_error_code -ne "SENSOR_INIT_ERROR" -and
                $record.packet_status -ne "SENSOR_READ_ERROR" -and $record.packet_error_code -ne "SENSOR_READ_ERROR" -and
                $record.packet_status -ne "UNKNOWN_ERROR" -and $record.packet_error_code -ne "UNKNOWN_ERROR") {
                $otherStatusErrors++
            }
        }
    }

    if ($sensorIdInvalid -gt 0) { $failures.Add("sensor_id_invalid") }
    if ($labelInvalid -gt 0) { $failures.Add("physical_label_invalid") }
    if ($nodeInvalid -gt 0) { $failures.Add("node_id_invalid") }
    if ($macInvalid -gt 0) { $failures.Add("node_mac_invalid") }
    if ($sampleRateInvalid -gt 0) { $failures.Add("sample_rate_invalid") }
    if ($odrInvalid -gt 0) { $failures.Add("odr_invalid") }
    if ($rangeInvalid -gt 0) { $failures.Add("range_invalid") }
    if ($protocolInvalid -gt 0) { $failures.Add("protocol_version_invalid") }
    if ($contractInvalid -gt 0) { $failures.Add("contract_version_invalid") }
    if ($sensorInitErrors -gt 0) { $failures.Add("sensor_init_error") }
    if ($sensorReadErrors -gt 0) { $failures.Add("sensor_read_error") }
    if ($unknownErrors -gt 0) { $failures.Add("unknown_error") }
    if ($otherStatusErrors -gt 0) { $failures.Add("unexpected_packet_error") }

    $seqGaps = 0
    for ($i = 1; $i -lt $seqValues.Count; $i++) {
        $delta = $seqValues[$i] - $seqValues[$i - 1]
        if ($delta -ne 1) {
            $seqGaps++
        }
    }
    if ($seqGaps -gt 3) {
        $failures.Add("seq_gaps_gt_3")
    } elseif ($seqGaps -gt 0) {
        $warnings.Add("seq_gaps_1_to_3")
    }

    $timestampErrors = 0
    $dtList = New-Object System.Collections.Generic.List[double]
    for ($i = 1; $i -lt $timeValues.Count; $i++) {
        $dt = $timeValues[$i] - $timeValues[$i - 1]
        if ($dt -le 0) {
            $timestampErrors++
        } else {
            $dtList.Add([double]$dt)
        }
    }
    if ($timestampErrors -gt 0) {
        $failures.Add("timestamp_not_increasing")
    }

    $effectiveHz = 0.0
    if ($dtList.Count -gt 0) {
        $meanDtUs = Get-Mean -Values ([double[]]$dtList.ToArray())
        if ($meanDtUs -gt 0) {
            $effectiveHz = 1000000.0 / $meanDtUs
        }
    }
    if ($effectiveHz -lt 95.0 -or $effectiveHz -gt 105.0) {
        $failures.Add("effective_hz_outside_95_105")
    } elseif ($effectiveHz -lt 98.0 -or $effectiveHz -gt 102.0) {
        $warnings.Add("effective_hz_warning")
    }

    $meanX = Get-Mean -Values ([double[]]$xG.ToArray())
    $meanY = Get-Mean -Values ([double[]]$yG.ToArray())
    $meanZ = Get-Mean -Values ([double[]]$zG.ToArray())
    $stdX = Get-StdDev -Values ([double[]]$xG.ToArray())
    $stdY = Get-StdDev -Values ([double[]]$yG.ToArray())
    $stdZ = Get-StdDev -Values ([double[]]$zG.ToArray())
    $meanNorm = Get-Mean -Values ([double[]]$gNorm.ToArray())
    $stdNorm = Get-StdDev -Values ([double[]]$gNorm.ToArray())

    $axisMeans = @{
        x = $meanX
        y = $meanY
        z = $meanZ
    }
    $dominantAxis = "x"
    foreach ($axis in @("y", "z")) {
        if ([math]::Abs($axisMeans[$axis]) -gt [math]::Abs($axisMeans[$dominantAxis])) {
            $dominantAxis = $axis
        }
    }
    $dominantMean = $axisMeans[$dominantAxis]
    $expectedMean = $axisMeans[$ExpectedAxis]

    if ($meanNorm -lt 0.85 -or $meanNorm -gt 1.15) {
        $failures.Add("g_norm_mean_outside_0p85_1p15")
    }
    if ($stdNorm -gt 0.10) {
        $failures.Add("g_norm_std_gt_0p10")
    } elseif ($stdNorm -gt 0.05) {
        $warnings.Add("g_norm_std_warning")
    }
    if ($dominantAxis -ne $ExpectedAxis) {
        $failures.Add("dominant_axis_unexpected")
    }
    if (($ExpectedSign -gt 0 -and $expectedMean -le 0) -or ($ExpectedSign -lt 0 -and $expectedMean -ge 0)) {
        $failures.Add("dominant_axis_sign_invalid")
    }
    if ([math]::Abs($expectedMean) -lt 0.70) {
        $failures.Add("dominant_axis_magnitude_lt_0p70")
    }

    $status = "pass"
    if ($failures.Count -gt 0) {
        $status = "fail"
    } elseif ($warnings.Count -gt 0) {
        $status = "warning"
    }

    return [pscustomobject]@{
        position = $PositionName
        validation_status = $status
        accepted_with_warning = $false
        samples_count = $samples
        effective_hz = $effectiveHz
        seq_gaps = $seqGaps
        timestamp_errors = $timestampErrors
        mean_x_g = $meanX
        mean_y_g = $meanY
        mean_z_g = $meanZ
        std_x_g = $stdX
        std_y_g = $stdY
        std_z_g = $stdZ
        mean_x_raw = (Get-Mean -Values ([double[]]$xRaw.ToArray()))
        mean_y_raw = (Get-Mean -Values ([double[]]$yRaw.ToArray()))
        mean_z_raw = (Get-Mean -Values ([double[]]$zRaw.ToArray()))
        g_norm_mean = $meanNorm
        g_norm_std = $stdNorm
        dominant_axis = $dominantAxis
        dominant_mean_g = $dominantMean
        expected_axis = $ExpectedAxis
        expected_sign = $ExpectedSign
        failures = @($failures.ToArray())
        warnings = @($warnings.ToArray())
        header_seen = $HeaderSeen
        header_detected = $HeaderSeen
        header_fallback_used = (-not $HeaderSeen)
        firmware_versions = @($firmwareVersions.GetEnumerator())
        node_macs = @($macValues.GetEnumerator())
        sensor_init_errors = $sensorInitErrors
        sensor_read_errors = $sensorReadErrors
        unknown_errors = $unknownErrors
    }
}

function Save-CsvCapture {
    param(
        [string] $Path,
        [object[]] $Records
    )
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add($ExpectedHeader)
    foreach ($record in $Records) {
        $values = foreach ($field in $ExpectedFields) { $record.$field }
        $lines.Add(($values -join ","))
    }
    Write-LinesUtf8NoBom -Path $Path -Lines @($lines.ToArray())
}

function Show-PositionSummary {
    param([object] $Summary)
    Write-Host ("samples_count: {0}" -f $Summary.samples_count)
    Write-Host ("effective_hz: {0}" -f (Format-Number $Summary.effective_hz 3))
    Write-Host ("seq_gaps: {0}" -f $Summary.seq_gaps)
    Write-Host ("timestamp_errors: {0}" -f $Summary.timestamp_errors)
    Write-Host ("mean_x_g: {0}" -f (Format-Number $Summary.mean_x_g))
    Write-Host ("mean_y_g: {0}" -f (Format-Number $Summary.mean_y_g))
    Write-Host ("mean_z_g: {0}" -f (Format-Number $Summary.mean_z_g))
    Write-Host ("g_norm_mean: {0}" -f (Format-Number $Summary.g_norm_mean))
    Write-Host ("g_norm_std: {0}" -f (Format-Number $Summary.g_norm_std))
    Write-Host ("dominant_axis: {0}" -f $Summary.dominant_axis)
    Write-Host ("validation_status: {0}" -f $Summary.validation_status)
    if ($Summary.failures.Count -gt 0) {
        Write-Host ("failures: {0}" -f ($Summary.failures -join ", "))
    }
    if ($Summary.warnings.Count -gt 0) {
        Write-Host ("warnings: {0}" -f ($Summary.warnings -join ", "))
    }
}

function New-CalibrationFiles {
    param(
        [string] $SessionId,
        [string] $SessionDir,
        [string] $CaptureDir,
        [object[]] $PositionSummaries,
        [string] $CalibrationId
    )

    $byPosition = @{}
    foreach ($summary in $PositionSummaries) {
        $byPosition[$summary.position] = $summary
    }

    $xPos = $byPosition["X_POS"]
    $xNeg = $byPosition["X_NEG"]
    $yPos = $byPosition["Y_POS"]
    $yNeg = $byPosition["Y_NEG"]
    $zPos = $byPosition["Z_POS"]
    $zNeg = $byPosition["Z_NEG"]

    $offsetXG = ($xPos.mean_x_g + $xNeg.mean_x_g) / 2.0
    $offsetYG = ($yPos.mean_y_g + $yNeg.mean_y_g) / 2.0
    $offsetZG = ($zPos.mean_z_g + $zNeg.mean_z_g) / 2.0
    $scaleX = 2.0 / ($xPos.mean_x_g - $xNeg.mean_x_g)
    $scaleY = 2.0 / ($yPos.mean_y_g - $yNeg.mean_y_g)
    $scaleZ = 2.0 / ($zPos.mean_z_g - $zNeg.mean_z_g)

    $offsetXRaw = ($xPos.mean_x_raw + $xNeg.mean_x_raw) / 2.0
    $offsetYRaw = ($yPos.mean_y_raw + $yNeg.mean_y_raw) / 2.0
    $offsetZRaw = ($zPos.mean_z_raw + $zNeg.mean_z_raw) / 2.0
    $sensXRaw = ($xPos.mean_x_raw - $xNeg.mean_x_raw) / 2.0
    $sensYRaw = ($yPos.mean_y_raw - $yNeg.mean_y_raw) / 2.0
    $sensZRaw = ($zPos.mean_z_raw - $zNeg.mean_z_raw) / 2.0
    $expectedCounts = 4096.0

    $acceptedWarnings = @($PositionSummaries | Where-Object { $_.accepted_with_warning } | ForEach-Object { $_.position })
    $failedPositions = @($PositionSummaries | Where-Object { $_.validation_status -eq "fail" })
    $allPassed = ($failedPositions.Count -eq 0) -and ($acceptedWarnings.Count -eq 0)
    $seqGapsTotal = (($PositionSummaries | Measure-Object -Property seq_gaps -Sum).Sum)
    $timestampErrorsTotal = (($PositionSummaries | Measure-Object -Property timestamp_errors -Sum).Sum)
    $firstFirmware = (($PositionSummaries | ForEach-Object { $_.firmware_versions } | Where-Object { $_ } | Select-Object -First 1) -as [string])
    $firstMac = (($PositionSummaries | ForEach-Object { $_.node_macs } | Where-Object { $_ } | Select-Object -First 1) -as [string])
    if ([string]::IsNullOrWhiteSpace($firstMac)) {
        $firstMac = $ExpectedMac
    }

    $positionObjects = [ordered]@{}
    foreach ($summary in $PositionSummaries) {
        $positionObjects[$summary.position] = [ordered]@{
            samples_count = $summary.samples_count
            effective_hz = [math]::Round($summary.effective_hz, 6)
            seq_gaps = $summary.seq_gaps
            timestamp_errors = $summary.timestamp_errors
            mean_x_g = [math]::Round($summary.mean_x_g, 9)
            mean_y_g = [math]::Round($summary.mean_y_g, 9)
            mean_z_g = [math]::Round($summary.mean_z_g, 9)
            std_x_g = [math]::Round($summary.std_x_g, 9)
            std_y_g = [math]::Round($summary.std_y_g, 9)
            std_z_g = [math]::Round($summary.std_z_g, 9)
            mean_x_raw = [math]::Round($summary.mean_x_raw, 6)
            mean_y_raw = [math]::Round($summary.mean_y_raw, 6)
            mean_z_raw = [math]::Round($summary.mean_z_raw, 6)
            g_norm_mean = [math]::Round($summary.g_norm_mean, 9)
            g_norm_std = [math]::Round($summary.g_norm_std, 9)
            dominant_axis = $summary.dominant_axis
            validation_status = $summary.validation_status
            accepted_with_warning = $summary.accepted_with_warning
            header_detected = $summary.header_detected
            header_fallback_used = $summary.header_fallback_used
            failures = $summary.failures
            warnings = $summary.warnings
        }
    }

    $captureDirRel = "reports/kx134_calibration/sensor_$SensorId/$SessionId/captures"
    $calibration = [ordered]@{
        calibration_id = $CalibrationId
        status = "valid"
        sensor_id = $SensorId
        physical_label = $PhysicalLabel
        node_id = $NodeId
        node_mac = $firstMac
        sensor_model = "KX134"
        breakout_board = "SparkFun SEN-17589"
        sample_rate_hz = $SampleRateHz
        odr_hz = $OdrHz
        range_g = $RangeG
        calibration_method = "six_position_static"
        calibration_date = (Get-Date).ToString("o")
        operator = "USER_CONFIRMED"
        firmware_version = $firstFirmware
        contract_version = "kx134.v3"
        raw_data_directory = $captureDirRel
        coefficients = [ordered]@{
            offset_x_g = [math]::Round($offsetXG, 9)
            offset_y_g = [math]::Round($offsetYG, 9)
            offset_z_g = [math]::Round($offsetZG, 9)
            scale_x = [math]::Round($scaleX, 9)
            scale_y = [math]::Round($scaleY, 9)
            scale_z = [math]::Round($scaleZ, 9)
            offset_x_raw = [math]::Round($offsetXRaw, 6)
            offset_y_raw = [math]::Round($offsetYRaw, 6)
            offset_z_raw = [math]::Round($offsetZRaw, 6)
            sensitivity_x_counts_per_g = [math]::Round($sensXRaw, 6)
            sensitivity_y_counts_per_g = [math]::Round($sensYRaw, 6)
            sensitivity_z_counts_per_g = [math]::Round($sensZRaw, 6)
            expected_counts_per_g = [math]::Round($expectedCounts, 6)
            sensitivity_x_deviation_pct = [math]::Round(((($sensXRaw - $expectedCounts) / $expectedCounts) * 100.0), 6)
            sensitivity_y_deviation_pct = [math]::Round(((($sensYRaw - $expectedCounts) / $expectedCounts) * 100.0), 6)
            sensitivity_z_deviation_pct = [math]::Round(((($sensZRaw - $expectedCounts) / $expectedCounts) * 100.0), 6)
        }
        position_summaries = $positionObjects
        validation = [ordered]@{
            all_positions_captured = ($PositionSummaries.Count -eq 6)
            all_positions_passed = $allPassed
            accepted_with_warnings = $acceptedWarnings
            seq_gaps_total = [int]$seqGapsTotal
            timestamp_errors_total = [int]$timestampErrorsTotal
            forbidden_fields_detected = (Test-ForbiddenHeaderFields)
            header_detected_all_positions = (-not (@($PositionSummaries | Where-Object { -not $_.header_detected }).Count -gt 0))
            header_fallback_used = (@($PositionSummaries | Where-Object { $_.header_fallback_used }).Count -gt 0)
            sensor_id_validated = $true
            node_mac_validated = $true
            ready_for_future_application = $true
        }
        notes = @(
            "Calibration is valid for sensor_id=$SensorId, range_g=$RangeG, sample_rate_hz=$SampleRateHz.",
            "If range_g changes, repeat calibration.",
            "Raw data remains preserved in reports/kx134_calibration."
        )
    }

    $calibrationPath = $CalibrationFile
    New-Item -ItemType Directory -Force -Path (Split-Path $calibrationPath) | Out-Null
    if (Test-Path $calibrationPath) {
        $backupPath = "{0}.backup_{1}" -f $calibrationPath, (Get-Date -Format "yyyyMMdd_HHmmss")
        Copy-Item -LiteralPath $calibrationPath -Destination $backupPath -Force
        Write-Host "Calibracion existente respaldada en: $backupPath"
    }
    Write-Utf8NoBom -Path $calibrationPath -Text ($calibration | ConvertTo-Json -Depth 12)

    $nodeMapPath = "config/kx134_node_map.json"
    if (Test-Path $nodeMapPath) {
        $nodeMap = Get-Content -LiteralPath $nodeMapPath -Raw | ConvertFrom-Json
    } else {
        $nodeMap = [pscustomobject]@{
            topology_version = "kx134.dual_sensor_nodes_plus_receiver.v1"
            status = "pending"
            total_esp32_required = 3
            transport = [pscustomobject]@{
                sensor_nodes_to_receiver = "ESP-NOW"
                receiver_to_pc_gui = "USB Serial"
            }
            nodes = @(
                [pscustomobject]@{ role = "sensor_node"; node_id = "sensor_node_1"; sensor_id = 1; physical_label = "KX134_SENSOR_1"; esp32_mac = "PENDING_CAPTURE"; sensor_model = "KX134"; breakout_board = "SparkFun SEN-17589"; calibration_file = "config/calibrations/kx134_sensor_1.json"; status = "pending" },
                [pscustomobject]@{ role = "sensor_node"; node_id = "sensor_node_2"; sensor_id = 2; physical_label = "KX134_SENSOR_2"; esp32_mac = "PENDING_CAPTURE"; sensor_model = "KX134"; breakout_board = "SparkFun SEN-17589"; calibration_file = "config/calibrations/kx134_sensor_2.json"; status = "pending" },
                [pscustomobject]@{ role = "receiver_node"; node_id = "receiver_esp32"; sensor_id = $null; physical_label = "ESP32_RECEIVER"; esp32_mac = "PENDING_CAPTURE"; sensor_model = $null; breakout_board = $null; calibration_file = $null; receives_from_sensor_ids = @(1, 2); serial_output_to_pc = $true; status = "pending" }
            )
            rules = [pscustomobject]@{
                sensor_id_required = $true
                node_mac_required = $true
                do_not_infer_sensor_id = $true
                do_not_share_calibration_between_sensors = $true
                receiver_must_not_assign_default_sensor_id = $true
                pc_wall_s_not_primary_sync = $true
            }
        }
    }

    foreach ($node in $nodeMap.nodes) {
        if ($node.node_id -eq $NodeId) {
            $node.sensor_id = $SensorId
            $node.physical_label = $PhysicalLabel
            $node.esp32_mac = $firstMac
            $node.calibration_file = $calibrationPath
            $node.status = "calibrated"
            if ($node.PSObject.Properties.Name -contains "sample_rate_hz") { $node.sample_rate_hz = $SampleRateHz } else { $node | Add-Member -NotePropertyName sample_rate_hz -NotePropertyValue $SampleRateHz }
            if ($node.PSObject.Properties.Name -contains "odr_hz") { $node.odr_hz = $OdrHz } else { $node | Add-Member -NotePropertyName odr_hz -NotePropertyValue $OdrHz }
            if ($node.PSObject.Properties.Name -contains "range_g") { $node.range_g = $RangeG } else { $node | Add-Member -NotePropertyName range_g -NotePropertyValue $RangeG }
        }
    }

    $sensorNodes = @($nodeMap.nodes | Where-Object { $_.role -eq "sensor_node" })
    $calibratedSensorNodes = @($sensorNodes | Where-Object { $_.status -eq "calibrated" })
    if ($calibratedSensorNodes.Count -eq 2) {
        $nodeMap.status = "sensor_1_calibrated_sensor_2_calibrated_receiver_pending"
    } elseif ($SensorId -eq 2) {
        $nodeMap.status = "sensor_1_calibrated_sensor_2_calibrated_receiver_pending"
    }
    Write-Utf8NoBom -Path $nodeMapPath -Text ($nodeMap | ConvertTo-Json -Depth 12)

    $result = [ordered]@{
        session_id = $SessionId
        calibration_id = $CalibrationId
        sensor_calibration_valid = $true
        sensor_id = $SensorId
        calibration_valid_name = $CalibrationDecisionName
        port = $Port
        baud = $Baud
        capture_backend = $script:ActiveBackend
        calibration_file = $calibrationPath
        node_map_file = $nodeMapPath
        summary_file = "reports/kx134_calibration/sensor_$SensorId/$SessionId/calibration_summary.md"
        capture_directory = $captureDirRel
        coefficients = $calibration.coefficients
        position_summaries = $positionObjects
        validation = $calibration.validation
    }
    $resultPath = Join-Path $SessionDir "calibration_result.json"
    Write-Utf8NoBom -Path $resultPath -Text ($result | ConvertTo-Json -Depth 12)

    $summaryPath = Join-Path $SessionDir "calibration_summary.md"
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# $TicketTitle")
    $lines.Add("")
    $lines.Add("- session_id: $SessionId")
    $lines.Add("- calibration_id: $CalibrationId")
    $lines.Add("- port: $Port")
    $lines.Add("- baud: $Baud")
    $lines.Add("- backend: $script:ActiveBackend")
    $lines.Add("- sensor_id: $SensorId")
    $lines.Add("- physical_label: $PhysicalLabel")
    $lines.Add("- node_id: $NodeId")
    $lines.Add("- node_mac: $firstMac")
    $lines.Add("- sample_rate_hz: $SampleRateHz")
    $lines.Add("- odr_hz: $OdrHz")
    $lines.Add("- range_g: $RangeG")
    $lines.Add("- ${CalibrationDecisionName}: YES")
    $lines.Add("- header_detected_all_positions: $($calibration.validation.header_detected_all_positions)")
    $lines.Add("- header_fallback_used: $($calibration.validation.header_fallback_used)")
    $lines.Add("")
    $lines.Add("## Position summaries")
    foreach ($summary in $PositionSummaries) {
        $lines.Add("")
        $lines.Add("### $($summary.position)")
        $lines.Add("- samples_count: $($summary.samples_count)")
        $lines.Add("- effective_hz: $(Format-Number $summary.effective_hz 3)")
        $lines.Add("- seq_gaps: $($summary.seq_gaps)")
        $lines.Add("- timestamp_errors: $($summary.timestamp_errors)")
        $lines.Add("- mean_x_g: $(Format-Number $summary.mean_x_g)")
        $lines.Add("- mean_y_g: $(Format-Number $summary.mean_y_g)")
        $lines.Add("- mean_z_g: $(Format-Number $summary.mean_z_g)")
        $lines.Add("- g_norm_mean: $(Format-Number $summary.g_norm_mean)")
        $lines.Add("- g_norm_std: $(Format-Number $summary.g_norm_std)")
        $lines.Add("- dominant_axis: $($summary.dominant_axis)")
        $lines.Add("- validation_status: $($summary.validation_status)")
        $lines.Add("- accepted_with_warning: $($summary.accepted_with_warning)")
        $lines.Add("- header_detected: $($summary.header_detected)")
        $lines.Add("- header_fallback_used: $($summary.header_fallback_used)")
        if ($summary.failures.Count -gt 0) {
            $lines.Add("- failures: $($summary.failures -join ', ')")
        }
        if ($summary.warnings.Count -gt 0) {
            $lines.Add("- warnings: $($summary.warnings -join ', ')")
        }
    }
    $lines.Add("")
    $lines.Add("## Coefficients")
    foreach ($key in $calibration.coefficients.Keys) {
        $lines.Add("- ${key}: $($calibration.coefficients[$key])")
    }
    $lines.Add("")
    $lines.Add("## Generated files")
    $lines.Add("- $calibrationPath")
    $lines.Add("- config/kx134_node_map.json")
    $lines.Add("- reports/kx134_calibration/sensor_$SensorId/$SessionId/calibration_result.json")
    $lines.Add("- reports/kx134_calibration/sensor_$SensorId/$SessionId/captures/*.csv")
    $lines.Add("")
    $lines.Add("## Restrictions")
    $lines.Add("- Firmware was not modified by this calibration script.")
    $lines.Add("- GUI was not modified by this calibration script.")
    $lines.Add("- Packaging was not modified by this calibration script.")
    $lines.Add("- Historical data under data/ was not modified.")
    $lines.Add("- Calibration is not applied in firmware yet.")
    Write-LinesUtf8NoBom -Path $summaryPath -Lines @($lines.ToArray())

    return [pscustomobject]@{
        CalibrationPath = $calibrationPath
        NodeMapPath = "config/kx134_node_map.json"
        ResultPath = $resultPath
        SummaryPath = $summaryPath
        Calibration = $calibration
    }
}

$positions = @(
    [pscustomobject]@{ Name = "X_POS"; Axis = "x"; Sign = 1; Instruction = "Coloque el Sensor $SensorId con el eje +X apuntando hacia arriba, vertical hacia el techo. Mantenga el modulo quieto y presione Enter cuando este listo." },
    [pscustomobject]@{ Name = "X_NEG"; Axis = "x"; Sign = -1; Instruction = "Coloque el Sensor $SensorId con el eje -X apuntando hacia arriba, vertical hacia el techo. Mantenga el modulo quieto y presione Enter cuando este listo." },
    [pscustomobject]@{ Name = "Y_POS"; Axis = "y"; Sign = 1; Instruction = "Coloque el Sensor $SensorId con el eje +Y apuntando hacia arriba, vertical hacia el techo. Mantenga el modulo quieto y presione Enter cuando este listo." },
    [pscustomobject]@{ Name = "Y_NEG"; Axis = "y"; Sign = -1; Instruction = "Coloque el Sensor $SensorId con el eje -Y apuntando hacia arriba, vertical hacia el techo. Mantenga el modulo quieto y presione Enter cuando este listo." },
    [pscustomobject]@{ Name = "Z_POS"; Axis = "z"; Sign = 1; Instruction = "Coloque el Sensor $SensorId con el eje +Z apuntando hacia arriba, vertical hacia el techo. Mantenga el modulo quieto y presione Enter cuando este listo." },
    [pscustomobject]@{ Name = "Z_NEG"; Axis = "z"; Sign = -1; Instruction = "Coloque el Sensor $SensorId con el eje -Z apuntando hacia arriba, vertical hacia el techo. Mantenga el modulo quieto y presione Enter cuando este listo." }
)

if (-not [string]::IsNullOrWhiteSpace($ResumeSession)) {
    Write-Section "Reanudar desde capturas existentes"
    $script:ActiveBackend = "resume_existing_captures"
    $script:HeaderGlobalSeen = $true
    $sessionId = $ResumeSession
    $sessionDir = Join-Path $OutputRoot $sessionId
    $captureDir = Join-Path $sessionDir "captures"

    if (-not (Test-Path $captureDir)) {
        throw "No existe directorio de capturas: $captureDir"
    }

    $positionSummaries = New-Object System.Collections.Generic.List[object]
    foreach ($position in $positions) {
        $capturePath = Join-Path $captureDir ("{0}.csv" -f $position.Name)
        if (-not (Test-Path $capturePath)) {
            throw "Falta captura: $capturePath"
        }
        $lines = Get-Content -Path $capturePath
        $parsed = Get-ValidRecords -Lines $lines
        $summary = Analyze-Position -Records @($parsed.Records) -PositionName $position.Name -ExpectedAxis $position.Axis -ExpectedSign $position.Sign -HeaderSeen ($parsed.HeaderSeen -or $script:HeaderGlobalSeen)
        Show-PositionSummary -Summary $summary
        if ($summary.validation_status -eq "fail") {
            throw "La posicion $($position.Name) falla al reanalizar capturas existentes."
        }
        $positionSummaries.Add($summary)
    }

    $timestamp = $sessionId -replace "^kx134_sensor${SensorId}_cal_", ''
    if ([string]::IsNullOrWhiteSpace($timestamp)) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    }
    $calibrationId = "kx134_sensor_${SensorId}_$timestamp"
    $files = New-CalibrationFiles -SessionId $sessionId -SessionDir $sessionDir -CaptureDir $captureDir -PositionSummaries @($positionSummaries.ToArray()) -CalibrationId $calibrationId
    Write-Host "Archivo calibracion: $($files.CalibrationPath)"
    Write-Host "Node map: $($files.NodeMapPath)"
    Write-Host "Resultado: $($files.ResultPath)"
    Write-Host "Resumen: $($files.SummaryPath)"
    Write-Host "$CalibrationDecisionName = YES"
    exit 0
}

Write-Section "KX134 SENSOR $SensorId CALIBRACION INTERACTIVA"
Write-Host "No presione BOOT. No se subira firmware."
Write-Host "Use EN/RST solo si necesita reiniciar el stream antes de empezar."
Write-Host "Puerto: $Port"
Write-Host "Baud: $Baud"
Write-Host "SensorId: $SensorId"
Write-Host "ExpectedMac: $ExpectedMac"
Write-Host "CaptureSeconds: $CaptureSeconds"
Write-Host "SettleSeconds: $SettleSeconds"
Write-Host "MinSamples: $MinSamples"
Write-Host "Cableado esperado: 3V3->3V3, GND->GND, SDA->GPIO21, SCL->GPIO22."
Write-Host ""
Read-Host "Confirme que la ESP32 Sensor $SensorId esta conectada por USB y el cableado sigue correcto. Presione Enter para continuar"

Confirm-CaptureBackend
Write-Host "Backend activo: $script:ActiveBackend"

$script:HeaderGlobalSeen = $false
Confirm-ActiveCsvStream

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$sessionId = "kx134_sensor${SensorId}_cal_$timestamp"
$calibrationId = "kx134_sensor_${SensorId}_$timestamp"
$sessionDir = Join-Path $OutputRoot $sessionId
$captureDir = Join-Path $sessionDir "captures"
New-Item -ItemType Directory -Force -Path $captureDir | Out-Null

Write-Host "Sesion: $sessionId"
Write-Host "Directorio: $sessionDir"

$positionSummaries = New-Object System.Collections.Generic.List[object]

foreach ($position in $positions) {
    $done = $false
    while (-not $done) {
        Write-Section $position.Name
        Write-Host $position.Instruction
        Read-Host "Cuando el sensor este quieto en esta posicion, presione Enter"

        Write-Host "Estabilizando $SettleSeconds s (datos descartados)..."
        [void](Read-Capture -Seconds $SettleSeconds)

        Write-Host "Capturando $CaptureSeconds s..."
        $rawLines = Read-Capture -Seconds $CaptureSeconds
        $parsed = Get-ValidRecords -Lines $rawLines
        if ($parsed.HeaderSeen) {
            $script:HeaderGlobalSeen = $true
        }
        $headerCheck = Test-Header -HeaderSeen $parsed.HeaderSeen
        Write-Host $headerCheck.Message

        $records = @($parsed.Records)
        $capturePath = Join-Path $captureDir ("{0}.csv" -f $position.Name)
        Save-CsvCapture -Path $capturePath -Records $records
        Write-Host "CSV guardado: $capturePath"

        $summary = Analyze-Position -Records $records -PositionName $position.Name -ExpectedAxis $position.Axis -ExpectedSign $position.Sign -HeaderSeen $parsed.HeaderSeen
        Show-PositionSummary -Summary $summary

        if ($summary.validation_status -eq "pass") {
            $positionSummaries.Add($summary)
            $done = $true
            Write-Host "Decision: PASS. Avanzando a la siguiente posicion."
        } elseif ($summary.validation_status -eq "warning" -and $ForceAcceptWarnings) {
            $summary.accepted_with_warning = $true
            $positionSummaries.Add($summary)
            $done = $true
            Write-Host "Decision: WARNING aceptado automaticamente por ForceAcceptWarnings."
        } else {
            Write-Host ""
            Write-Host "Decision: $($summary.validation_status.ToUpperInvariant())."
            Write-Host "Opciones: R = repetir, A = aceptar bajo advertencia, Q = cancelar"
            $choice = (Read-Host "Seleccione R/A/Q").Trim().ToUpperInvariant()
            if ($choice -eq "R") {
                Write-Host "Se repetira $($position.Name)."
            } elseif ($choice -eq "A") {
                $summary.accepted_with_warning = $true
                if ($summary.validation_status -eq "fail") {
                    $summary.validation_status = "warning"
                }
                $positionSummaries.Add($summary)
                $done = $true
                Write-Host "Posicion aceptada bajo advertencia."
            } elseif ($choice -eq "Q") {
                $cancelResult = [ordered]@{
                    session_id = $sessionId
                    sensor_calibration_valid = $false
                    sensor_id = $SensorId
                    calibration_valid_name = $CalibrationDecisionName
                    cancelled_at_position = $position.Name
                    port = $Port
                    baud = $Baud
                    capture_backend = $script:ActiveBackend
                    partial_position_summaries = @($positionSummaries.ToArray())
                    message = "Calibration cancelled by user."
                }
                Write-Utf8NoBom -Path (Join-Path $sessionDir "calibration_result.json") -Text ($cancelResult | ConvertTo-Json -Depth 8)
                Write-Host "Calibracion cancelada. No se genero calibracion valida."
                exit 2
            } else {
                Write-Host "Opcion no reconocida; se repetira $($position.Name)."
            }
        }
    }
}

Write-Section "Calculo de coeficientes"
$files = New-CalibrationFiles -SessionId $sessionId -SessionDir $sessionDir -CaptureDir $captureDir -PositionSummaries @($positionSummaries.ToArray()) -CalibrationId $calibrationId
Write-Host "Archivo calibracion: $($files.CalibrationPath)"
Write-Host "Node map: $($files.NodeMapPath)"
Write-Host "Resultado: $($files.ResultPath)"
Write-Host "Resumen: $($files.SummaryPath)"
Write-Host ""
Write-Host "$CalibrationDecisionName = YES"
