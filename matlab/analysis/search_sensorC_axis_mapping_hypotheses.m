% search_sensorC_axis_mapping_hypotheses.m
% Busqueda exhaustiva de hipotesis de mapeo/signo para sensor_C usando
% datasets historicos ya capturados (sin nuevas adquisiciones).

%% Configuracion
default_sensor_id = "sensor_C";
default_dataset_manifest_relpath = "";
default_expected_pose_order = ["pos_x","neg_x","pos_y","neg_y","pos_z","neg_z"];
default_top_n = 10;

if exist("sensor_id", "var") && strlength(string(sensor_id)) > 0
    sensor_id = string(sensor_id);
else
    sensor_id = default_sensor_id;
end

if exist("dataset_manifest_relpath", "var") && strlength(string(dataset_manifest_relpath)) > 0
    dataset_manifest_relpath = string(dataset_manifest_relpath);
else
    dataset_manifest_relpath = default_dataset_manifest_relpath;
end

if exist("expected_pose_order", "var") && ~isempty(expected_pose_order)
    expected_pose_order = string(expected_pose_order(:))';
else
    expected_pose_order = default_expected_pose_order;
end

if exist("top_n", "var") && ~isempty(top_n)
    top_n = double(top_n);
else
    top_n = default_top_n;
end
top_n = max(1, round(top_n));

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
raw_dir = fullfile(repo_dir, "data", "raw", char(sensor_id));
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
if ~isfolder(analysis_out_dir)
    mkdir(analysis_out_dir);
end

%% Dataset
[manifest_abs, manifest_relpath, manifest_tbl] = resolve_manifest(repo_dir, analysis_out_dir, sensor_id, dataset_manifest_relpath);
required_manifest_cols = {'pose','run_file'};
missing_manifest_cols = setdiff(required_manifest_cols, manifest_tbl.Properties.VariableNames);
if ~isempty(missing_manifest_cols)
    error("Manifest sin columnas requeridas: %s", strjoin(missing_manifest_cols, ", "));
end

manifest_tbl.pose = string(manifest_tbl.pose);
manifest_tbl.run_file = string(manifest_tbl.run_file);

for i = 1:numel(expected_pose_order)
    p = expected_pose_order(i);
    if ~any(manifest_tbl.pose == p)
        error("El manifest no contiene corridas para la pose requerida: %s", p);
    end
end

%% Lectura de corridas base
expected_cols = {'seq','t_us','raw_x','raw_y','raw_z','mv_x','mv_y','mv_z'};
n_rows = height(manifest_tbl);

run_pose = strings(n_rows,1);
run_file = strings(n_rows,1);
samples = zeros(n_rows,1);
duration_s = zeros(n_rows,1);
freq_hz = zeros(n_rows,1);
seq_jumps = zeros(n_rows,1);

mean_raw_x = zeros(n_rows,1);
mean_raw_y = zeros(n_rows,1);
mean_raw_z = zeros(n_rows,1);
mean_mv_x = zeros(n_rows,1);
mean_mv_y = zeros(n_rows,1);
mean_mv_z = zeros(n_rows,1);
expected_axis = strings(n_rows,1);
expected_sign = zeros(n_rows,1);

for r = 1:n_rows
    pose_name = string(manifest_tbl.pose(r));
    file_name = string(manifest_tbl.run_file(r));
    csv_abs = fullfile(raw_dir, char(file_name));
    if ~isfile(csv_abs)
        error("CSV listado en manifest no existe: %s", csv_abs);
    end

    tbl = readtable(csv_abs, "Delimiter", ",", "TextType", "string");
    missing_cols = setdiff(expected_cols, tbl.Properties.VariableNames);
    if ~isempty(missing_cols)
        error("CSV sin columnas esperadas (%s): %s", file_name, strjoin(missing_cols, ", "));
    end
    tbl = tbl(:, expected_cols);
    n = height(tbl);
    if n < 2
        error("Corrida con muestras insuficientes: %s", file_name);
    end

    seq_col = double(tbl.seq);
    t_us = double(tbl.t_us);
    [exp_axis, exp_sign] = expected_from_pose(pose_name);

    run_pose(r) = pose_name;
    run_file(r) = file_name;
    samples(r) = n;
    duration_s(r) = (t_us(end) - t_us(1)) / 1e6;
    freq_hz(r) = (n - 1) / max(duration_s(r), eps);
    seq_jumps(r) = nnz(diff(seq_col) ~= 1);
    mean_raw_x(r) = mean(double(tbl.raw_x));
    mean_raw_y(r) = mean(double(tbl.raw_y));
    mean_raw_z(r) = mean(double(tbl.raw_z));
    mean_mv_x(r) = mean(double(tbl.mv_x));
    mean_mv_y(r) = mean(double(tbl.mv_y));
    mean_mv_z(r) = mean(double(tbl.mv_z));
    expected_axis(r) = exp_axis;
    expected_sign(r) = exp_sign;
