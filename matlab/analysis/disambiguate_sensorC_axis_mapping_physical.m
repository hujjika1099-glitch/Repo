
% disambiguate_sensorC_axis_mapping_physical.m
% Desambiguacion fisica de hipotesis de mapeo/signo para sensor_C usando
% solo datasets existentes (sin nuevas capturas, sin recalibrar firmware).

%% Configuracion
default_sensor_id = "sensor_C";
default_dataset_manifest_relpath = "reports/analysis_outputs/sensor_C_axis_mapping_search_dataset_20260322_121904.csv";
default_dataset_manifest_fallback = "reports/analysis_outputs/sensor_C_axis_convention_dataset_phase104.csv";
default_expected_pose_order = ["pos_x","neg_x","pos_y","neg_y","pos_z","neg_z"];
default_top_n = 10;
default_family_tie_eps = 0.50;
default_null_iterations = 400;
default_raw_pair_delta_min_mv = 20;
default_pair_sign_threshold_g = 0.35;

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
    top_n = max(1, round(double(top_n)));
else
    top_n = default_top_n;
end

if exist("null_iterations", "var") && ~isempty(null_iterations)
    null_iterations = max(50, round(double(null_iterations)));
else
    null_iterations = default_null_iterations;
end

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
raw_dir = fullfile(repo_dir, "data", "raw", char(sensor_id));
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
if ~isfolder(analysis_out_dir)
    mkdir(analysis_out_dir);
end

%% Manifest de dataset
[manifest_abs, manifest_relpath, manifest_tbl] = resolve_manifest( ...
    repo_dir, dataset_manifest_relpath, default_dataset_manifest_fallback);

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
        error("Manifest incompleto, falta pose: %s", p);
    end
end

%% Metricas base por corrida
expected_cols = {'seq','t_us','raw_x','raw_y','raw_z','mv_x','mv_y','mv_z'};
n_runs = height(manifest_tbl);

run_pose = strings(n_runs,1);
run_file = strings(n_runs,1);
samples = zeros(n_runs,1);
duration_s = zeros(n_runs,1);
freq_hz = zeros(n_runs,1);
seq_jumps = zeros(n_runs,1);
mean_mv_x = zeros(n_runs,1);
mean_mv_y = zeros(n_runs,1);
mean_mv_z = zeros(n_runs,1);
expected_axis = strings(n_runs,1);
expected_sign = zeros(n_runs,1);

for i = 1:n_runs
    pose_name = string(manifest_tbl.pose(i));
    file_name = string(manifest_tbl.run_file(i));
    csv_abs = fullfile(raw_dir, char(file_name));
    if ~isfile(csv_abs)
        error("CSV listado no existe: %s", csv_abs);
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

    run_pose(i) = pose_name;
    run_file(i) = file_name;
    samples(i) = n;
    duration_s(i) = (t_us(end) - t_us(1)) / 1e6;
    freq_hz(i) = (n - 1) / max(duration_s(i), eps);
    seq_jumps(i) = nnz(diff(seq_col) ~= 1);
    mean_mv_x(i) = mean(double(tbl.mv_x));
    mean_mv_y(i) = mean(double(tbl.mv_y));
    mean_mv_z(i) = mean(double(tbl.mv_z));
    expected_axis(i) = exp_axis;
    expected_sign(i) = exp_sign;
end

run_base_tbl = table( ...
    run_pose, run_file, samples, duration_s, freq_hz, seq_jumps, ...
    mean_mv_x, mean_mv_y, mean_mv_z, expected_axis, expected_sign, ...
    'VariableNames', {'pose','run_file','samples','duration_s','freq_hz','seq_jumps', ...
    'mean_mv_x','mean_mv_y','mean_mv_z','expected_axis','expected_sign'});

%% Espacio de hipotesis (48)
channel_labels = ["x","y","z"];
perm_all = perms(1:3);  % 6 permutaciones
[sx, sy, sz] = ndgrid([-1 1], [-1 1], [-1 1]);
sign_all = [sx(:), sy(:), sz(:)]; % 8 signos

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

overall_mean_abs_gnorm_err = zeros(n_hyp,1);
overall_max_abs_gnorm_err = zeros(n_hyp,1);
total_seq_jumps = zeros(n_hyp,1);
pose_axis_match_count = zeros(n_hyp,1);
pose_sign_match_count = zeros(n_hyp,1);
exact_pose_match_count = zeros(n_hyp,1);
pair_axis_match_count = zeros(n_hyp,1);
pair_sign_opposition_count = zeros(n_hyp,1);
average_expected_axis_strength = zeros(n_hyp,1);
average_cross_axis_abs = zeros(n_hyp,1);
average_pair_dominance_ratio = zeros(n_hyp,1);
worst_pair_dominance_ratio = zeros(n_hyp,1);
raw_pair_sign_ok_count = zeros(n_hyp,1);
average_raw_pair_dominance_ratio = zeros(n_hyp,1);
invalid_sensitivity_count = zeros(n_hyp,1);
base_score = zeros(n_hyp,1);
permutation_family_rank_metric = zeros(n_hyp,1);
score_global = zeros(n_hyp,1);

