% analyze_sensorC_multipose_static.m
% Consolidado multipose estatico para sensor_C.

%% Configuracion
sensor_id = "sensor_C";
poses = ["pos_x","neg_x","pos_y","neg_y","pos_z","neg_z"];
runs_per_pose = 3;
min_delta_mv = 50;      % separacion minima pos vs neg en eje esperado
dominance_ratio_min = 1.2; % eje esperado debe dominar sobre ejes cruzados

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
if ~isfolder(analysis_out_dir)
    mkdir(analysis_out_dir);
end

expected_cols = {'seq','t_us','raw_x','raw_y','raw_z','mv_x','mv_y','mv_z'};

%% Recoleccion de corridas por pose
run_pose = strings(0,1);
run_file = strings(0,1);
samples = zeros(0,1);
duration_s = zeros(0,1);
freq_hz = zeros(0,1);
seq_jumps = zeros(0,1);
raw_x_mean = zeros(0,1);
raw_y_mean = zeros(0,1);
raw_z_mean = zeros(0,1);
mv_x_mean = zeros(0,1);
mv_y_mean = zeros(0,1);
mv_z_mean = zeros(0,1);

for p = 1:numel(poses)
    pose = poses(p);
    raw_dir = fullfile(repo_dir, "data", "raw", char(sensor_id));
    pattern = char(sensor_id + "_" + pose + "_*.csv");
    files = dir(fullfile(raw_dir, pattern));
    if numel(files) < runs_per_pose
        error("Pose %s sin corridas suficientes (%d < %d).", pose, numel(files), runs_per_pose);
    end

    [~, order] = sort([files.datenum], "ascend");
    files = files(order);
    files = files((end-runs_per_pose+1):end);

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

        t_us = double(tbl.t_us);

        run_pose(end+1,1) = pose; %#ok<SAGROW>
        run_file(end+1,1) = string(files(i).name); %#ok<SAGROW>
        samples(end+1,1) = n; %#ok<SAGROW>
        duration_s(end+1,1) = (t_us(end)-t_us(1))/1e6; %#ok<SAGROW>
        freq_hz(end+1,1) = (n-1)/max(duration_s(end), eps); %#ok<SAGROW>
        seq_jumps(end+1,1) = nnz(diff(double(tbl.seq)) ~= 1); %#ok<SAGROW>
        raw_x_mean(end+1,1) = mean(double(tbl.raw_x)); %#ok<SAGROW>
        raw_y_mean(end+1,1) = mean(double(tbl.raw_y)); %#ok<SAGROW>
        raw_z_mean(end+1,1) = mean(double(tbl.raw_z)); %#ok<SAGROW>
        mv_x_mean(end+1,1) = mean(double(tbl.mv_x)); %#ok<SAGROW>
        mv_y_mean(end+1,1) = mean(double(tbl.mv_y)); %#ok<SAGROW>
        mv_z_mean(end+1,1) = mean(double(tbl.mv_z)); %#ok<SAGROW>
    end
end

run_tbl = table(run_pose, run_file, samples, duration_s, freq_hz, seq_jumps, ...
    raw_x_mean, raw_y_mean, raw_z_mean, mv_x_mean, mv_y_mean, mv_z_mean, ...
    'VariableNames', {'pose','run_file','samples','duration_s','freq_hz','seq_jumps', ...
    'raw_x_mean','raw_y_mean','raw_z_mean','mv_x_mean','mv_y_mean','mv_z_mean'});

%% Resumen por pose
pose_name = poses(:);
runs_found = zeros(numel(poses),1);
freq_mean_hz = zeros(numel(poses),1);
freq_std_hz = zeros(numel(poses),1);
seq_jumps_total = zeros(numel(poses),1);

raw_x_pose_mean = zeros(numel(poses),1);
raw_y_pose_mean = zeros(numel(poses),1);
raw_z_pose_mean = zeros(numel(poses),1);
mv_x_pose_mean = zeros(numel(poses),1);
mv_y_pose_mean = zeros(numel(poses),1);
mv_z_pose_mean = zeros(numel(poses),1);