end

run_base_tbl = table( ...
    run_pose, run_file, samples, duration_s, freq_hz, seq_jumps, ...
    mean_raw_x, mean_raw_y, mean_raw_z, mean_mv_x, mean_mv_y, mean_mv_z, ...
    expected_axis, expected_sign, ...
    'VariableNames', {'pose','run_file','samples','duration_s','freq_hz','seq_jumps', ...
    'mean_raw_x','mean_raw_y','mean_raw_z','mean_mv_x','mean_mv_y','mean_mv_z', ...
    'expected_axis','expected_sign'});

%% Hipotesis: 6 permutaciones x 8 combinaciones de signo = 48
channel_labels = ["x","y","z"];
perm_all = perms(1:3); % 6x3
[sx, sy, sz] = ndgrid([-1 1], [-1 1], [-1 1]);
sign_all = [sx(:), sy(:), sz(:)]; % 8x3

n_hyp = size(perm_all,1) * size(sign_all,1);
hypothesis_id = zeros(n_hyp,1);
perm_index = zeros(n_hyp,1);
sign_index = zeros(n_hyp,1);
phys_x_source = strings(n_hyp,1);
phys_y_source = strings(n_hyp,1);
phys_z_source = strings(n_hyp,1);
sign_x = zeros(n_hyp,1);
sign_y = zeros(n_hyp,1);
sign_z = zeros(n_hyp,1);
mapping_label = strings(n_hyp,1);
sign_label = strings(n_hyp,1);
offset_x_mv = zeros(n_hyp,1);
offset_y_mv = zeros(n_hyp,1);
offset_z_mv = zeros(n_hyp,1);
sens_x_mv_per_g = zeros(n_hyp,1);
sens_y_mv_per_g = zeros(n_hyp,1);
sens_z_mv_per_g = zeros(n_hyp,1);
invalid_sensitivity_count = zeros(n_hyp,1);
overall_mean_abs_gnorm_err = zeros(n_hyp,1);
overall_max_abs_gnorm_err = zeros(n_hyp,1);
total_seq_jumps = zeros(n_hyp,1);
pose_axis_match_count = zeros(n_hyp,1);
pose_sign_match_count = zeros(n_hyp,1);
exact_pose_match_count = zeros(n_hyp,1);
average_expected_axis_strength = zeros(n_hyp,1);
average_cross_axis_abs = zeros(n_hyp,1);
score_global = zeros(n_hyp,1);

h_idx = 0;
for p_idx = 1:size(perm_all,1)
    perm_vec = perm_all(p_idx,:);
    for s_idx = 1:size(sign_all,1)
        h_idx = h_idx + 1;
        sign_vec = sign_all(s_idx,:);

        [summary_row, ~, ~] = evaluate_hypothesis(run_base_tbl, expected_pose_order, perm_vec, sign_vec);

        hypothesis_id(h_idx) = h_idx;
        perm_index(h_idx) = p_idx;
        sign_index(h_idx) = s_idx;
        phys_x_source(h_idx) = channel_labels(perm_vec(1));
        phys_y_source(h_idx) = channel_labels(perm_vec(2));
        phys_z_source(h_idx) = channel_labels(perm_vec(3));
        sign_x(h_idx) = sign_vec(1);
        sign_y(h_idx) = sign_vec(2);
        sign_z(h_idx) = sign_vec(3);
        mapping_label(h_idx) = compose_mapping_label(channel_labels, perm_vec);
        sign_label(h_idx) = compose_sign_label(sign_vec);
        offset_x_mv(h_idx) = summary_row.offset_mv(1);
        offset_y_mv(h_idx) = summary_row.offset_mv(2);
        offset_z_mv(h_idx) = summary_row.offset_mv(3);
        sens_x_mv_per_g(h_idx) = summary_row.sens_mv(1);
        sens_y_mv_per_g(h_idx) = summary_row.sens_mv(2);
        sens_z_mv_per_g(h_idx) = summary_row.sens_mv(3);
        invalid_sensitivity_count(h_idx) = summary_row.invalid_sensitivity_count;
        overall_mean_abs_gnorm_err(h_idx) = summary_row.overall_mean_abs_gnorm_err;
        overall_max_abs_gnorm_err(h_idx) = summary_row.overall_max_abs_gnorm_err;
        total_seq_jumps(h_idx) = summary_row.total_seq_jumps;
        pose_axis_match_count(h_idx) = summary_row.pose_axis_match_count;
        pose_sign_match_count(h_idx) = summary_row.pose_sign_match_count;
        exact_pose_match_count(h_idx) = summary_row.exact_pose_match_count;
        average_expected_axis_strength(h_idx) = summary_row.average_expected_axis_strength;
        average_cross_axis_abs(h_idx) = summary_row.average_cross_axis_abs;
        score_global(h_idx) = summary_row.score_global;
    end