h_idx = 0;
for p = 1:size(perm_all,1)
    perm_vec = perm_all(p,:);
    for s = 1:size(sign_all,1)
        h_idx = h_idx + 1;
        sign_vec = sign_all(s,:);

        [summary, ~, ~] = evaluate_hypothesis_physical( ...
            run_base_tbl, expected_pose_order, perm_vec, sign_vec, ...
            default_raw_pair_delta_min_mv, default_pair_sign_threshold_g);

        hypothesis_id(h_idx) = h_idx;
        perm_index(h_idx) = p;
        sign_index(h_idx) = s;
        phys_x_source(h_idx) = channel_labels(perm_vec(1));
        phys_y_source(h_idx) = channel_labels(perm_vec(2));
        phys_z_source(h_idx) = channel_labels(perm_vec(3));
        sign_x(h_idx) = sign_vec(1);
        sign_y(h_idx) = sign_vec(2);
        sign_z(h_idx) = sign_vec(3);
        mapping_label(h_idx) = compose_mapping_label(channel_labels, perm_vec);
        sign_label(h_idx) = compose_sign_label(sign_vec);

        overall_mean_abs_gnorm_err(h_idx) = summary.overall_mean_abs_gnorm_err;
        overall_max_abs_gnorm_err(h_idx) = summary.overall_max_abs_gnorm_err;
        total_seq_jumps(h_idx) = summary.total_seq_jumps;
        pose_axis_match_count(h_idx) = summary.pose_axis_match_count;
        pose_sign_match_count(h_idx) = summary.pose_sign_match_count;
        exact_pose_match_count(h_idx) = summary.exact_pose_match_count;
        pair_axis_match_count(h_idx) = summary.pair_axis_match_count;
        pair_sign_opposition_count(h_idx) = summary.pair_sign_opposition_count;
        average_expected_axis_strength(h_idx) = summary.average_expected_axis_strength;
        average_cross_axis_abs(h_idx) = summary.average_cross_axis_abs;
        average_pair_dominance_ratio(h_idx) = summary.average_pair_dominance_ratio;
        worst_pair_dominance_ratio(h_idx) = summary.worst_pair_dominance_ratio;
        raw_pair_sign_ok_count(h_idx) = summary.raw_pair_sign_ok_count;
        average_raw_pair_dominance_ratio(h_idx) = summary.average_raw_pair_dominance_ratio;
        invalid_sensitivity_count(h_idx) = summary.invalid_sensitivity_count;
        base_score(h_idx) = summary.base_score;
    end
end

hyp_tbl = table( ...
    hypothesis_id, perm_index, sign_index, ...
    phys_x_source, phys_y_source, phys_z_source, ...
    sign_x, sign_y, sign_z, mapping_label, sign_label, ...
    overall_mean_abs_gnorm_err, overall_max_abs_gnorm_err, total_seq_jumps, ...
    pose_axis_match_count, pose_sign_match_count, exact_pose_match_count, ...
    pair_axis_match_count, pair_sign_opposition_count, ...
    average_expected_axis_strength, average_cross_axis_abs, ...
    average_pair_dominance_ratio, worst_pair_dominance_ratio, ...
    raw_pair_sign_ok_count, average_raw_pair_dominance_ratio, ...
    invalid_sensitivity_count, base_score, permutation_family_rank_metric, score_global);

%% Resumen por familia de permutacion (colapsa 8 variantes de signo)
family_tbl = build_family_table(hyp_tbl, default_family_tie_eps);

% Asignar metricas de familia a cada hipotesis y recalcular score_global
for i = 1:height(hyp_tbl)
    p = hyp_tbl.perm_index(i);
    fid = family_tbl.perm_index == p;
    rank_metric = family_tbl.family_rank_metric(fid);
    gap_bonus = family_tbl.family_gap_bonus(fid);
    tie_penalty = family_tbl.family_tie_penalty(fid);
    hyp_tbl.permutation_family_rank_metric(i) = 0.50 * rank_metric + 0.30 * gap_bonus + 0.20 * (1 - tie_penalty);
    hyp_tbl.score_global(i) = hyp_tbl.base_score(i) + ...
        (6.0 * rank_metric) + ...
        (3.0 * gap_bonus) - ...
        (4.0 * tie_penalty);
end

% Actualizar tabla de familia con score_global
family_tbl = refresh_family_with_global_scores(hyp_tbl, family_tbl, default_family_tie_eps);

% Ranking final de hipotesis
hyp_tbl = sortrows(hyp_tbl, ...
    {'score_global','base_score','average_pair_dominance_ratio','pair_axis_match_count','exact_pose_match_count','overall_mean_abs_gnorm_err'}, ...
    {'descend','descend','descend','descend','descend','ascend'});

