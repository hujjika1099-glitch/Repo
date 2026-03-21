% analyze_sensorC_zpair_retest.m
% Reanalisis focalizado del par Z para sensor_C.

%% Configuracion
sensor_id = "sensor_C";
pos_pose = "pos_z";
neg_pose = "neg_z";
runs_per_pose = 5;
min_delta_mv = 50;
dominance_ratio_min = 1.2;
phase9_pair_csv_relpath = "reports/analysis_outputs/sensor_C_multipose_static_20260321_120320_pairs.csv";
phase91_comparison_csv_relpath = "reports/analysis_outputs/sensor_C_zpair_retest_20260321_125701_comparison.csv";

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
dominance_condition = dominance_ratio >= dominance_ratio_min;
seq_condition = all(seq_jumps_total == 0);
pair_coherent = axis_dominant && opposed_sign && dominance_condition;
approval_all_conditions = axis_dominant && dominance_condition && opposed_sign && seq_condition;

if approval_all_conditions
    final_decision = "z_pair_fixed";
else
    final_decision = "z_pair_still_inconsistent";
end

%% Comparacion contra fase 9 y 9.1
phase9_csv_path = fullfile(repo_dir, char(phase9_pair_csv_relpath));
phase9_found = isfile(phase9_csv_path);
phase91_csv_path = fullfile(repo_dir, char(phase91_comparison_csv_relpath));
phase91_found = isfile(phase91_csv_path);

phase9_delta_mv_x = NaN;
phase9_delta_mv_y = NaN;
phase9_delta_mv_z = NaN;
phase9_dominant_axis = "<NOT_FOUND>";
phase9_dominance_ratio = NaN;
phase9_pair_coherent = false;
phase9_seq_condition = true;

if phase9_found
    phase9_tbl = readtable(phase9_csv_path, "Delimiter", ",", "TextType", "string");
    zid = phase9_tbl.pair_name == "z_pair";
    if any(zid)
        phase9_delta_mv_x = double(phase9_tbl.delta_mv_x(zid));
        phase9_delta_mv_y = double(phase9_tbl.delta_mv_y(zid));
        phase9_delta_mv_z = double(phase9_tbl.delta_mv_z(zid));
        phase9_dominant_axis = string(phase9_tbl.dominant_axis(zid));
        phase9_dominance_ratio = double(phase9_tbl.dominance_ratio(zid));
        phase9_pair_coherent = logical(phase9_tbl.pair_coherent(zid));
    end
end

phase91_delta_mv_x = NaN;
phase91_delta_mv_y = NaN;
phase91_delta_mv_z = NaN;
phase91_dominant_axis = "<NOT_FOUND>";
phase91_dominance_ratio = NaN;
phase91_pair_coherent = false;
phase91_seq_condition = true;

if phase91_found
    phase91_tbl = readtable(phase91_csv_path, "Delimiter", ",", "TextType", "string");
    phase91_delta_mv_x = double(phase91_tbl.retest_delta_mv_x(1));
    phase91_delta_mv_y = double(phase91_tbl.retest_delta_mv_y(1));
    phase91_delta_mv_z = double(phase91_tbl.retest_delta_mv_z(1));
    phase91_dominant_axis = string(phase91_tbl.retest_dominant_axis(1));
    phase91_dominance_ratio = double(phase91_tbl.retest_dominance_ratio(1));
    phase91_pair_coherent = logical(phase91_tbl.retest_pair_coherent(1));
end

comparison_tbl = table( ...
    phase9_delta_mv_x, phase9_delta_mv_y, phase9_delta_mv_z, ...
    phase9_dominant_axis, phase9_dominance_ratio, phase9_pair_coherent, phase9_seq_condition, ...
    phase91_delta_mv_x, phase91_delta_mv_y, phase91_delta_mv_z, ...
    phase91_dominant_axis, phase91_dominance_ratio, phase91_pair_coherent, phase91_seq_condition, ...
    delta_mv_x, delta_mv_y, delta_mv_z, dominant_axis, dominance_ratio, ...
    pair_coherent, seq_condition, axis_dominant, dominance_condition, opposed_sign, ...
    approval_all_conditions, final_decision, ...
    'VariableNames', {'phase9_delta_mv_x','phase9_delta_mv_y','phase9_delta_mv_z', ...
    'phase9_dominant_axis','phase9_dominance_ratio','phase9_pair_coherent','phase9_seq_condition', ...
    'phase91_delta_mv_x','phase91_delta_mv_y','phase91_delta_mv_z', ...
    'phase91_dominant_axis','phase91_dominance_ratio','phase91_pair_coherent','phase91_seq_condition', ...
    'phase92_delta_mv_x','phase92_delta_mv_y','phase92_delta_mv_z','phase92_dominant_axis','phase92_dominance_ratio', ...
    'phase92_pair_coherent','phase92_seq_condition','cond1_dominant_axis_z','cond2_dominance_ratio_ok', ...
    'cond3_abs_delta_mv_z_ok','cond4_seq_jumps_zero','final_decision'});

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
fprintf(fid, "phase9_pair_csv: %s\n", strrep(phase9_csv_path, [repo_dir filesep], ""));
fprintf(fid, "phase9_found: %s\n", string(phase9_found));
fprintf(fid, "phase91_comparison_csv: %s\n", strrep(phase91_csv_path, [repo_dir filesep], ""));
fprintf(fid, "phase91_found: %s\n", string(phase91_found));
fprintf(fid, "final_decision: %s\n", final_decision);
fprintf(fid, "phase92_dominant_axis: %s\n", dominant_axis);
fprintf(fid, "phase92_delta_mv_z: %.6f\n", delta_mv_z);
fprintf(fid, "phase92_dominance_ratio: %.6f\n", dominance_ratio);
fprintf(fid, "phase92_pair_coherent: %s\n", string(pair_coherent));
fprintf(fid, "cond1_dominant_axis_z: %s\n", string(axis_dominant));
fprintf(fid, "cond2_dominance_ratio_ok: %s\n", string(dominance_condition));
fprintf(fid, "cond3_abs_delta_mv_z_ok: %s\n", string(opposed_sign));
fprintf(fid, "cond4_seq_jumps_zero: %s\n", string(seq_condition));
fprintf(fid, "approval_all_conditions: %s\n", string(approval_all_conditions));

%% Salida por consola
fprintf("\nZPAIR_RETEST_OK\n");
fprintf("RUN_CSV: %s\n", strrep(run_csv_out, [repo_dir filesep], ""));
fprintf("POSE_CSV: %s\n", strrep(pose_csv_out, [repo_dir filesep], ""));
fprintf("COMPARISON_CSV: %s\n", strrep(cmp_csv_out, [repo_dir filesep], ""));
fprintf("TXT_OUT: %s\n", strrep(txt_out, [repo_dir filesep], ""));
fprintf("FINAL_DECISION: %s\n", final_decision);