raw_x_mean_range = zeros(numel(poses),1);
raw_y_mean_range = zeros(numel(poses),1);
raw_z_mean_range = zeros(numel(poses),1);
mv_x_mean_range = zeros(numel(poses),1);
mv_y_mean_range = zeros(numel(poses),1);
mv_z_mean_range = zeros(numel(poses),1);

for p = 1:numel(poses)
    pose = poses(p);
    idx = run_tbl.pose == pose;
    subset = run_tbl(idx,:);

    runs_found(p) = height(subset);
    freq_mean_hz(p) = mean(subset.freq_hz);
    freq_std_hz(p) = std(subset.freq_hz);
    seq_jumps_total(p) = sum(subset.seq_jumps);

    raw_x_pose_mean(p) = mean(subset.raw_x_mean);
    raw_y_pose_mean(p) = mean(subset.raw_y_mean);
    raw_z_pose_mean(p) = mean(subset.raw_z_mean);
    mv_x_pose_mean(p) = mean(subset.mv_x_mean);
    mv_y_pose_mean(p) = mean(subset.mv_y_mean);
    mv_z_pose_mean(p) = mean(subset.mv_z_mean);

    raw_x_mean_range(p) = max(subset.raw_x_mean) - min(subset.raw_x_mean);
    raw_y_mean_range(p) = max(subset.raw_y_mean) - min(subset.raw_y_mean);
    raw_z_mean_range(p) = max(subset.raw_z_mean) - min(subset.raw_z_mean);
    mv_x_mean_range(p) = max(subset.mv_x_mean) - min(subset.mv_x_mean);
    mv_y_mean_range(p) = max(subset.mv_y_mean) - min(subset.mv_y_mean);
    mv_z_mean_range(p) = max(subset.mv_z_mean) - min(subset.mv_z_mean);
end

pose_tbl = table(pose_name, runs_found, freq_mean_hz, freq_std_hz, seq_jumps_total, ...
    raw_x_pose_mean, raw_y_pose_mean, raw_z_pose_mean, ...
    mv_x_pose_mean, mv_y_pose_mean, mv_z_pose_mean, ...
    raw_x_mean_range, raw_y_mean_range, raw_z_mean_range, ...
    mv_x_mean_range, mv_y_mean_range, mv_z_mean_range, ...
    'VariableNames', {'pose','runs_found','freq_mean_hz','freq_std_hz','seq_jumps_total', ...
    'raw_x_pose_mean','raw_y_pose_mean','raw_z_pose_mean', ...
    'mv_x_pose_mean','mv_y_pose_mean','mv_z_pose_mean', ...
    'raw_x_mean_range','raw_y_mean_range','raw_z_mean_range', ...
    'mv_x_mean_range','mv_y_mean_range','mv_z_mean_range'});

%% Comparacion pos vs neg por eje esperado
pair_name = ["x_pair","y_pair","z_pair"]';
expected_axis = ["x","y","z"]';
pos_pose = ["pos_x","pos_y","pos_z"]';
neg_pose = ["neg_x","neg_y","neg_z"]';
delta_mv_x = zeros(3,1);
delta_mv_y = zeros(3,1);
delta_mv_z = zeros(3,1);
dominant_axis = strings(3,1);
delta_expected_mv = zeros(3,1);
dominance_ratio = zeros(3,1);
axis_dominant = false(3,1);
opposed_sign = false(3,1);
pair_coherent = false(3,1);