top_k = min(top_n, height(hyp_tbl));
top_tbl = hyp_tbl(1:top_k,:);
best_h = hyp_tbl(1,:);
if height(hyp_tbl) > 1
    second_h = hyp_tbl(2,:);
else
    second_h = hyp_tbl(1,:);
end
score_gap = best_h.score_global - second_h.score_global;

% Mejor familia final
family_tbl = sortrows(family_tbl, {'family_best_score','family_best_base_score','family_rank_metric'}, {'descend','descend','descend'});
best_family = family_tbl(1,:);
if height(family_tbl) > 1
    second_family = family_tbl(2,:);
else
    second_family = family_tbl(1,:);
end
family_score_gap = best_family.family_best_score - second_family.family_best_score;

%% Detalle de mejor hipotesis
best_perm = [ ...
    find(channel_labels == best_h.phys_x_source, 1), ...
    find(channel_labels == best_h.phys_y_source, 1), ...
    find(channel_labels == best_h.phys_z_source, 1)];
best_sign = [best_h.sign_x, best_h.sign_y, best_h.sign_z];
[best_summary, best_pose_tbl, best_pair_tbl] = evaluate_hypothesis_physical( ...
    run_base_tbl, expected_pose_order, best_perm, best_sign, ...
    default_raw_pair_delta_min_mv, default_pair_sign_threshold_g);

%% Hipotesis nula (pose labels aleatorizados)
rng(104);
null_scores = zeros(null_iterations,1);
for i = 1:null_iterations
    ridx = randperm(height(run_base_tbl));
    shuffled_tbl = run_base_tbl;
    shuffled_tbl.pose = run_base_tbl.pose(ridx);
    shuffled_tbl.expected_axis = strings(height(shuffled_tbl),1);
    shuffled_tbl.expected_sign = zeros(height(shuffled_tbl),1);
    for k = 1:height(shuffled_tbl)
        [eaxis, esign] = expected_from_pose(shuffled_tbl.pose(k));
        shuffled_tbl.expected_axis(k) = eaxis;
        shuffled_tbl.expected_sign(k) = esign;
    end
    null_summary = evaluate_hypothesis_physical( ...
        shuffled_tbl, expected_pose_order, best_perm, best_sign, ...
        default_raw_pair_delta_min_mv, default_pair_sign_threshold_g);
    null_scores(i) = null_summary.base_score;
end

null_score_mean = mean(null_scores);
null_score_std = std(null_scores);
null_score_p95 = prctile(null_scores, 95);
null_score_max = max(null_scores);
best_vs_null_mean = best_h.base_score - null_score_mean;
best_vs_null_p95 = best_h.base_score - null_score_p95;

%% Decision final automatica
rule_identified_weak = ...
    best_vs_null_p95 >= 8.0 && ...
    score_gap >= 3.0 && ...
    family_score_gap >= 3.0 && ...
    best_h.pair_axis_match_count >= 2 && ...
    best_h.pair_sign_opposition_count >= 2 && ...
    best_h.average_pair_dominance_ratio >= 1.25 && ...
    best_h.worst_pair_dominance_ratio >= 1.10 && ...
    best_h.exact_pose_match_count >= 4 && ...
    best_family.family_tie_count_eps <= 2;

rule_not_supported = ...
    (best_vs_null_p95 <= 1.0) || ...
    (best_h.pair_axis_match_count <= 1) || ...
    (best_h.average_pair_dominance_ratio < 1.05) || ...
    (best_h.exact_pose_match_count <= 2) || ...
    (best_h.overall_mean_abs_gnorm_err > 1.50);

if rule_identified_weak
    final_decision = "mapping_identified_but_weak";
elseif rule_not_supported
    final_decision = "mapping_not_supported";
else
    final_decision = "mapping_ambiguous";
end

%% Salidas
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
base = "sensor_C_axis_mapping_disambiguation_" + stamp;
hyp_csv_out = fullfile(analysis_out_dir, char(base + "_hypotheses.csv"));
fam_csv_out = fullfile(analysis_out_dir, char(base + "_families.csv"));
top_csv_out = fullfile(analysis_out_dir, char(base + "_top10.csv"));
best_poses_csv_out = fullfile(analysis_out_dir, char(base + "_best_poses.csv"));
best_pairs_csv_out = fullfile(analysis_out_dir, char(base + "_best_pairs.csv"));
txt_out = fullfile(analysis_out_dir, char(base + ".txt"));

writetable(hyp_tbl, hyp_csv_out);
writetable(family_tbl, fam_csv_out);
writetable(top_tbl, top_csv_out);
writetable(best_pose_tbl, best_poses_csv_out);
writetable(best_pair_tbl, best_pairs_csv_out);

