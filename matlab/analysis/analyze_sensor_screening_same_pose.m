% analyze_sensor_screening_same_pose.m
% Screening comparativo entre sensores en misma pose.

%% Configuracion
sensor_ids = ["sensor_A","sensor_B","sensor_C"];
pose_label = "z_plus_static";
runs_per_sensor = 5;

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
if ~isfolder(analysis_out_dir)
    mkdir(analysis_out_dir);
end

expected_cols = {'seq','t_us','raw_x','raw_y','raw_z','mv_x','mv_y','mv_z'};

%% Recoleccion por corrida
run_sensor_id = strings(0,1);
run_file = strings(0,1);
samples = zeros(0,1);
duration_s = zeros(0,1);
freq_hz = zeros(0,1);
seq_jumps = zeros(0,1);
raw_z_mean = zeros(0,1);
mv_z_mean = zeros(0,1);
raw_z_std = zeros(0,1);
mv_z_std = zeros(0,1);

for s = 1:numel(sensor_ids)
    sid = sensor_ids(s);
    raw_dir = fullfile(repo_dir, "data", "raw", char(sid));
    pattern = char(sid + "_" + pose_label + "_*.csv");
    files = dir(fullfile(raw_dir, pattern));
    if numel(files) < runs_per_sensor
        error("Sensor %s no tiene corridas suficientes (%d < %d).", sid, numel(files), runs_per_sensor);
    end

    [~, order] = sort([files.datenum], "ascend");
    files = files(order);
    files = files((end-runs_per_sensor+1):end);

    for i = 1:numel(files)
        csv_path = fullfile(files(i).folder, files(i).name);
        tbl = readtable(csv_path, "Delimiter", ",", "TextType", "string");
        missing_cols = setdiff(expected_cols, tbl.Properties.VariableNames);
        if ~isempty(missing_cols)
            error("CSV sin columnas esperadas (%s): %s", files(i).name, strjoin(missing_cols, ", "));
        end
        tbl = tbl(:, expected_cols);

        n = height(tbl);
        if n < 2
            error("Corrida con muestras insuficientes: %s", files(i).name);
        end

        seq = double(tbl.seq);
        t_us = double(tbl.t_us);
        r_z = double(tbl.raw_z);
        m_z = double(tbl.mv_z);

        run_sensor_id(end+1,1) = sid; %#ok<SAGROW>
        run_file(end+1,1) = string(files(i).name); %#ok<SAGROW>
        samples(end+1,1) = n; %#ok<SAGROW>
        duration_s(end+1,1) = (t_us(end)-t_us(1))/1e6; %#ok<SAGROW>
        freq_hz(end+1,1) = (n-1)/max(duration_s(end), eps); %#ok<SAGROW>
        seq_jumps(end+1,1) = nnz(diff(seq) ~= 1); %#ok<SAGROW>
        raw_z_mean(end+1,1) = mean(r_z); %#ok<SAGROW>
        mv_z_mean(end+1,1) = mean(m_z); %#ok<SAGROW>
        raw_z_std(end+1,1) = std(r_z); %#ok<SAGROW>
        mv_z_std(end+1,1) = std(m_z); %#ok<SAGROW>
    end
end

run_tbl = table(run_sensor_id, run_file, samples, duration_s, freq_hz, seq_jumps, ...
    raw_z_mean, mv_z_mean, raw_z_std, mv_z_std, ...
    'VariableNames', {'sensor_id','run_file','samples','duration_s','freq_hz','seq_jumps', ...
    'raw_z_mean','mv_z_mean','raw_z_std','mv_z_std'});

%% Resumen por sensor
summary_sensor_id = strings(numel(sensor_ids),1);
runs_found = zeros(numel(sensor_ids),1);
freq_mean = zeros(numel(sensor_ids),1);
freq_std = zeros(numel(sensor_ids),1);
seq_jumps_total = zeros(numel(sensor_ids),1);
raw_z_mean_range = zeros(numel(sensor_ids),1);
mv_z_mean_range = zeros(numel(sensor_ids),1);
raw_z_std_mean = zeros(numel(sensor_ids),1);
mv_z_std_mean = zeros(numel(sensor_ids),1);
sensor_label = strings(numel(sensor_ids),1);

