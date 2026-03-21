% analyze_sensorC_zpair_retest.m
% Reanalisis focalizado del par Z para sensor_C.

%% Configuracion
sensor_id = "sensor_C";
pos_pose = "pos_z";
neg_pose = "neg_z";
runs_per_pose = 5;
min_delta_mv = 50;
dominance_ratio_min = 1.2;
baseline_pair_csv_relpath = "reports/analysis_outputs/sensor_C_multipose_static_20260321_120320_pairs.csv";

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
if ~isfolder(analysis_out_dir)
    mkdir(analysis_out_dir);
end
raw_dir = fullfile(repo_dir, "data", "raw", char(sensor_id));

expected_cols = {'seq','t_us','raw_x','raw_y','raw_z','mv_x','mv_y','mv_z'};

%% Recoleccion de corridas (ultimas N por pose)
poses = [pos_pose, neg_pose];
run_pose = strings(0,1);
run_file = strings(0,1);
samples = zeros(0,1);
duration_s = zeros(0,1);
freq_hz = zeros(0,1);
seq_jumps = zeros(0,1);
mv_x_mean = zeros(0,1);
mv_y_mean = zeros(0,1);
mv_z_mean = zeros(0,1);

for p = 1:numel(poses)
    pose = poses(p);
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
        mv_x_mean(end+1,1) = mean(double(tbl.mv_x)); %#ok<SAGROW>
        mv_y_mean(end+1,1) = mean(double(tbl.mv_y)); %#ok<SAGROW>
        mv_z_mean(end+1,1) = mean(double(tbl.mv_z)); %#ok<SAGROW>
    end
end

run_tbl = table(run_pose, run_file, samples, duration_s, freq_hz, seq_jumps, ...
    mv_x_mean, mv_y_mean, mv_z_mean, ...
    'VariableNames', {'pose','run_file','samples','duration_s','freq_hz','seq_jumps', ...
    'mv_x_mean','mv_y_mean','mv_z_mean'});

%% Resumen por pose
pose_name = poses(:);
runs_found = zeros(2,1);
freq_mean_hz = zeros(2,1);
freq_std_hz = zeros(2,1);
seq_jumps_total = zeros(2,1);
mv_x_pose_mean = zeros(2,1);
mv_y_pose_mean = zeros(2,1);
mv_z_pose_mean = zeros(2,1);
mv_x_mean_range = zeros(2,1);
mv_y_mean_range = zeros(2,1);
mv_z_mean_range = zeros(2,1);

for p = 1:numel(poses)
    pose = poses(p);
    idx = run_tbl.pose == pose;
    subset = run_tbl(idx,:);

    runs_found(p) = height(subset);
    freq_mean_hz(p) = mean(subset.freq_hz);
    freq_std_hz(p) = std(subset.freq_hz);
    seq_jumps_total(p) = sum(subset.seq_jumps);
    mv_x_pose_mean(p) = mean(subset.mv_x_mean);
    mv_y_pose_mean(p) = mean(subset.mv_y_mean);
    mv_z_pose_mean(p) = mean(subset.mv_z_mean);
    mv_x_mean_range(p) = max(subset.mv_x_mean) - min(subset.mv_x_mean);
    mv_y_mean_range(p) = max(subset.mv_y_mean) - min(subset.mv_y_mean);
    mv_z_mean_range(p) = max(subset.mv_z_mean) - min(subset.mv_z_mean);
end

pose_tbl = table(pose_name, runs_found, freq_mean_hz, freq_std_hz, seq_jumps_total, ...
    mv_x_pose_mean, mv_y_pose_mean, mv_z_pose_mean, ...
    mv_x_mean_range, mv_y_mean_range, mv_z_mean_range, ...
    'VariableNames', {'pose','runs_found','freq_mean_hz','freq_std_hz','seq_jumps_total', ...
    'mv_x_pose_mean','mv_y_pose_mean','mv_z_pose_mean', ...
    'mv_x_mean_range','mv_y_mean_range','mv_z_mean_range'});

%% Metricas del par Z (retest)
pos_idx = pose_tbl.pose == pos_pose;
neg_idx = pose_tbl.pose == neg_pose;
delta_mv_x = pose_tbl.mv_x_pose_mean(pos_idx) - pose_tbl.mv_x_pose_mean(neg_idx);
delta_mv_y = pose_tbl.mv_y_pose_mean(pos_idx) - pose_tbl.mv_y_pose_mean(neg_idx);
delta_mv_z = pose_tbl.mv_z_pose_mean(pos_idx) - pose_tbl.mv_z_pose_mean(neg_idx);