fid = fopen(txt_out, "w");
if fid < 0
    error("No fue posible escribir resumen: %s", txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/analysis/disambiguate_sensorC_axis_mapping_physical.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "dataset_manifest: %s\n", manifest_relpath);
fprintf(fid, "hypotheses_evaluated: %d\n", n_hyp);
fprintf(fid, "families_evaluated: %d\n", height(family_tbl));
fprintf(fid, "score_formula_base: base=100*(0.08*norm_mean + 0.05*norm_max + 0.10*pose_axis + 0.07*pose_exact + 0.14*pair_axis + 0.14*pair_sign + 0.11*pair_dom_avg + 0.10*pair_dom_worst + 0.07*expected_axis + 0.06*cross_axis + 0.05*raw_pair_sign + 0.02*raw_pair_dom + 0.01*seq_term)\n");
fprintf(fid, "score_formula_global: score_global=base + 6*family_rank_metric + 3*family_gap_bonus - 4*family_tie_penalty\n");
fprintf(fid, "null_reference: shuffled pose labels (%d iter), same best permutation/sign\n", null_iterations);
fprintf(fid, "hypotheses_csv: %s\n", make_relpath(hyp_csv_out, repo_dir));
fprintf(fid, "families_csv: %s\n", make_relpath(fam_csv_out, repo_dir));
fprintf(fid, "top10_csv: %s\n", make_relpath(top_csv_out, repo_dir));
fprintf(fid, "best_poses_csv: %s\n", make_relpath(best_poses_csv_out, repo_dir));
fprintf(fid, "best_pairs_csv: %s\n", make_relpath(best_pairs_csv_out, repo_dir));
fprintf(fid, "best_hypothesis_id: %d\n", best_h.hypothesis_id);
fprintf(fid, "best_permutation_family: %s\n", best_h.mapping_label);
fprintf(fid, "best_mapping: %s\n", best_h.mapping_label);
fprintf(fid, "best_signs: %s\n", best_h.sign_label);
fprintf(fid, "best_base_score: %.6f\n", best_h.base_score);
fprintf(fid, "best_score: %.6f\n", best_h.score_global);
fprintf(fid, "second_score: %.6f\n", second_h.score_global);
fprintf(fid, "score_gap: %.6f\n", score_gap);
fprintf(fid, "best_family_score: %.6f\n", best_family.family_best_score);
fprintf(fid, "second_family_score: %.6f\n", second_family.family_best_score);
fprintf(fid, "family_score_gap: %.6f\n", family_score_gap);
fprintf(fid, "null_score_mean: %.6f\n", null_score_mean);
fprintf(fid, "null_score_std: %.6f\n", null_score_std);
fprintf(fid, "null_score_p95: %.6f\n", null_score_p95);
fprintf(fid, "null_score_max: %.6f\n", null_score_max);
fprintf(fid, "best_vs_null_mean: %.6f\n", best_vs_null_mean);
fprintf(fid, "best_vs_null_p95: %.6f\n", best_vs_null_p95);
fprintf(fid, "rule_identified_weak: %s\n", string(rule_identified_weak));
fprintf(fid, "rule_not_supported: %s\n", string(rule_not_supported));
fprintf(fid, "final_decision: %s\n", final_decision);

%% Consola
fprintf("\nAXIS_MAPPING_DISAMBIGUATION_OK\n");
fprintf("DATASET_MANIFEST: %s\n", manifest_relpath);
fprintf("HYPOTHESES_EVALUATED: %d\n", n_hyp);
fprintf("FAMILIES_EVALUATED: %d\n", height(family_tbl));
fprintf("HYPOTHESES_CSV: %s\n", make_relpath(hyp_csv_out, repo_dir));
fprintf("FAMILIES_CSV: %s\n", make_relpath(fam_csv_out, repo_dir));
fprintf("TOP10_CSV: %s\n", make_relpath(top_csv_out, repo_dir));
fprintf("BEST_POSES_CSV: %s\n", make_relpath(best_poses_csv_out, repo_dir));
fprintf("BEST_PAIRS_CSV: %s\n", make_relpath(best_pairs_csv_out, repo_dir));
fprintf("SUMMARY_TXT: %s\n", make_relpath(txt_out, repo_dir));
fprintf("BEST_HYPOTHESIS_ID: %d\n", best_h.hypothesis_id);
fprintf("BEST_PERMUTATION_FAMILY: %s\n", best_h.mapping_label);
fprintf("BEST_MAPPING: %s\n", best_h.mapping_label);
fprintf("BEST_SIGNS: %s\n", best_h.sign_label);
fprintf("BEST_SCORE: %.6f\n", best_h.score_global);
fprintf("SCORE_GAP: %.6f\n", score_gap);
fprintf("FINAL_DECISION: %s\n", final_decision);

%% Funciones locales
function [summary, pose_tbl, pair_tbl] = evaluate_hypothesis_physical( ...
    run_base_tbl, expected_pose_order, perm_vec, sign_vec, raw_pair_delta_min_mv, pair_sign_threshold_g)

