% capture_single_sensor_baseline.m
% Captura baseline individual ADXL335 desde ESP32 por puerto serial.

%% Configuracion de captura
default_port = "COM5";
default_baud = 115200;
default_duration_s = 12;
default_sensor_id = "sensor_A";
default_pose_label = "z_plus_static";

if exist("port", "var") && strlength(string(port)) > 0
    port = string(port);
else
    env_port = string(getenv("ADXL_PORT"));
    if strlength(env_port) > 0
        port = env_port;
    else
        port = default_port;
    end
end

if exist("baud", "var") && ~isempty(baud)
    baud = double(baud);
else
    env_baud = str2double(getenv("ADXL_BAUD"));
    if ~isnan(env_baud) && env_baud > 0
        baud = env_baud;
    else
        baud = default_baud;
    end
end

if exist("duration_s", "var") && ~isempty(duration_s)
    duration_s = double(duration_s);
else
    env_duration = str2double(getenv("ADXL_DURATION_S"));
    if ~isnan(env_duration) && env_duration > 0
        duration_s = env_duration;
    else
        duration_s = default_duration_s;
    end
end

if exist("sensor_id", "var") && strlength(string(sensor_id)) > 0
    sensor_id = string(sensor_id);
else
    env_sensor = string(getenv("ADXL_SENSOR_ID"));
    if strlength(env_sensor) > 0
        sensor_id = env_sensor;
    else
        sensor_id = default_sensor_id;
    end
end

if exist("pose_label", "var") && strlength(string(pose_label)) > 0
    pose_label = string(pose_label);
else
    env_pose = string(getenv("ADXL_POSE_LABEL"));
    if strlength(env_pose) > 0
        pose_label = env_pose;
    else
        pose_label = default_pose_label;
    end
end

%% Rutas de salida (sin sobrescritura)
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
out_dir = fullfile(repo_dir, "data", "raw", char(sensor_id));
if ~isfolder(out_dir)
    mkdir(out_dir);
end

timestamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
base_name = sensor_id + "_" + pose_label + "_" + timestamp;
csv_path = fullfile(out_dir, char(base_name + ".csv"));
session_path = fullfile(out_dir, char(base_name + "_session.txt"));

suffix = 1;
while isfile(csv_path) || isfile(session_path)
    base_name = sensor_id + "_" + pose_label + "_" + timestamp + "_v" + string(suffix);
    csv_path = fullfile(out_dir, char(base_name + ".csv"));
    session_path = fullfile(out_dir, char(base_name + "_session.txt"));
    suffix = suffix + 1;
end

%% Captura serial
expected_header = "seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z";
metadata_lines = strings(0, 1);
samples = zeros(0, 8);
invalid_lines = 0;
header_seen = false;

capture_start_local = datetime("now", "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss Z");
fprintf("Iniciando captura en %s @ %d baud por %.1f s...\n", port, baud, duration_s);

s = serialport(port, baud, "Timeout", 1);
configureTerminator(s, "LF");
flush(s);

capture_tic = tic;
try
    while toc(capture_tic) < duration_s
        if s.NumBytesAvailable == 0
            pause(0.003);
            continue;
        end

        line = strtrim(string(readline(s)));
        if strlength(line) == 0
            continue;
        end

        if startsWith(line, "#")
            metadata_lines(end+1, 1) = line; %#ok<SAGROW>
            continue;
        end

        if line == expected_header
            header_seen = true;
            continue;
        end

        tokens = split(line, ",");
        if numel(tokens) ~= 8
            invalid_lines = invalid_lines + 1;
            continue;
        end

        values = str2double(tokens);
        if any(isnan(values))
            invalid_lines = invalid_lines + 1;
            continue;
        end

        samples(end+1, :) = values.'; %#ok<SAGROW>
    end
catch ME
    clear s;
    rethrow(ME);
end
capture_wall_s = toc(capture_tic);
clear s;

if isempty(samples)
    error("No se capturaron muestras CSV validas. Revisa puerto, firmware y formato serial.");
end

seq = samples(:, 1);
t_us = samples(:, 2);
seq_jumps = nnz(diff(seq) ~= 1);

if size(samples, 1) >= 2
    stream_duration_s = max(0, (t_us(end) - t_us(1)) / 1e6);
else
    stream_duration_s = 0;
end

if stream_duration_s > 0
    freq_hz = (size(samples, 1) - 1) / stream_duration_s;
else
    freq_hz = size(samples, 1) / max(capture_wall_s, eps);
end

%% Guardado de CSV
tbl = array2table(samples, ...
    "VariableNames", {'seq', 't_us', 'raw_x', 'raw_y', 'raw_z', 'mv_x', 'mv_y', 'mv_z'});
writetable(tbl, csv_path);

%% Guardado de metadatos de sesion
capture_end_local = datetime("now", "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss Z");
fid = fopen(session_path, "w");
if fid < 0
    error("No fue posible crear el archivo de sesion: %s", session_path);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "capture_script: matlab/calibration/capture_single_sensor_baseline.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "pose_label: %s\n", pose_label);
fprintf(fid, "port: %s\n", port);
fprintf(fid, "baud: %d\n", baud);
fprintf(fid, "requested_duration_s: %.3f\n", duration_s);
fprintf(fid, "real_duration_wall_s: %.3f\n", capture_wall_s);
fprintf(fid, "real_duration_stream_s: %.3f\n", stream_duration_s);
fprintf(fid, "samples_captured: %d\n", size(samples, 1));
fprintf(fid, "estimated_frequency_hz: %.3f\n", freq_hz);
fprintf(fid, "seq_jumps: %d\n", seq_jumps);
fprintf(fid, "invalid_lines_ignored: %d\n", invalid_lines);
fprintf(fid, "header_seen: %s\n", string(header_seen));
fprintf(fid, "capture_start_local: %s\n", string(capture_start_local));
fprintf(fid, "capture_end_local: %s\n", string(capture_end_local));
fprintf(fid, "csv_path: %s\n", csv_path);
fprintf(fid, "metadata_line_count: %d\n", numel(metadata_lines));
fprintf(fid, "metadata_lines_begin\n");
for k = 1:numel(metadata_lines)
    fprintf(fid, "%s\n", metadata_lines(k));
end
fprintf(fid, "metadata_lines_end\n");

%% Resumen final en consola
fprintf("\nCAPTURE_OK\n");
fprintf("CSV: %s\n", csv_path);
fprintf("SESSION: %s\n", session_path);
fprintf("SAMPLES: %d\n", size(samples, 1));
fprintf("DURATION_WALL_S: %.3f\n", capture_wall_s);
fprintf("DURATION_STREAM_S: %.3f\n", stream_duration_s);
fprintf("FREQ_EST_HZ: %.3f\n", freq_hz);
fprintf("SEQ_JUMPS: %d\n", seq_jumps);
fprintf("INVALID_LINES_IGNORED: %d\n", invalid_lines);
