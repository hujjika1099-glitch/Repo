% analyze_repeatability_same_pose.m
% Analisis comparativo de corridas repetidas para mismo sensor y pose.

%% Configuracion
default_sensor_id = "sensor_A";
default_pose_label = "z_plus_static";
default_min_runs_target = 3;   % objetivo operativo recomendado
default_use_latest_n_runs = 0; % 0 = usar todas las corridas

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

if exist("min_runs_target", "var") && ~isempty(min_runs_target)
    min_runs_target = double(min_runs_target);
else
    env_min_runs = str2double(getenv("ADXL_MIN_RUNS_TARGET"));
    if ~isnan(env_min_runs) && env_min_runs > 0
        min_runs_target = env_min_runs;
    else
        min_runs_target = default_min_runs_target;
    end
end

if exist("use_latest_n_runs", "var") && ~isempty(use_latest_n_runs)
    use_latest_n_runs = double(use_latest_n_runs);
else
    env_latest_n = str2double(getenv("ADXL_USE_LATEST_N_RUNS"));
    if ~isnan(env_latest_n) && env_latest_n >= 1
        use_latest_n_runs = env_latest_n;
    else
        use_latest_n_runs = default_use_latest_n_runs;
    end
end

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
raw_dir = fullfile(repo_dir, "data", "raw", char(sensor_id));
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
if ~isfolder(analysis_out_dir)
    mkdir(analysis_out_dir);
end

pattern = char(sensor_id + "_" + pose_label + "_*.csv");
files = dir(fullfile(raw_dir, pattern));
if isempty(files)
    error("No hay corridas para %s/%s en %s", sensor_id, pose_label, raw_dir);
end

[~, order] = sort([files.datenum], "ascend");
files = files(order);

if use_latest_n_runs >= 1 && numel(files) > use_latest_n_runs
    files = files((end - use_latest_n_runs + 1):end);
end

%% Recoleccion de metricas por corrida
run_names = strings(numel(files), 1);
n_samples = zeros(numel(files), 1);
duration_s = zeros(numel(files), 1);
freq_hz = zeros(numel(files), 1);
seq_jumps = zeros(numel(files), 1);
raw_x_mean = zeros(numel(files), 1);
raw_y_mean = zeros(numel(files), 1);
raw_z_mean = zeros(numel(files), 1);
mv_x_mean = zeros(numel(files), 1);
mv_y_mean = zeros(numel(files), 1);
mv_z_mean = zeros(numel(files), 1);

for i = 1:numel(files)
    csv_path = fullfile(files(i).folder, files(i).name);
    tbl = readtable(csv_path, "Delimiter", ",", "TextType", "string");
    expected_cols = {'seq','t_us','raw_x','raw_y','raw_z','mv_x','mv_y','mv_z'};
    missing_cols = setdiff(expected_cols, tbl.Properties.VariableNames);
    if ~isempty(missing_cols)
        error("CSV sin columnas esperadas (%s): %s", files(i).name, strjoin(missing_cols, ", "));
    end
    tbl = tbl(:, expected_cols);

    run_names(i) = string(files(i).name);
    n_samples(i) = height(tbl);
    if n_samples(i) > 1
        t_us = double(tbl.t_us);
        duration_s(i) = (t_us(end) - t_us(1)) / 1e6;
        freq_hz(i) = (n_samples(i) - 1) / max(duration_s(i), eps);
        seq_jumps(i) = nnz(diff(double(tbl.seq)) ~= 1);
    else
        duration_s(i) = 0;
        freq_hz(i) = NaN;
        seq_jumps(i) = 0;
    end

    raw_x_mean(i) = mean(double(tbl.raw_x));
    raw_y_mean(i) = mean(double(tbl.raw_y));
    raw_z_mean(i) = mean(double(tbl.raw_z));
    mv_x_mean(i) = mean(double(tbl.mv_x));
    mv_y_mean(i) = mean(double(tbl.mv_y));
    mv_z_mean(i) = mean(double(tbl.mv_z));
end

run_file = run_names;
overview_tbl = table(run_file, n_samples, duration_s, freq_hz, seq_jumps, ...
    raw_x_mean, raw_y_mean, raw_z_mean, mv_x_mean, mv_y_mean, mv_z_mean, ...
    'VariableNames', {'run_file','samples','duration_s','freq_hz','seq_jumps', ...
    'raw_x_mean','raw_y_mean','raw_z_mean','mv_x_mean','mv_y_mean','mv_z_mean'});

stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
base = sensor_id + "_" + pose_label + "_repeatability_" + stamp;
csv_out = fullfile(analysis_out_dir, char(base + ".csv"));
txt_out = fullfile(analysis_out_dir, char(base + ".txt"));
writetable(overview_tbl, csv_out);

fid = fopen(txt_out, "w");
if fid < 0
    error("No fue posible crear reporte de repetibilidad: %s", txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "analysis_script: matlab/analysis/analyze_repeatability_same_pose.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "pose_label: %s\n", pose_label);
fprintf(fid, "runs_found: %d\n", numel(files));
fprintf(fid, "min_runs_target: %d\n", min_runs_target);
fprintf(fid, "use_latest_n_runs: %d\n", use_latest_n_runs);
fprintf(fid, "overview_csv: %s\n", strrep(csv_out, [repo_dir filesep], ""));
fprintf(fid, "ready_for_comparison: %s\n", string(numel(files) >= min_runs_target));

if numel(files) >= 2
    fprintf(fid, "mv_z_mean_range: %.6f\n", max(mv_z_mean) - min(mv_z_mean));
    fprintf(fid, "raw_z_mean_range: %.6f\n", max(raw_z_mean) - min(raw_z_mean));
else
    fprintf(fid, "mv_z_mean_range: <insufficient_runs>\n");
    fprintf(fid, "raw_z_mean_range: <insufficient_runs>\n");
end

fprintf("\nREPEATABILITY_PREP_OK\n");
fprintf("RUNS_FOUND: %d\n", numel(files));
fprintf("MIN_RUNS_TARGET: %d\n", min_runs_target);
fprintf("USE_LATEST_N_RUNS: %d\n", use_latest_n_runs);
fprintf("OVERVIEW_CSV: %s\n", strrep(csv_out, [repo_dir filesep], ""));
fprintf("OVERVIEW_TXT: %s\n", strrep(txt_out, [repo_dir filesep], ""));
fprintf("READY_FOR_COMPARISON: %s\n", string(numel(files) >= min_runs_target));