axis_labels = ["x","y","z"];
v_measured = [run_base_tbl.mean_mv_x, run_base_tbl.mean_mv_y, run_base_tbl.mean_mv_z];
v_phys = v_measured(:, perm_vec) .* sign_vec;

% Medias por pose en mV transformados
n_poses = numel(expected_pose_order);
pose_name = expected_pose_order(:);
runs_found = zeros(n_poses,1);
freq_mean_hz = zeros(n_poses,1);
seq_jumps_total = zeros(n_poses,1);
pose_mv_x_mean = zeros(n_poses,1);
pose_mv_y_mean = zeros(n_poses,1);
pose_mv_z_mean = zeros(n_poses,1);
pose_expected_axis = strings(n_poses,1);
pose_expected_sign = zeros(n_poses,1);

for p = 1:n_poses
    pose_key = expected_pose_order(p);
    idx = run_base_tbl.pose == pose_key;
    if ~any(idx)
        error("Sin corridas para pose %s.", pose_key);
    end
    [exp_axis, exp_sign] = expected_from_pose(pose_key);
    runs_found(p) = nnz(idx);
    freq_mean_hz(p) = mean(run_base_tbl.freq_hz(idx));
    seq_jumps_total(p) = sum(run_base_tbl.seq_jumps(idx));
    pose_mv_x_mean(p) = mean(v_phys(idx,1));
    pose_mv_y_mean(p) = mean(v_phys(idx,2));
    pose_mv_z_mean(p) = mean(v_phys(idx,3));
    pose_expected_axis(p) = exp_axis;
    pose_expected_sign(p) = exp_sign;
end

% Metricas crudas por par (antes de calibrar g)
pair_axis_name = ["x","y","z"]';
raw_pair_expected_delta_mv = zeros(3,1);
raw_pair_cross_delta_abs_max = zeros(3,1);
raw_pair_dominance_ratio = zeros(3,1);
raw_pair_sign_ok = false(3,1);

for a = 1:3
    ax = axis_labels(a);
    pos_idx = pose_name == ("pos_" + ax);
    neg_idx = pose_name == ("neg_" + ax);
    d = [
        pose_mv_x_mean(pos_idx) - pose_mv_x_mean(neg_idx), ...
        pose_mv_y_mean(pos_idx) - pose_mv_y_mean(neg_idx), ...
        pose_mv_z_mean(pos_idx) - pose_mv_z_mean(neg_idx)];
    raw_pair_expected_delta_mv(a) = d(a);
    raw_pair_cross_delta_abs_max(a) = max(abs(d(setdiff(1:3, a))));
    raw_pair_dominance_ratio(a) = abs(raw_pair_expected_delta_mv(a)) / max(raw_pair_cross_delta_abs_max(a), eps);
    raw_pair_sign_ok(a) = (raw_pair_expected_delta_mv(a) > 0) && (abs(raw_pair_expected_delta_mv(a)) >= raw_pair_delta_min_mv);
end

% Calibracion simple por eje sobre mV transformados
offset_mv = zeros(1,3);
sens_mv = zeros(1,3);
invalid_sensitivity_count = 0;
for a = 1:3
    ax = axis_labels(a);
    pos_idx = pose_name == ("pos_" + ax);
    neg_idx = pose_name == ("neg_" + ax);
    pos_vec = [pose_mv_x_mean(pos_idx), pose_mv_y_mean(pos_idx), pose_mv_z_mean(pos_idx)];
    neg_vec = [pose_mv_x_mean(neg_idx), pose_mv_y_mean(neg_idx), pose_mv_z_mean(neg_idx)];
    offset_mv(a) = (pos_vec(a) + neg_vec(a)) / 2;
    sens_mv(a) = (pos_vec(a) - neg_vec(a)) / 2;
    if abs(sens_mv(a)) < 1e-9
        invalid_sensitivity_count = invalid_sensitivity_count + 1;
        sens_mv(a) = sign(sens_mv(a) + eps) * 1e-9;
    end
end

% g estimado por corrida
g_est = (v_phys - offset_mv) ./ sens_mv;
g_norm = sqrt(sum(g_est.^2, 2));
g_norm_abs_err = abs(g_norm - 1.0);

expected_axis_mean_run = zeros(height(run_base_tbl),1);
cross_axis_abs_mean_run = zeros(height(run_base_tbl),1);

for i = 1:height(run_base_tbl)
    [exp_axis, exp_sign] = expected_from_pose(run_base_tbl.pose(i));
    exp_idx = axis_to_index(exp_axis);
    exp_val = g_est(i, exp_idx) * exp_sign;
    cross_val = mean(abs(g_est(i, setdiff(1:3, exp_idx))));
    expected_axis_mean_run(i) = exp_val;
    cross_axis_abs_mean_run(i) = cross_val;