d = [delta_mv_x, delta_mv_y, delta_mv_z];
[~, max_idx] = max(abs(d));
axes_map = ["x","y","z"];
dominant_axis = axes_map(max_idx);
delta_expected_mv = delta_mv_z;
max_other_abs = max(abs([delta_mv_x, delta_mv_y]));
dominance_ratio = abs(delta_expected_mv) / max(max_other_abs, eps);
axis_dominant = dominant_axis == "z";
opposed_sign = abs(delta_expected_mv) >= min_delta_mv;
pair_coherent = axis_dominant && opposed_sign && (dominance_ratio >= dominance_ratio_min);

if pair_coherent
    final_decision = "z_pair_fixed";
else
    final_decision = "z_pair_still_inconsistent";
end

%% Comparacion contra fase 9
baseline_csv_path = fullfile(repo_dir, char(baseline_pair_csv_relpath));
baseline_found = isfile(baseline_csv_path);

baseline_delta_mv_x = NaN;
baseline_delta_mv_y = NaN;
baseline_delta_mv_z = NaN;
baseline_dominant_axis = "<NOT_FOUND>";
baseline_dominance_ratio = NaN;
baseline_pair_coherent = false;

if baseline_found
    baseline_tbl = readtable(baseline_csv_path, "Delimiter", ",", "TextType", "string");
    zid = baseline_tbl.pair_name == "z_pair";
    if any(zid)
        baseline_delta_mv_x = double(baseline_tbl.delta_mv_x(zid));
        baseline_delta_mv_y = double(baseline_tbl.delta_mv_y(zid));
        baseline_delta_mv_z = double(baseline_tbl.delta_mv_z(zid));
        baseline_dominant_axis = string(baseline_tbl.dominant_axis(zid));
        baseline_dominance_ratio = double(baseline_tbl.dominance_ratio(zid));
        baseline_pair_coherent = logical(baseline_tbl.pair_coherent(zid));
    end
end

comparison_tbl = table( ...
    baseline_delta_mv_x, baseline_delta_mv_y, baseline_delta_mv_z, ...
    baseline_dominant_axis, baseline_dominance_ratio, baseline_pair_coherent, ...
    delta_mv_x, delta_mv_y, delta_mv_z, dominant_axis, dominance_ratio, pair_coherent, ...
    'VariableNames', {'baseline_delta_mv_x','baseline_delta_mv_y','baseline_delta_mv_z', ...
    'baseline_dominant_axis','baseline_dominance_ratio','baseline_pair_coherent', ...
    'retest_delta_mv_x','retest_delta_mv_y','retest_delta_mv_z', ...
    'retest_dominant_axis','retest_dominance_ratio','retest_pair_coherent'});

%% Guardado de artefactos
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
base = "sensor_C_zpair_retest_" + stamp;
run_csv_out = fullfile(analysis_out_dir, char(base + "_runs.csv"));
pose_csv_out = fullfile(analysis_out_dir, char(base + "_poses.csv"));
cmp_csv_out = fullfile(analysis_out_dir, char(base + "_comparison.csv"));
txt_out = fullfile(analysis_out_dir, char(base + ".txt"));

writetable(run_tbl, run_csv_out);
writetable(pose_tbl, pose_csv_out);
writetable(comparison_tbl, cmp_csv_out);

fid = fopen(txt_out, "w");
if fid < 0
    error("No fue posible crear salida z-pair: %s", txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "analysis_script: matlab/analysis/analyze_sensorC_zpair_retest.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "runs_per_pose: %d\n", runs_per_pose);
fprintf(fid, "run_csv: %s\n", strrep(run_csv_out, [repo_dir filesep], ""));
fprintf(fid, "pose_csv: %s\n", strrep(pose_csv_out, [repo_dir filesep], ""));
fprintf(fid, "comparison_csv: %s\n", strrep(cmp_csv_out, [repo_dir filesep], ""));
fprintf(fid, "baseline_pair_csv: %s\n", strrep(baseline_csv_path, [repo_dir filesep], ""));
fprintf(fid, "baseline_found: %s\n", string(baseline_found));
fprintf(fid, "final_decision: %s\n", final_decision);
fprintf(fid, "retest_dominant_axis: %s\n", dominant_axis);
fprintf(fid, "retest_delta_mv_z: %.6f\n", delta_mv_z);
fprintf(fid, "retest_dominance_ratio: %.6f\n", dominance_ratio);
fprintf(fid, "retest_pair_coherent: %s\n", string(pair_coherent));

%% Salida por consola
fprintf("\nZPAIR_RETEST_OK\n");
fprintf("RUN_CSV: %s\n", strrep(run_csv_out, [repo_dir filesep], ""));
fprintf("POSE_CSV: %s\n", strrep(pose_csv_out, [repo_dir filesep], ""));
fprintf("COMPARISON_CSV: %s\n", strrep(cmp_csv_out, [repo_dir filesep], ""));
fprintf("TXT_OUT: %s\n", strrep(txt_out, [repo_dir filesep], ""));
fprintf("FINAL_DECISION: %s\n", final_decision);