end

hyp_tbl = table( ...
    hypothesis_id, perm_index, sign_index, ...
    phys_x_source, phys_y_source, phys_z_source, ...
    sign_x, sign_y, sign_z, mapping_label, sign_label, ...
    offset_x_mv, offset_y_mv, offset_z_mv, ...
    sens_x_mv_per_g, sens_y_mv_per_g, sens_z_mv_per_g, ...
    invalid_sensitivity_count, overall_mean_abs_gnorm_err, overall_max_abs_gnorm_err, total_seq_jumps, ...
    pose_axis_match_count, pose_sign_match_count, exact_pose_match_count, ...
    average_expected_axis_strength, average_cross_axis_abs, score_global);

hyp_tbl = sortrows(hyp_tbl, ...
    {'score_global','overall_mean_abs_gnorm_err','average_cross_axis_abs','exact_pose_match_count','pose_axis_match_count'}, ...
    {'descend','ascend','ascend','descend','descend'});

top_k = min(top_n, height(hyp_tbl));
top_tbl = hyp_tbl(1:top_k, :);
best_h = hyp_tbl(1,:);

best_perm = [find(channel_labels == best_h.phys_x_source, 1), ...
             find(channel_labels == best_h.phys_y_source, 1), ...
             find(channel_labels == best_h.phys_z_source, 1)];
best_sign = [best_h.sign_x, best_h.sign_y, best_h.sign_z];

[best_summary, best_runs_tbl, best_pose_tbl] = evaluate_hypothesis(run_base_tbl, expected_pose_order, best_perm, best_sign);

if height(hyp_tbl) > 1
    second_score = hyp_tbl.score_global(2);
else
    second_score = NaN;
end
score_gap = best_h.score_global - second_score;
score_gap_rel = score_gap / max(abs(second_score), eps);

quality_strong = ...
    best_h.total_seq_jumps == 0 && ...
    best_h.exact_pose_match_count >= 5 && ...
    best_h.pose_axis_match_count >= 5 && ...
    best_h.overall_mean_abs_gnorm_err <= 0.35 && ...
    best_h.average_expected_axis_strength >= 0.70 && ...
    best_h.average_cross_axis_abs <= 0.35;

quality_weak = ...
    best_h.total_seq_jumps == 0 && ...
    best_h.exact_pose_match_count >= 4 && ...
    best_h.pose_axis_match_count >= 4 && ...
    best_h.overall_mean_abs_gnorm_err <= 0.60 && ...
    best_h.average_expected_axis_strength >= 0.45 && ...
    best_h.average_cross_axis_abs <= 0.60;

if quality_strong && score_gap >= 8 && score_gap_rel >= 0.08
    final_decision = "mapping_identified_strong";
elseif best_h.exact_pose_match_count <= 2 && best_h.overall_mean_abs_gnorm_err >= 0.75
    final_decision = "mapping_not_supported";
elseif quality_weak && score_gap >= 3
    final_decision = "mapping_identified_but_weak";
else
    final_decision = "mapping_ambiguous";
end

%% Guardado de artefactos
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
base = "sensor_C_axis_mapping_search_" + stamp;
hyp_csv_out = fullfile(analysis_out_dir, char(base + "_hypotheses.csv"));
top_csv_out = fullfile(analysis_out_dir, char(base + "_top10.csv"));
best_runs_csv_out = fullfile(analysis_out_dir, char(base + "_best_runs.csv"));
best_poses_csv_out = fullfile(analysis_out_dir, char(base + "_best_poses.csv"));
txt_out = fullfile(analysis_out_dir, char(base + ".txt"));