end

% Resumen por pose en g
mean_gx = zeros(n_poses,1);
mean_gy = zeros(n_poses,1);
mean_gz = zeros(n_poses,1);
mean_gnorm = zeros(n_poses,1);
mean_abs_gnorm_err = zeros(n_poses,1);
max_abs_gnorm_err = zeros(n_poses,1);
mean_expected_axis = zeros(n_poses,1);
mean_cross_axis_abs = zeros(n_poses,1);
dominant_axis = strings(n_poses,1);
dominant_sign = zeros(n_poses,1);
axis_match = false(n_poses,1);
sign_match = false(n_poses,1);
exact_match = false(n_poses,1);

for p = 1:n_poses
    pose_key = expected_pose_order(p);
    idx = run_base_tbl.pose == pose_key;

    mean_gx(p) = mean(g_est(idx,1));
    mean_gy(p) = mean(g_est(idx,2));
    mean_gz(p) = mean(g_est(idx,3));
    mean_gnorm(p) = mean(g_norm(idx));
    mean_abs_gnorm_err(p) = mean(g_norm_abs_err(idx));
    max_abs_gnorm_err(p) = max(g_norm_abs_err(idx));
    mean_expected_axis(p) = mean(expected_axis_mean_run(idx));
    mean_cross_axis_abs(p) = mean(cross_axis_abs_mean_run(idx));

    g_pose = [mean_gx(p), mean_gy(p), mean_gz(p)];
    [~, d_idx] = max(abs(g_pose));
    dominant_axis(p) = axis_labels(d_idx);
    dominant_sign(p) = sign(g_pose(d_idx));

    exp_axis = pose_expected_axis(p);
    exp_sign = pose_expected_sign(p);
    exp_idx = axis_to_index(exp_axis);
    exp_val = g_pose(exp_idx);
    axis_match(p) = d_idx == exp_idx;
    sign_match(p) = (sign(exp_val) == exp_sign) && (abs(exp_val) >= 0.20);
    exact_match(p) = axis_match(p) && sign_match(p);
end

pose_tbl = table( ...
    pose_name, runs_found, seq_jumps_total, freq_mean_hz, ...
    mean_gx, mean_gy, mean_gz, mean_gnorm, mean_abs_gnorm_err, max_abs_gnorm_err, ...
    dominant_axis, dominant_sign, mean_expected_axis, mean_cross_axis_abs, ...
    axis_match, sign_match, exact_match, ...
    'VariableNames', {'pose','runs_found','seq_jumps_total','freq_mean_hz', ...
    'mean_gx','mean_gy','mean_gz','mean_gnorm','mean_abs_gnorm_err','max_abs_gnorm_err', ...
    'dominant_axis','dominant_sign','expected_axis_mean','cross_axis_abs_mean', ...
    'axis_match','sign_match','exact_match'});

% Resumen por par en g
pair_name = ["x_pair","y_pair","z_pair"]';
expected_pair_axis = axis_labels';
delta_gx_pair = zeros(3,1);
delta_gy_pair = zeros(3,1);
delta_gz_pair = zeros(3,1);
dominant_pair_axis = strings(3,1);
pair_axis_match = false(3,1);
pair_sign_opposition_ok = false(3,1);
pair_expected_delta_abs = zeros(3,1);
pair_cross_delta_abs_max = zeros(3,1);
pair_dominance_ratio = zeros(3,1);

for a = 1:3
    ax = axis_labels(a);
    pos_idx = pose_name == ("pos_" + ax);
    neg_idx = pose_name == ("neg_" + ax);

    g_pos = [mean_gx(pos_idx), mean_gy(pos_idx), mean_gz(pos_idx)];
    g_neg = [mean_gx(neg_idx), mean_gy(neg_idx), mean_gz(neg_idx)];
    d = g_pos - g_neg;

    delta_gx_pair(a) = d(1);
    delta_gy_pair(a) = d(2);
    delta_gz_pair(a) = d(3);

    [~, dom_idx] = max(abs(d));
    dominant_pair_axis(a) = axis_labels(dom_idx);
    pair_axis_match(a) = dom_idx == a;

    pos_val = g_pos(a);
    neg_val = g_neg(a);
    pair_sign_opposition_ok(a) = ...
        (pos_val >= pair_sign_threshold_g) && ...
        (neg_val <= -pair_sign_threshold_g);

    pair_expected_delta_abs(a) = abs(d(a));
    pair_cross_delta_abs_max(a) = max(abs(d(setdiff(1:3, a))));
    pair_dominance_ratio(a) = pair_expected_delta_abs(a) / max(pair_cross_delta_abs_max(a), eps);
end

