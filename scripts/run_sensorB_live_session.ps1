param(
    [string]$Port = "COM5",
    [int]$DurationS = 20,
    [string]$SessionName = "live_demo",
    [string]$FilePrefix = "sensor_B_live",
    [string]$OutputDirRelpath = "data/raw/sensor_B_live",
    [string]$ProcessedDirRelpath = "data/processed",
    [switch]$NoCsv,
    [switch]$NoMat,
    [string]$LivePlotMode = "mv"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$saveCsvText = if ($NoCsv) { "false" } else { "true" }
$saveMatText = if ($NoMat) { "false" } else { "true" }

$cmd = @"
try
    sensor_id='sensor_B';
    port='$Port';
    duration_s=$DurationS;
    session_name='$SessionName';
    file_prefix='$FilePrefix';
    output_dir_relpath='$OutputDirRelpath';
    processed_dir_relpath='$ProcessedDirRelpath';
    save_csv=$saveCsvText;
    save_mat=$saveMatText;
    prompt_user=false;
    live_plot_mode='$LivePlotMode';
    show_live_plot=true;
    run('matlab/live/run_sensorB_live_session.m');
catch ME
    disp(getReport(ME,'extended'));
end
"@

matlab -r $cmd