for s = 1:numel(sensor_ids)
    sid = sensor_ids(s);
    idx = run_tbl.sensor_id == sid;
    subset = run_tbl(idx,:);

    summary_sensor_id(s) = sid;
    runs_found(s) = height(subset);
    freq_mean(s) = mean(subset.freq_hz);
    freq_std(s) = std(subset.freq_hz);
    seq_jumps_total(s) = sum(subset.seq_jumps);
    raw_z_mean_range(s) = max(subset.raw_z_mean) - min(subset.raw_z_mean);
    mv_z_mean_range(s) = max(subset.mv_z_mean) - min(subset.mv_z_mean);
    raw_z_std_mean(s) = mean(subset.raw_z_std);
    mv_z_std_mean(s) = mean(subset.mv_z_std);
end

[~, best_idx] = min(mv_z_mean_range);
candidate_preferred_sensor = summary_sensor_id(best_idx);
best_mv_range = mv_z_mean_range(best_idx);

sensor_label(:) = "sensor_ok";
for s = 1:numel(sensor_ids)
    if mv_z_mean_range(s) > 5 * max(best_mv_range, eps)
        sensor_label(s) = "sensor_suspect";
    end
end

if nnz(sensor_label == "sensor_suspect") >= 2
    system_label = "fixture_issue";
else
    system_label = "no_fixture_issue_evidence";
end

summary_tbl = table(summary_sensor_id, runs_found, freq_mean, freq_std, seq_jumps_total, ...
    raw_z_mean_range, mv_z_mean_range, raw_z_std_mean, mv_z_std_mean, sensor_label, ...
    'VariableNames', {'sensor_id','runs_found','freq_mean_hz','freq_std_hz','seq_jumps_total', ...
    'raw_z_mean_range','mv_z_mean_range','raw_z_std_mean','mv_z_std_mean','sensor_label'});

%% Guardado de artefactos
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
base = "sensor_screening_" + pose_label + "_" + stamp;
run_csv_out = fullfile(analysis_out_dir, char(base + "_runs.csv"));
summary_csv_out = fullfile(analysis_out_dir, char(base + "_summary.csv"));
txt_out = fullfile(analysis_out_dir, char(base + ".txt"));

writetable(run_tbl, run_csv_out);
writetable(summary_tbl, summary_csv_out);

fid = fopen(txt_out, "w");
if fid < 0
    error("No fue posible crear salida de screening: %s", txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "analysis_script: matlab/analysis/analyze_sensor_screening_same_pose.m\n");
fprintf(fid, "pose_label: %s\n", pose_label);
fprintf(fid, "runs_per_sensor: %d\n", runs_per_sensor);
fprintf(fid, "run_csv: %s\n", strrep(run_csv_out, [repo_dir filesep], ""));
fprintf(fid, "summary_csv: %s\n", strrep(summary_csv_out, [repo_dir filesep], ""));
fprintf(fid, "candidate_preferred_sensor: %s\n", candidate_preferred_sensor);
fprintf(fid, "system_label: %s\n", system_label);

for s = 1:height(summary_tbl)
    fprintf(fid, "sensor_%s_label: %s\n", summary_tbl.sensor_id(s), summary_tbl.sensor_label(s));
    fprintf(fid, "sensor_%s_raw_z_mean_range: %.6f\n", summary_tbl.sensor_id(s), summary_tbl.raw_z_mean_range(s));
    fprintf(fid, "sensor_%s_mv_z_mean_range: %.6f\n", summary_tbl.sensor_id(s), summary_tbl.mv_z_mean_range(s));
end

%% Salida de consola
fprintf("\nSCREENING_OK\n");
fprintf("POSE_LABEL: %s\n", pose_label);
fprintf("RUNS_PER_SENSOR: %d\n", runs_per_sensor);
fprintf("RUN_CSV: %s\n", strrep(run_csv_out, [repo_dir filesep], ""));
fprintf("SUMMARY_CSV: %s\n", strrep(summary_csv_out, [repo_dir filesep], ""));
fprintf("TXT_OUT: %s\n", strrep(txt_out, [repo_dir filesep], ""));
fprintf("CANDIDATE_PREFERRED_SENSOR: %s\n", candidate_preferred_sensor);
fprintf("SYSTEM_LABEL: %s\n", system_label);