writetable(hyp_tbl, hyp_csv_out);
writetable(top_tbl, top_csv_out);
writetable(best_runs_tbl, best_runs_csv_out);
writetable(best_pose_tbl, best_poses_csv_out);

fid = fopen(txt_out, "w");
if fid < 0
    error("No fue posible crear resumen de busqueda: %s", txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/analysis/search_sensorC_axis_mapping_hypotheses.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "dataset_manifest: %s\n", manifest_relpath);
fprintf(fid, "hypothesis_count: %d\n", n_hyp);
fprintf(fid, "search_space: 6 permutations x 8 sign combinations\n");
fprintf(fid, "score_formula: score=100*(0.23*norm_mean + 0.10*norm_max + 0.15*expected_axis_strength + 0.10*cross_axis_term + 0.14*axis_match + 0.10*sign_match + 0.10*exact_match + 0.04*seq_term + 0.04*sens_term)\n");
fprintf(fid, "metrics_terms: norm_mean=1/(1+overall_mean_abs_gnorm_err), norm_max=1/(1+overall_max_abs_gnorm_err), expected_axis_strength=clamp((avg_expected_axis_strength+1)/2,0,1), cross_axis_term=1/(1+avg_cross_axis_abs), axis_match=pose_axis_match_count/6, sign_match=pose_sign_match_count/6, exact_match=exact_pose_match_count/6, seq_term=1/(1+total_seq_jumps), sens_term=1/(1+invalid_sensitivity_count)\n");
fprintf(fid, "hypothesis_csv: %s\n", make_relpath(hyp_csv_out, repo_dir));
fprintf(fid, "top10_csv: %s\n", make_relpath(top_csv_out, repo_dir));
fprintf(fid, "best_runs_csv: %s\n", make_relpath(best_runs_csv_out, repo_dir));
fprintf(fid, "best_poses_csv: %s\n", make_relpath(best_poses_csv_out, repo_dir));
fprintf(fid, "best_hypothesis_id: %d\n", best_h.hypothesis_id);
fprintf(fid, "best_mapping: %s\n", best_h.mapping_label);
fprintf(fid, "best_signs: %s\n", best_h.sign_label);
fprintf(fid, "best_score: %.6f\n", best_h.score_global);
fprintf(fid, "best_overall_mean_abs_gnorm_err: %.9f\n", best_h.overall_mean_abs_gnorm_err);
fprintf(fid, "best_overall_max_abs_gnorm_err: %.9f\n", best_h.overall_max_abs_gnorm_err);
fprintf(fid, "best_pose_axis_match_count: %d\n", best_h.pose_axis_match_count);
fprintf(fid, "best_pose_sign_match_count: %d\n", best_h.pose_sign_match_count);
fprintf(fid, "best_exact_pose_match_count: %d\n", best_h.exact_pose_match_count);
fprintf(fid, "best_average_expected_axis_strength: %.9f\n", best_h.average_expected_axis_strength);
fprintf(fid, "best_average_cross_axis_abs: %.9f\n", best_h.average_cross_axis_abs);
fprintf(fid, "best_total_seq_jumps: %d\n", best_h.total_seq_jumps);
fprintf(fid, "second_best_score: %.6f\n", second_score);
fprintf(fid, "score_gap: %.6f\n", score_gap);
fprintf(fid, "score_gap_relative: %.6f\n", score_gap_rel);
fprintf(fid, "quality_strong: %s\n", string(quality_strong));
fprintf(fid, "quality_weak: %s\n", string(quality_weak));
fprintf(fid, "final_decision: %s\n", final_decision);

%% Salida por consola
fprintf("\nAXIS_MAPPING_SEARCH_OK\n");
fprintf("DATASET_MANIFEST: %s\n", manifest_relpath);
fprintf("HYPOTHESIS_COUNT: %d\n", n_hyp);
fprintf("HYPOTHESIS_CSV: %s\n", make_relpath(hyp_csv_out, repo_dir));
fprintf("TOP10_CSV: %s\n", make_relpath(top_csv_out, repo_dir));
fprintf("BEST_RUNS_CSV: %s\n", make_relpath(best_runs_csv_out, repo_dir));
fprintf("BEST_POSES_CSV: %s\n", make_relpath(best_poses_csv_out, repo_dir));
fprintf("SUMMARY_TXT: %s\n", make_relpath(txt_out, repo_dir));
fprintf("BEST_HYPOTHESIS_ID: %d\n", best_h.hypothesis_id);
fprintf("BEST_MAPPING: %s\n", best_h.mapping_label);
fprintf("BEST_SIGNS: %s\n", best_h.sign_label);
fprintf("BEST_SCORE: %.6f\n", best_h.score_global);
fprintf("FINAL_DECISION: %s\n", final_decision);