pair_tbl = table( ...
    pair_name, expected_pair_axis, ...
    delta_gx_pair, delta_gy_pair, delta_gz_pair, ...
    dominant_pair_axis, pair_axis_match, pair_sign_opposition_ok, ...
    pair_expected_delta_abs, pair_cross_delta_abs_max, pair_dominance_ratio, ...
    raw_pair_expected_delta_mv, raw_pair_cross_delta_abs_max, raw_pair_dominance_ratio, raw_pair_sign_ok, ...
    'VariableNames', {'pair_name','expected_pair_axis', ...
    'delta_gx_pair','delta_gy_pair','delta_gz_pair', ...
    'dominant_pair_axis','pair_axis_match','pair_sign_opposition_ok', ...
    'pair_expected_delta_abs','pair_cross_delta_abs_max','pair_dominance_ratio', ...
    'raw_pair_expected_delta_mv','raw_pair_cross_delta_abs_max','raw_pair_dominance_ratio','raw_pair_sign_ok'});

% Globales
overall_mean_abs_gnorm_err = mean(g_norm_abs_err);
overall_max_abs_gnorm_err = max(g_norm_abs_err);
total_seq_jumps = sum(run_base_tbl.seq_jumps);
pose_axis_match_count = sum(pose_tbl.axis_match);
pose_sign_match_count = sum(pose_tbl.sign_match);
exact_pose_match_count = sum(pose_tbl.exact_match);
pair_axis_match_count = sum(pair_tbl.pair_axis_match);
pair_sign_opposition_count = sum(pair_tbl.pair_sign_opposition_ok);
average_expected_axis_strength = mean(pose_tbl.expected_axis_mean);
average_cross_axis_abs = mean(pose_tbl.cross_axis_abs_mean);
average_pair_dominance_ratio = mean(pair_tbl.pair_dominance_ratio);
worst_pair_dominance_ratio = min(pair_tbl.pair_dominance_ratio);
raw_pair_sign_ok_count = sum(pair_tbl.raw_pair_sign_ok);
average_raw_pair_dominance_ratio = mean(pair_tbl.raw_pair_dominance_ratio);

% Score base fisico reforzado (0..100 aprox)
t_norm_mean = 1 / (1 + overall_mean_abs_gnorm_err);
t_norm_max = 1 / (1 + overall_max_abs_gnorm_err);
t_pose_axis = pose_axis_match_count / 6;
t_pose_exact = exact_pose_match_count / 6;
t_pair_axis = pair_axis_match_count / 3;
t_pair_sign = pair_sign_opposition_count / 3;
t_pair_dom_avg = clamp((average_pair_dominance_ratio - 1.0) / 1.5, 0, 1);
t_pair_dom_worst = clamp((worst_pair_dominance_ratio - 1.0) / 1.2, 0, 1);
t_expected_axis = clamp((average_expected_axis_strength + 1.0) / 2.0, 0, 1);
t_cross_axis = 1 / (1 + average_cross_axis_abs);
t_raw_pair_sign = raw_pair_sign_ok_count / 3;
t_raw_pair_dom = clamp((average_raw_pair_dominance_ratio - 1.0) / 1.5, 0, 1);
t_seq = 1 / (1 + total_seq_jumps);

base_score = 100 * ( ...
    0.08 * t_norm_mean + ...
    0.05 * t_norm_max + ...
    0.10 * t_pose_axis + ...
    0.07 * t_pose_exact + ...
    0.14 * t_pair_axis + ...
    0.14 * t_pair_sign + ...
    0.11 * t_pair_dom_avg + ...
    0.10 * t_pair_dom_worst + ...
    0.07 * t_expected_axis + ...
    0.06 * t_cross_axis + ...
    0.05 * t_raw_pair_sign + ...
    0.02 * t_raw_pair_dom + ...
    0.01 * t_seq);

summary = struct();
summary.overall_mean_abs_gnorm_err = overall_mean_abs_gnorm_err;
summary.overall_max_abs_gnorm_err = overall_max_abs_gnorm_err;
summary.total_seq_jumps = total_seq_jumps;
summary.pose_axis_match_count = pose_axis_match_count;
summary.pose_sign_match_count = pose_sign_match_count;
summary.exact_pose_match_count = exact_pose_match_count;
summary.pair_axis_match_count = pair_axis_match_count;
summary.pair_sign_opposition_count = pair_sign_opposition_count;
summary.average_expected_axis_strength = average_expected_axis_strength;
summary.average_cross_axis_abs = average_cross_axis_abs;
summary.average_pair_dominance_ratio = average_pair_dominance_ratio;
summary.worst_pair_dominance_ratio = worst_pair_dominance_ratio;
summary.raw_pair_sign_ok_count = raw_pair_sign_ok_count;
summary.average_raw_pair_dominance_ratio = average_raw_pair_dominance_ratio;
summary.invalid_sensitivity_count = invalid_sensitivity_count;
summary.base_score = base_score;
end

function family_tbl = build_family_table(hyp_tbl, family_tie_eps)
perm_values = unique(hyp_tbl.perm_index);
n_fam = numel(perm_values);