for i = 1:3
    pidx = pose_tbl.pose == pos_pose(i);
    nidx = pose_tbl.pose == neg_pose(i);
    d = [pose_tbl.mv_x_pose_mean(pidx)-pose_tbl.mv_x_pose_mean(nidx), ...
         pose_tbl.mv_y_pose_mean(pidx)-pose_tbl.mv_y_pose_mean(nidx), ...
         pose_tbl.mv_z_pose_mean(pidx)-pose_tbl.mv_z_pose_mean(nidx)];

    delta_mv_x(i) = d(1);
    delta_mv_y(i) = d(2);
    delta_mv_z(i) = d(3);

    [max_abs, max_idx] = max(abs(d));
    axes_map = ["x","y","z"];
    dominant_axis(i) = axes_map(max_idx);

    exp_idx = find(axes_map == expected_axis(i), 1);
    delta_expected_mv(i) = d(exp_idx);
    other_idx = setdiff(1:3, exp_idx);
    max_other_abs = max(abs(d(other_idx)));
    dominance_ratio(i) = abs(delta_expected_mv(i)) / max(max_other_abs, eps);

    axis_dominant(i) = dominant_axis(i) == expected_axis(i);
    opposed_sign(i) = abs(delta_expected_mv(i)) >= min_delta_mv;
    pair_coherent(i) = axis_dominant(i) && opposed_sign(i) && (dominance_ratio(i) >= dominance_ratio_min);
end

pair_tbl = table(pair_name, expected_axis, pos_pose, neg_pose, ...
    delta_mv_x, delta_mv_y, delta_mv_z, dominant_axis, delta_expected_mv, ...
    dominance_ratio, axis_dominant, opposed_sign, pair_coherent);

all_pairs_coherent = all(pair_coherent);
all_seq_ok = all(pose_tbl.seq_jumps_total == 0);

if all_pairs_coherent && all_seq_ok
    final_decision = "ready_for_final_calibration";
else
    final_decision = "multipose_inconsistent";
end

%% Guardado de artefactos
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
base = "sensor_C_multipose_static_" + stamp;
run_csv_out = fullfile(analysis_out_dir, char(base + "_runs.csv"));
pose_csv_out = fullfile(analysis_out_dir, char(base + "_poses.csv"));
pair_csv_out = fullfile(analysis_out_dir, char(base + "_pairs.csv"));
txt_out = fullfile(analysis_out_dir, char(base + ".txt"));

writetable(run_tbl, run_csv_out);
writetable(pose_tbl, pose_csv_out);
writetable(pair_tbl, pair_csv_out);

fid = fopen(txt_out, "w");
if fid < 0
    error("No fue posible crear salida multipose: %s", txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "analysis_script: matlab/analysis/analyze_sensorC_multipose_static.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "runs_per_pose: %d\n", runs_per_pose);
fprintf(fid, "run_csv: %s\n", strrep(run_csv_out, [repo_dir filesep], ""));
fprintf(fid, "pose_csv: %s\n", strrep(pose_csv_out, [repo_dir filesep], ""));
fprintf(fid, "pair_csv: %s\n", strrep(pair_csv_out, [repo_dir filesep], ""));
fprintf(fid, "final_decision: %s\n", final_decision);

for i = 1:height(pair_tbl)
    fprintf(fid, "pair_%s_dominant_axis: %s\n", pair_tbl.pair_name(i), pair_tbl.dominant_axis(i));
    fprintf(fid, "pair_%s_delta_expected_mv: %.6f\n", pair_tbl.pair_name(i), pair_tbl.delta_expected_mv(i));
    fprintf(fid, "pair_%s_dominance_ratio: %.6f\n", pair_tbl.pair_name(i), pair_tbl.dominance_ratio(i));
    fprintf(fid, "pair_%s_coherent: %s\n", pair_tbl.pair_name(i), string(pair_tbl.pair_coherent(i)));
end

%% Salida por consola
fprintf("\nMULTIPOSE_OK\n");
fprintf("RUN_CSV: %s\n", strrep(run_csv_out, [repo_dir filesep], ""));
fprintf("POSE_CSV: %s\n", strrep(pose_csv_out, [repo_dir filesep], ""));
fprintf("PAIR_CSV: %s\n", strrep(pair_csv_out, [repo_dir filesep], ""));
fprintf("TXT_OUT: %s\n", strrep(txt_out, [repo_dir filesep], ""));
fprintf("FINAL_DECISION: %s\n", final_decision);