%% Funciones locales
function [manifest_abs, manifest_relpath, manifest_tbl] = resolve_manifest(repo_dir, analysis_out_dir, sensor_id, dataset_manifest_relpath)
if strlength(dataset_manifest_relpath) > 0
    manifest_abs = fullfile(repo_dir, char(dataset_manifest_relpath));
    if ~isfile(manifest_abs)
        error("Manifest explicitado no existe: %s", manifest_abs);
    end
else
    search_pattern = char(sensor_id + "_axis_mapping_search_dataset_*.csv");
    list_search = dir(fullfile(analysis_out_dir, search_pattern));
    if ~isempty(list_search)
        [~, idx] = sort([list_search.datenum], "ascend");
        list_search = list_search(idx);
        manifest_abs = fullfile(list_search(end).folder, list_search(end).name);
    else
        fallback = fullfile(analysis_out_dir, char(sensor_id + "_axis_convention_dataset_phase104.csv"));
        if ~isfile(fallback)
            error("No se encontro manifest de esta fase ni fallback phase104 para %s.", sensor_id);
        end
        manifest_abs = fallback;
    end
end

manifest_relpath = string(make_relpath(manifest_abs, repo_dir));
manifest_tbl = readtable(manifest_abs, "Delimiter", ",", "TextType", "string");
end

function [summary_row, run_eval_tbl, pose_eval_tbl] = evaluate_hypothesis(run_base_tbl, expected_pose_order, perm_vec, sign_vec)
v_measured = [run_base_tbl.mean_mv_x, run_base_tbl.mean_mv_y, run_base_tbl.mean_mv_z];
v_phys = v_measured(:, perm_vec) .* sign_vec;

axis_labels = ["x","y","z"];
offset_mv = zeros(1,3);
sens_mv = zeros(1,3);
invalid_sensitivity_count = 0;

for a = 1:3
    ax = axis_labels(a);
    pos_id = run_base_tbl.pose == ("pos_" + ax);
    neg_id = run_base_tbl.pose == ("neg_" + ax);
    if ~any(pos_id) || ~any(neg_id)
        error("Hipotesis invalida: faltan poses pos/neg para eje %s.", ax);
    end
    pos_mean = mean(v_phys(pos_id, a));
    neg_mean = mean(v_phys(neg_id, a));
    offset_mv(a) = (pos_mean + neg_mean) / 2;
    sens_mv(a) = (pos_mean - neg_mean) / 2;
    if abs(sens_mv(a)) < 1e-9
        invalid_sensitivity_count = invalid_sensitivity_count + 1;
        if sens_mv(a) == 0
            sens_mv(a) = 1e-9;
        else
            sens_mv(a) = sign(sens_mv(a)) * 1e-9;
        end
    end
end

g_est = (v_phys - offset_mv) ./ sens_mv;
g_norm = sqrt(sum(g_est.^2, 2));
g_abs_norm_err = abs(g_norm - 1.0);

n_runs = height(run_base_tbl);
expected_axis_idx = zeros(n_runs,1);
expected_axis_mean = zeros(n_runs,1);
cross_axis_abs_mean = zeros(n_runs,1);
dominant_axis = strings(n_runs,1);
dominant_sign = zeros(n_runs,1);
axis_match_run = false(n_runs,1);
sign_match_run = false(n_runs,1);
exact_match_run = false(n_runs,1);

for i = 1:n_runs
    [ax_idx, exp_sign] = expected_axis_idx_sign(run_base_tbl.pose(i));
    expected_axis_idx(i) = ax_idx;
    expected_axis_mean(i) = g_est(i, ax_idx) * exp_sign;
    other_idx = setdiff(1:3, ax_idx);
    cross_axis_abs_mean(i) = mean(abs(g_est(i, other_idx)));

    [~, dom_idx] = max(abs(g_est(i,:)));
    dominant_axis(i) = axis_labels(dom_idx);
    dominant_sign(i) = sign(g_est(i, dom_idx));
    axis_match_run(i) = dom_idx == ax_idx;
    sign_match_run(i) = sign(g_est(i, ax_idx)) == exp_sign;
    exact_match_run(i) = axis_match_run(i) && sign_match_run(i);