perm_index = zeros(n_fam,1);
family_mapping_label = strings(n_fam,1);
family_best_hypothesis_id = zeros(n_fam,1);
family_best_sign_label = strings(n_fam,1);
family_best_base_score = zeros(n_fam,1);
family_second_best_base_score = zeros(n_fam,1);
family_base_score_gap = zeros(n_fam,1);
family_mean_base_score = zeros(n_fam,1);
family_std_base_score = zeros(n_fam,1);
family_tie_count_eps = zeros(n_fam,1);
family_rank_metric = zeros(n_fam,1);
family_gap_bonus = zeros(n_fam,1);
family_tie_penalty = zeros(n_fam,1);
family_best_score = zeros(n_fam,1);
family_second_best_score = zeros(n_fam,1);

for i = 1:n_fam
    p = perm_values(i);
    subset = hyp_tbl(hyp_tbl.perm_index == p, :);
    subset = sortrows(subset, {'base_score','pair_axis_match_count','exact_pose_match_count'}, {'descend','descend','descend'});

    perm_index(i) = p;
    family_mapping_label(i) = string(subset.mapping_label(1));
    family_best_hypothesis_id(i) = subset.hypothesis_id(1);
    family_best_sign_label(i) = string(subset.sign_label(1));
    family_best_base_score(i) = subset.base_score(1);
    if height(subset) > 1
        family_second_best_base_score(i) = subset.base_score(2);
    else
        family_second_best_base_score(i) = subset.base_score(1);
    end
    family_base_score_gap(i) = family_best_base_score(i) - family_second_best_base_score(i);
    family_mean_base_score(i) = mean(subset.base_score);
    family_std_base_score(i) = std(subset.base_score);
    family_tie_count_eps(i) = nnz((family_best_base_score(i) - subset.base_score) <= family_tie_eps);
end

tmp = table(perm_index, family_mapping_label, family_best_hypothesis_id, family_best_sign_label, ...
    family_best_base_score, family_second_best_base_score, family_base_score_gap, ...
    family_mean_base_score, family_std_base_score, family_tie_count_eps, ...
    family_rank_metric, family_gap_bonus, family_tie_penalty, family_best_score, family_second_best_score);

tmp = sortrows(tmp, {'family_best_base_score','family_base_score_gap'}, {'descend','descend'});
for i = 1:height(tmp)
    if height(tmp) > 1
        tmp.family_rank_metric(i) = (height(tmp) - i) / (height(tmp) - 1);
    else
        tmp.family_rank_metric(i) = 1;
    end
    tmp.family_gap_bonus(i) = clamp(tmp.family_base_score_gap(i) / 5.0, 0, 1);
    tmp.family_tie_penalty(i) = clamp((tmp.family_tie_count_eps(i) - 1) / 4.0, 0, 1);
end

family_tbl = tmp;
end

function family_tbl = refresh_family_with_global_scores(hyp_tbl, family_tbl, family_tie_eps)
for i = 1:height(family_tbl)
    p = family_tbl.perm_index(i);
    subset = hyp_tbl(hyp_tbl.perm_index == p, :);
    subset = sortrows(subset, {'score_global','base_score'}, {'descend','descend'});
    family_tbl.family_best_hypothesis_id(i) = subset.hypothesis_id(1);
    family_tbl.family_best_sign_label(i) = string(subset.sign_label(1));
    family_tbl.family_best_score(i) = subset.score_global(1);
    if height(subset) > 1
        family_tbl.family_second_best_score(i) = subset.score_global(2);
    else
        family_tbl.family_second_best_score(i) = subset.score_global(1);
    end
    family_tbl.family_tie_count_eps(i) = nnz((family_tbl.family_best_score(i) - subset.score_global) <= family_tie_eps);
end
end

function idx = axis_to_index(axis_name)
switch axis_name
    case "x"
        idx = 1;
    case "y"
        idx = 2;
    case "z"
        idx = 3;
    otherwise
        error("Eje no soportado: %s", axis_name);
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

function [manifest_abs, manifest_relpath, manifest_tbl] = resolve_manifest(repo_dir, preferred_relpath, fallback_relpath)
preferred_abs = fullfile(repo_dir, char(preferred_relpath));
fallback_abs = fullfile(repo_dir, char(fallback_relpath));
if isfile(preferred_abs)
    manifest_abs = preferred_abs;
elseif isfile(fallback_abs)
    manifest_abs = fallback_abs;
else
    error("No se encontro manifest preferido ni fallback.");
end
manifest_relpath = string(make_relpath(manifest_abs, repo_dir));
manifest_tbl = readtable(manifest_abs, "Delimiter", ",", "TextType", "string");
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

function rel = make_relpath(abs_path, repo_dir)
rel = strrep(abs_path, [repo_dir filesep], "");
end

function y = clamp(x, lo, hi)
y = min(max(x, lo), hi);
end