end

mean_gx = g_est(:,1);
mean_gy = g_est(:,2);
mean_gz = g_est(:,3);

run_eval_tbl = table( ...
    run_base_tbl.pose, run_base_tbl.run_file, run_base_tbl.samples, run_base_tbl.duration_s, ...
    run_base_tbl.freq_hz, run_base_tbl.seq_jumps, ...
    mean_gx, mean_gy, mean_gz, g_norm, g_abs_norm_err, ...
    expected_axis_mean, cross_axis_abs_mean, dominant_axis, dominant_sign, ...
    axis_match_run, sign_match_run, exact_match_run, ...
    'VariableNames', {'pose','run_file','samples','duration_s','freq_hz','seq_jumps', ...
    'mean_gx','mean_gy','mean_gz','mean_gnorm','mean_abs_gnorm_err', ...
    'expected_axis_mean','cross_axis_abs_mean','dominant_axis','dominant_sign', ...
    'axis_match','sign_match','exact_match'});

pose_name = expected_pose_order(:);
n_poses = numel(expected_pose_order);
runs_found = zeros(n_poses,1);
seq_jumps_total = zeros(n_poses,1);
freq_mean_hz = zeros(n_poses,1);
pose_mean_gx = zeros(n_poses,1);
pose_mean_gy = zeros(n_poses,1);
pose_mean_gz = zeros(n_poses,1);
pose_mean_gnorm = zeros(n_poses,1);
pose_mean_abs_gnorm_err = zeros(n_poses,1);
pose_max_abs_gnorm_err = zeros(n_poses,1);
pose_mean_expected_axis = zeros(n_poses,1);
pose_mean_cross_axis_abs = zeros(n_poses,1);
pose_axis_match = false(n_poses,1);
pose_sign_match = false(n_poses,1);
pose_exact_match = false(n_poses,1);
pose_dominant_axis = strings(n_poses,1);
pose_dominant_sign = zeros(n_poses,1);

for p = 1:n_poses
    pose_key = expected_pose_order(p);
    idx = run_eval_tbl.pose == pose_key;
    if ~any(idx)
        error("Hipotesis evaluada sin corridas para pose %s.", pose_key);
    end
    subset = run_eval_tbl(idx, :);

    runs_found(p) = height(subset);
    seq_jumps_total(p) = sum(subset.seq_jumps);
    freq_mean_hz(p) = mean(subset.freq_hz);
    pose_mean_gx(p) = mean(subset.mean_gx);
    pose_mean_gy(p) = mean(subset.mean_gy);
    pose_mean_gz(p) = mean(subset.mean_gz);
    pose_mean_gnorm(p) = mean(subset.mean_gnorm);
    pose_mean_abs_gnorm_err(p) = mean(subset.mean_abs_gnorm_err);
    pose_max_abs_gnorm_err(p) = max(subset.mean_abs_gnorm_err);
    pose_mean_expected_axis(p) = mean(subset.expected_axis_mean);
    pose_mean_cross_axis_abs(p) = mean(subset.cross_axis_abs_mean);

    [exp_axis_idx, exp_sign] = expected_axis_idx_sign(pose_key);
    g_pose = [pose_mean_gx(p), pose_mean_gy(p), pose_mean_gz(p)];
    [~, dom_idx] = max(abs(g_pose));
    pose_dominant_axis(p) = axis_labels(dom_idx);
    pose_dominant_sign(p) = sign(g_pose(dom_idx));
    pose_axis_match(p) = dom_idx == exp_axis_idx;
    pose_sign_match(p) = sign(g_pose(exp_axis_idx)) == exp_sign;
    pose_exact_match(p) = pose_axis_match(p) && pose_sign_match(p);
end

pose_eval_tbl = table( ...
    pose_name, runs_found, seq_jumps_total, freq_mean_hz, ...
    pose_mean_gx, pose_mean_gy, pose_mean_gz, pose_mean_gnorm, ...
    pose_mean_abs_gnorm_err, pose_max_abs_gnorm_err, ...
    pose_mean_expected_axis, pose_mean_cross_axis_abs, ...
    pose_dominant_axis, pose_dominant_sign, ...
    pose_axis_match, pose_sign_match, pose_exact_match, ...
    'VariableNames', {'pose','runs_found','seq_jumps_total','freq_mean_hz', ...
    'mean_gx','mean_gy','mean_gz','mean_gnorm', ...
    'mean_abs_gnorm_err','max_abs_gnorm_err', ...
    'mean_expected_axis','mean_cross_axis_abs', ...
    'dominant_axis','dominant_sign','axis_match','sign_match','exact_match'});

overall_mean_abs_gnorm_err = mean(run_eval_tbl.mean_abs_gnorm_err);
overall_max_abs_gnorm_err = max(run_eval_tbl.mean_abs_gnorm_err);
total_seq_jumps = sum(run_eval_tbl.seq_jumps);
pose_axis_match_count = sum(pose_eval_tbl.axis_match);
pose_sign_match_count = sum(pose_eval_tbl.sign_match);
exact_pose_match_count = sum(pose_eval_tbl.exact_match);
average_expected_axis_strength = mean(run_eval_tbl.expected_axis_mean);
average_cross_axis_abs = mean(run_eval_tbl.cross_axis_abs_mean);

norm_mean_term = 1 / (1 + overall_mean_abs_gnorm_err);
norm_max_term = 1 / (1 + overall_max_abs_gnorm_err);
expected_term = max(0, min(1, (average_expected_axis_strength + 1) / 2));
cross_term = 1 / (1 + average_cross_axis_abs);
axis_match_term = pose_axis_match_count / n_poses;
sign_match_term = pose_sign_match_count / n_poses;
exact_match_term = exact_pose_match_count / n_poses;
seq_term = 1 / (1 + total_seq_jumps);
sens_term = 1 / (1 + invalid_sensitivity_count);

score_global = 100 * ( ...
    0.23 * norm_mean_term + ...
    0.10 * norm_max_term + ...
    0.15 * expected_term + ...
    0.10 * cross_term + ...
    0.14 * axis_match_term + ...
    0.10 * sign_match_term + ...
    0.10 * exact_match_term + ...
    0.04 * seq_term + ...
    0.04 * sens_term);

summary_row = struct();
summary_row.offset_mv = offset_mv;
summary_row.sens_mv = sens_mv;
summary_row.invalid_sensitivity_count = invalid_sensitivity_count;
summary_row.overall_mean_abs_gnorm_err = overall_mean_abs_gnorm_err;
summary_row.overall_max_abs_gnorm_err = overall_max_abs_gnorm_err;
summary_row.total_seq_jumps = total_seq_jumps;
summary_row.pose_axis_match_count = pose_axis_match_count;
summary_row.pose_sign_match_count = pose_sign_match_count;
summary_row.exact_pose_match_count = exact_pose_match_count;
summary_row.average_expected_axis_strength = average_expected_axis_strength;
summary_row.average_cross_axis_abs = average_cross_axis_abs;
summary_row.score_global = score_global;
end

function label = compose_mapping_label(channel_labels, perm_vec)
label = "phys_x<=mv_" + channel_labels(perm_vec(1)) + ...
    ",phys_y<=mv_" + channel_labels(perm_vec(2)) + ...
    ",phys_z<=mv_" + channel_labels(perm_vec(3));
end

function label = compose_sign_label(sign_vec)
label = sprintf("[%+d,%+d,%+d]", sign_vec(1), sign_vec(2), sign_vec(3));
label = string(label);
end

function [axis_idx, sign_val] = expected_axis_idx_sign(pose_name)
[axis_name, sign_val] = expected_from_pose(pose_name);
switch axis_name
    case "x"
        axis_idx = 1;
    case "y"
        axis_idx = 2;
    case "z"
        axis_idx = 3;
    otherwise
        error("Eje no soportado en pose: %s", pose_name);
end
end

function [axis_name, sign_val] = expected_from_pose(pose_name)
if startsWith(pose_name, "pos_")
    sign_val = 1;
elseif startsWith(pose_name, "neg_")
    sign_val = -1;
else
    error("Pose no reconocida: %s", pose_name);
end

axis_name = extractAfter(pose_name, 4);
if ~ismember(axis_name, ["x","y","z"])
    error("Pose con eje no soportado: %s", pose_name);
end
end

function rel = make_relpath(abs_path, repo_dir)
rel = strrep(abs_path, [repo_dir filesep], "");
end
