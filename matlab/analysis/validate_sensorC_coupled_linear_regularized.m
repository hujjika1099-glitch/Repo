% validate_sensorC_coupled_linear_regularized.m
% Selecciona y valida un modelo acoplado regularizado para sensor_C.

%% Configuracion
default_sensor_id = "sensor_C";
default_candidates_mat_relpath = "";
default_current_coupled_model_mat_relpath = "data/processed/sensor_C_coupled_linear_model_20260322_131829.mat";
default_current_coupled_pose_csv_relpath = "data/processed/sensor_C_coupled_linear_validation_20260322_132133_poses.csv";
default_current_coupled_pairs_csv_relpath = "reports/analysis_outputs/sensor_C_coupled_linear_validation_20260322_132133_pairs.csv";
default_simple_pose_csv_relpath = "data/processed/sensor_C_static_validation_20260321_140524_poses.csv";
default_expected_pose_order = ["pos_x","neg_x","pos_y","neg_y","pos_z","neg_z"];

if exist("sensor_id", "var") && strlength(string(sensor_id)) > 0
    sensor_id = string(sensor_id);
else
    sensor_id = default_sensor_id;
end
if exist("candidates_mat_relpath", "var") && strlength(string(candidates_mat_relpath)) > 0
    candidates_mat_relpath = string(candidates_mat_relpath);
else
    candidates_mat_relpath = default_candidates_mat_relpath;
end
if exist("expected_pose_order", "var") && ~isempty(expected_pose_order)
    expected_pose_order = string(expected_pose_order(:))';
else
    expected_pose_order = default_expected_pose_order;
end

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
processed_dir = fullfile(repo_dir, "data", "processed");
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
if ~isfolder(processed_dir), mkdir(processed_dir); end
if ~isfolder(analysis_out_dir), mkdir(analysis_out_dir); end

%% Cargar candidatos
if strlength(candidates_mat_relpath) > 0
    candidates_mat_abs = fullfile(repo_dir, char(candidates_mat_relpath));
else
    mats = dir(fullfile(analysis_out_dir, char(sensor_id + "_coupled_regularized_candidates_*.mat")));
    if isempty(mats), error("No existen candidatos regularizados."); end
    [~, idx] = sort([mats.datenum], "ascend");
    mats = mats(idx);
    candidates_mat_abs = fullfile(mats(end).folder, mats(end).name);
end
if ~isfile(candidates_mat_abs), error("No existe %s", candidates_mat_abs); end

loaded_fit = load(candidates_mat_abs);
fit_result = loaded_fit.fit_result;
candidates_tbl = loaded_fit.candidates_tbl;
runs_input_tbl = fit_result.runs_tbl;
dataset_manifest_abs = fullfile(repo_dir, char(string(fit_result.dataset_manifest_phase_relpath)));
n_l = height(candidates_tbl);

%% Evaluacion de todos los lambdas
eval_cache = cell(n_l,1);
direct_global_mean_err = zeros(n_l,1);
direct_global_max_err = zeros(n_l,1);
direct_pose_axis_match_count = zeros(n_l,1);
direct_pose_sign_match_count = zeros(n_l,1);
direct_exact_pose_match_count = zeros(n_l,1);
direct_pair_axis_match_count = zeros(n_l,1);
direct_pair_sign_opposition_count = zeros(n_l,1);
direct_avg_pair_dominance_ratio = zeros(n_l,1);
direct_worst_pair_dominance_ratio = zeros(n_l,1);
direct_expected_axis_mean = zeros(n_l,1);
direct_cross_axis_abs_mean = zeros(n_l,1);
direct_seq_jumps_total = zeros(n_l,1);

cv_mean_abs_gnorm_err = zeros(n_l,1);
cv_max_abs_gnorm_err = zeros(n_l,1);
cv_expected_axis_mean = zeros(n_l,1);
cv_cross_axis_abs_mean = zeros(n_l,1);
cv_pair_axis_match_count = zeros(n_l,1);
cv_pair_sign_opposition_count = zeros(n_l,1);
cv_avg_pair_dominance_ratio = zeros(n_l,1);
cv_worst_pair_dominance_ratio = zeros(n_l,1);
cv_exact_pose_match_count = zeros(n_l,1);
cv_n_folds = zeros(n_l,1);
score_global = zeros(n_l,1);

for i = 1:n_l
    cand = fit_result.candidates(i);
    ev = coupled_eval_model(cand.A_mv, cand.c_mv, runs_input_tbl, expected_pose_order);
    eval_cache{i} = ev;

    direct_global_mean_err(i) = ev.metrics.global_mean_abs_gnorm_err;
    direct_global_max_err(i) = ev.metrics.global_max_abs_gnorm_err;
    direct_pose_axis_match_count(i) = ev.metrics.pose_axis_match_count;
    direct_pose_sign_match_count(i) = ev.metrics.pose_sign_match_count;
    direct_exact_pose_match_count(i) = ev.metrics.exact_pose_match_count;
    direct_pair_axis_match_count(i) = ev.metrics.pair_axis_match_count;
    direct_pair_sign_opposition_count(i) = ev.metrics.pair_sign_opposition_count;
    direct_avg_pair_dominance_ratio(i) = ev.metrics.avg_pair_dominance_ratio;
    direct_worst_pair_dominance_ratio(i) = ev.metrics.worst_pair_dominance_ratio;
    direct_expected_axis_mean(i) = ev.metrics.mean_expected_axis;
    direct_cross_axis_abs_mean(i) = ev.metrics.mean_cross_axis_abs;
    direct_seq_jumps_total(i) = ev.metrics.seq_jumps_total;

    cvm = coupled_cross_validate_lambda(cand.lambda, runs_input_tbl, expected_pose_order);
    cv_mean_abs_gnorm_err(i) = cvm.cv_mean_abs_gnorm_err;
    cv_max_abs_gnorm_err(i) = cvm.cv_max_abs_gnorm_err;
    cv_expected_axis_mean(i) = cvm.cv_expected_axis_mean;
    cv_cross_axis_abs_mean(i) = cvm.cv_cross_axis_abs_mean;
    cv_pair_axis_match_count(i) = cvm.cv_pair_axis_match_count;
    cv_pair_sign_opposition_count(i) = cvm.cv_pair_sign_opposition_count;
    cv_avg_pair_dominance_ratio(i) = cvm.cv_avg_pair_dominance_ratio;
    cv_worst_pair_dominance_ratio(i) = cvm.cv_worst_pair_dominance_ratio;
    cv_exact_pose_match_count(i) = cvm.cv_exact_pose_match_count;
    cv_n_folds(i) = cvm.cv_n_folds;

    s_cv_pair_axis = cv_pair_axis_match_count(i) / 3.0;
    s_cv_pair_sign = cv_pair_sign_opposition_count(i) / 3.0;
    s_cv_pair_dom = min(cv_avg_pair_dominance_ratio(i), 2.0) / 2.0;
    s_cv_err = 1.0 / (1.0 + cv_mean_abs_gnorm_err(i));
    s_cv_cross = 1.0 / (1.0 + cv_cross_axis_abs_mean(i));
    s_fit_err = 1.0 / (1.0 + candidates_tbl.rmse_overall(i));
    s_stability = min(max((log10(max(candidates_tbl.rcond_A(i), 1e-12)) + 12.0) / 12.0, 0.0), 1.0);
    score_global(i) = ...
        0.30 * s_cv_pair_axis + 0.20 * s_cv_pair_sign + 0.15 * s_cv_pair_dom + ...
        0.15 * s_cv_err + 0.08 * s_cv_cross + 0.07 * s_fit_err + 0.05 * s_stability;
end

selection_tbl = candidates_tbl;
selection_tbl.direct_global_mean_abs_gnorm_err = direct_global_mean_err;
selection_tbl.direct_global_max_abs_gnorm_err = direct_global_max_err;
selection_tbl.direct_pose_axis_match_count = direct_pose_axis_match_count;
selection_tbl.direct_pose_sign_match_count = direct_pose_sign_match_count;
selection_tbl.direct_exact_pose_match_count = direct_exact_pose_match_count;
selection_tbl.direct_pair_axis_match_count = direct_pair_axis_match_count;
selection_tbl.direct_pair_sign_opposition_count = direct_pair_sign_opposition_count;
selection_tbl.direct_avg_pair_dominance_ratio = direct_avg_pair_dominance_ratio;
selection_tbl.direct_worst_pair_dominance_ratio = direct_worst_pair_dominance_ratio;
selection_tbl.direct_mean_expected_axis = direct_expected_axis_mean;
selection_tbl.direct_mean_cross_axis_abs = direct_cross_axis_abs_mean;
selection_tbl.direct_seq_jumps_total = direct_seq_jumps_total;
selection_tbl.cv_mean_abs_gnorm_err = cv_mean_abs_gnorm_err;
selection_tbl.cv_max_abs_gnorm_err = cv_max_abs_gnorm_err;
selection_tbl.cv_expected_axis_mean = cv_expected_axis_mean;
selection_tbl.cv_cross_axis_abs_mean = cv_cross_axis_abs_mean;
selection_tbl.cv_pair_axis_match_count = cv_pair_axis_match_count;
selection_tbl.cv_pair_sign_opposition_count = cv_pair_sign_opposition_count;
selection_tbl.cv_avg_pair_dominance_ratio = cv_avg_pair_dominance_ratio;
selection_tbl.cv_worst_pair_dominance_ratio = cv_worst_pair_dominance_ratio;
selection_tbl.cv_exact_pose_match_count = cv_exact_pose_match_count;
selection_tbl.cv_n_folds = cv_n_folds;
selection_tbl.score_global = score_global;

[~, ord] = sortrows(selection_tbl, ...
    {'score_global','cv_pair_axis_match_count','cv_pair_sign_opposition_count', ...
    'cv_avg_pair_dominance_ratio','cv_mean_abs_gnorm_err','rmse_overall','cond_A'}, ...
    {'descend','descend','descend','descend','ascend','ascend','ascend'});
rank_col = zeros(height(selection_tbl),1);
rank_col(ord) = (1:height(selection_tbl))';
selection_tbl.rank = rank_col;
selection_tbl = sortrows(selection_tbl, "rank", "ascend");
selection_tbl.is_selected = selection_tbl.rank == 1;
best_row = selection_tbl(selection_tbl.is_selected, :);
best_lambda = best_row.lambda(1);
best_idx = find([fit_result.candidates.lambda] == best_lambda, 1, "first");
best_candidate = fit_result.candidates(best_idx);
best_eval = eval_cache{best_idx};

%% Comparacion con modelo actual
current_pose_tbl = readtable(fullfile(repo_dir, default_current_coupled_pose_csv_relpath), "Delimiter", ",", "TextType", "string");
current_pairs_tbl = readtable(fullfile(repo_dir, default_current_coupled_pairs_csv_relpath), "Delimiter", ",", "TextType", "string");
current_model = load(fullfile(repo_dir, default_current_coupled_model_mat_relpath)).model;

current_global_mean_err = mean(double(current_pose_tbl.mean_error_gnorm));
current_global_max_err = max(double(current_pose_tbl.max_error_gnorm));
current_exact_pose_count = sum(logical(double(current_pose_tbl.exact_match)));
current_pair_axis_match_count = sum(logical(double(current_pairs_tbl.pair_axis_match)));
current_pair_sign_count = sum(logical(double(current_pairs_tbl.pair_sign_opposition_ok)));
current_avg_pair_dom = mean(double(current_pairs_tbl.pair_dominance_ratio));
current_mean_expected_axis = mean(double(current_pose_tbl.mean_expected_axis));
current_mean_cross_axis = mean(double(current_pose_tbl.mean_cross_axis_abs));

regularized_global_mean_err = best_eval.metrics.global_mean_abs_gnorm_err;
regularized_global_max_err = best_eval.metrics.global_max_abs_gnorm_err;
regularized_exact_pose_count = best_eval.metrics.exact_pose_count;
regularized_pair_axis_match_count = best_eval.metrics.pair_axis_match_count;
regularized_pair_sign_count = best_eval.metrics.pair_sign_opposition_count;
regularized_avg_pair_dom = best_eval.metrics.avg_pair_dominance_ratio;
regularized_mean_expected_axis = best_eval.metrics.mean_expected_axis;
regularized_mean_cross_axis = best_eval.metrics.mean_cross_axis_abs;

comparison_current_tbl = table( ...
    ["global_mean_abs_gnorm_err";"global_max_abs_gnorm_err";"exact_pose_match_count"; ...
    "pair_axis_match_count";"pair_sign_opposition_count";"avg_pair_dominance_ratio"; ...
    "mean_expected_axis";"mean_cross_axis_abs";"rmse_overall";"cond_A";"rcond_A"], ...
    [current_global_mean_err; current_global_max_err; current_exact_pose_count; ...
    current_pair_axis_match_count; current_pair_sign_count; current_avg_pair_dom; ...
    current_mean_expected_axis; current_mean_cross_axis; ...
    current_model.rmse_overall; current_model.cond_A; current_model.rcond_A], ...
    [regularized_global_mean_err; regularized_global_max_err; regularized_exact_pose_count; ...
    regularized_pair_axis_match_count; regularized_pair_sign_count; regularized_avg_pair_dom; ...
    regularized_mean_expected_axis; regularized_mean_cross_axis; ...
    best_candidate.rmse_overall; best_candidate.cond_A; best_candidate.rcond_A], ...
    'VariableNames', {'metric','current_coupled_value','regularized_value'});
comparison_current_tbl.delta_regularized_minus_current = comparison_current_tbl.regularized_value - comparison_current_tbl.current_coupled_value;

%% Comparacion con simple (por pose y global)
simple_pose_tbl = readtable(fullfile(repo_dir, default_simple_pose_csv_relpath), "Delimiter", ",", "TextType", "string");
simple_pose_tbl.pose = string(simple_pose_tbl.pose);
current_pose_tbl.pose = string(current_pose_tbl.pose);
reg_pose_tbl = best_eval.poses_tbl;
simple_rows = strings(0,1);
s_mean_err = zeros(0,1); c_mean_err = zeros(0,1); r_mean_err = zeros(0,1);
s_exp = zeros(0,1); c_exp = zeros(0,1); r_exp = zeros(0,1);
s_cross = zeros(0,1); c_cross = zeros(0,1); r_cross = zeros(0,1);
for i = 1:numel(expected_pose_order)
    p = expected_pose_order(i);
    s = simple_pose_tbl(simple_pose_tbl.pose == p, :);
    c = current_pose_tbl(current_pose_tbl.pose == p, :);
    r = reg_pose_tbl(reg_pose_tbl.pose == p, :);
    simple_rows(end+1,1) = p; %#ok<SAGROW>
    s_mean_err(end+1,1) = double(s.mean_abs_gnorm_err(1)); %#ok<SAGROW>
    c_mean_err(end+1,1) = double(c.mean_error_gnorm(1)); %#ok<SAGROW>
    r_mean_err(end+1,1) = double(r.mean_error_gnorm(1)); %#ok<SAGROW>
    s_exp(end+1,1) = double(s.mean_expected_axis(1)); %#ok<SAGROW>
    c_exp(end+1,1) = double(c.mean_expected_axis(1)); %#ok<SAGROW>
    r_exp(end+1,1) = double(r.mean_expected_axis(1)); %#ok<SAGROW>
    s_cross(end+1,1) = double(s.mean_cross_axis_abs(1)); %#ok<SAGROW>
    c_cross(end+1,1) = double(c.mean_cross_axis_abs(1)); %#ok<SAGROW>
    r_cross(end+1,1) = double(r.mean_cross_axis_abs(1)); %#ok<SAGROW>
end
simple_rows(end+1,1) = "GLOBAL"; %#ok<SAGROW>
s_mean_err(end+1,1) = mean(s_mean_err); %#ok<SAGROW>
c_mean_err(end+1,1) = mean(c_mean_err); %#ok<SAGROW>
r_mean_err(end+1,1) = mean(r_mean_err); %#ok<SAGROW>
s_exp(end+1,1) = mean(s_exp); %#ok<SAGROW>
c_exp(end+1,1) = mean(c_exp); %#ok<SAGROW>
r_exp(end+1,1) = mean(r_exp); %#ok<SAGROW>
s_cross(end+1,1) = mean(s_cross); %#ok<SAGROW>
c_cross(end+1,1) = mean(c_cross); %#ok<SAGROW>
r_cross(end+1,1) = mean(r_cross); %#ok<SAGROW>

comparison_simple_tbl = table( ...
    simple_rows, s_mean_err, c_mean_err, r_mean_err, ...
    r_mean_err - s_mean_err, r_mean_err - c_mean_err, ...
    s_exp, c_exp, r_exp, r_exp - s_exp, r_exp - c_exp, ...
    s_cross, c_cross, r_cross, r_cross - s_cross, r_cross - c_cross, ...
    'VariableNames', {'pose','simple_mean_abs_gnorm_err','coupled_current_mean_abs_gnorm_err', ...
    'coupled_regularized_mean_abs_gnorm_err','delta_mean_abs_gnorm_err_reg_vs_simple', ...
    'delta_mean_abs_gnorm_err_reg_vs_current','simple_mean_expected_axis', ...
    'coupled_current_mean_expected_axis','coupled_regularized_mean_expected_axis', ...
    'delta_mean_expected_axis_reg_vs_simple','delta_mean_expected_axis_reg_vs_current', ...
    'simple_mean_cross_axis_abs','coupled_current_mean_cross_axis_abs', ...
    'coupled_regularized_mean_cross_axis_abs','delta_mean_cross_axis_abs_reg_vs_simple', ...
    'delta_mean_cross_axis_abs_reg_vs_current'});

global_simple_mean_err = comparison_simple_tbl.simple_mean_abs_gnorm_err(comparison_simple_tbl.pose == "GLOBAL");
global_current_mean_err = comparison_simple_tbl.coupled_current_mean_abs_gnorm_err(comparison_simple_tbl.pose == "GLOBAL");
global_regularized_mean_err = comparison_simple_tbl.coupled_regularized_mean_abs_gnorm_err(comparison_simple_tbl.pose == "GLOBAL");

%% Decision final
selected_cv_row = selection_tbl(selection_tbl.is_selected, :);
seq_jumps_total = best_eval.metrics.seq_jumps_total;
improve_vs_current = global_current_mean_err - global_regularized_mean_err;
improve_vs_simple = global_simple_mean_err - global_regularized_mean_err;
if seq_jumps_total == 0 && improve_vs_current >= 0.03 && improve_vs_simple >= 0.25 && ...
        regularized_pair_axis_match_count >= 2 && regularized_pair_sign_count >= 2 && ...
        regularized_avg_pair_dom >= 1.00 && selected_cv_row.cv_pair_axis_match_count >= 2 && ...
        selected_cv_row.cv_pair_sign_opposition_count >= 2 && selected_cv_row.cv_avg_pair_dominance_ratio >= 1.00 && ...
        selected_cv_row.cv_mean_abs_gnorm_err <= global_current_mean_err + 0.05 && best_candidate.rcond_A >= 1e-6
    final_decision = "coupled_model_supported";
elseif seq_jumps_total == 0 && (improve_vs_current > 0 || improve_vs_simple > 0) && ...
        (regularized_pair_axis_match_count >= 1 || selected_cv_row.cv_pair_axis_match_count >= 1)
    final_decision = "coupled_model_weak";
else
    final_decision = "coupled_model_not_supported";
end

%% Salidas
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
selection_csv_out = fullfile(analysis_out_dir, char(sensor_id + "_coupled_regularized_selection_" + stamp + ".csv"));
writetable(selection_tbl, selection_csv_out);

model_base = sensor_id + "_coupled_regularized_model_" + stamp;
model_csv_out = fullfile(processed_dir, char(model_base + ".csv"));
model_mat_out = fullfile(processed_dir, char(model_base + ".mat"));
validation_base = sensor_id + "_coupled_regularized_validation_" + stamp;
runs_csv_out = fullfile(processed_dir, char(validation_base + ".csv"));
poses_csv_out = fullfile(processed_dir, char(validation_base + "_poses.csv"));
pairs_csv_out = fullfile(analysis_out_dir, char(validation_base + "_pairs.csv"));
comparison_current_csv_out = fullfile(analysis_out_dir, char(validation_base + "_comparison_vs_current_coupled.csv"));
comparison_simple_csv_out = fullfile(analysis_out_dir, char(validation_base + "_comparison_vs_simple.csv"));
summary_txt_out = fullfile(analysis_out_dir, char(validation_base + ".txt"));

writetable(best_eval.runs_tbl, runs_csv_out);
writetable(best_eval.poses_tbl, poses_csv_out);
writetable(best_eval.pairs_tbl, pairs_csv_out);
writetable(comparison_current_tbl, comparison_current_csv_out);
writetable(comparison_simple_tbl, comparison_simple_csv_out);

coeff_name = strings(0,1); coeff_value = zeros(0,1);
for r = 1:3
    for c = 1:3
        coeff_name(end+1,1) = "A_mv_" + r + "_" + c; %#ok<SAGROW>
        coeff_value(end+1,1) = best_candidate.A_mv(r,c); %#ok<SAGROW>
    end
end
for r = 1:3
    coeff_name(end+1,1) = "c_mv_" + r; %#ok<SAGROW>
    coeff_value(end+1,1) = best_candidate.c_mv(r); %#ok<SAGROW>
end
for r = 1:3
    for c = 1:3
        coeff_name(end+1,1) = "M_mv_" + r + "_" + c; %#ok<SAGROW>
        coeff_value(end+1,1) = best_candidate.M_mv(r,c); %#ok<SAGROW>
    end
end
for r = 1:3
    coeff_name(end+1,1) = "b_mv_" + r; %#ok<SAGROW>
    coeff_value(end+1,1) = best_candidate.b_mv(r); %#ok<SAGROW>
end
coeff_name(end+1,1) = "lambda"; coeff_value(end+1,1) = best_lambda;
coeff_name(end+1,1) = "rmse_overall"; coeff_value(end+1,1) = best_candidate.rmse_overall;
coeff_name(end+1,1) = "cond_A"; coeff_value(end+1,1) = best_candidate.cond_A;
coeff_name(end+1,1) = "rcond_A"; coeff_value(end+1,1) = best_candidate.rcond_A;
coeff_name(end+1,1) = "cv_mean_abs_gnorm_err"; coeff_value(end+1,1) = selected_cv_row.cv_mean_abs_gnorm_err;
coeff_name(end+1,1) = "cv_avg_pair_dominance_ratio"; coeff_value(end+1,1) = selected_cv_row.cv_avg_pair_dominance_ratio;
coeff_name(end+1,1) = "cv_pair_axis_match_count"; coeff_value(end+1,1) = selected_cv_row.cv_pair_axis_match_count;
coeff_name(end+1,1) = "cv_pair_sign_opposition_count"; coeff_value(end+1,1) = selected_cv_row.cv_pair_sign_opposition_count;
coeff_name(end+1,1) = "score_global"; coeff_value(end+1,1) = selected_cv_row.score_global;
writetable(table(coeff_name, coeff_value, 'VariableNames', {'parameter','value'}), model_csv_out);

model = struct();
model.sensor_id = sensor_id;
model.model_type = "coupled_linear_regularized";
model.created_at = string(datetime("now", "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss Z"));
model.lambda = best_lambda;
model.A_mv = best_candidate.A_mv;
model.c_mv = best_candidate.c_mv;
model.M_mv = best_candidate.M_mv;
model.b_mv = best_candidate.b_mv;
model.cond_A = best_candidate.cond_A;
model.rcond_A = best_candidate.rcond_A;
model.b_solve_method = best_candidate.b_solve_method;
model.rmse_overall = best_candidate.rmse_overall;
model.score_global = selected_cv_row.score_global;
model.dataset_manifest_relpath = local_relpath(dataset_manifest_abs, repo_dir);
model.candidates_mat_relpath = local_relpath(candidates_mat_abs, repo_dir);
model.final_decision = final_decision;
save(model_mat_out, "model", "selection_tbl");

fid = fopen(summary_txt_out, "w");
if fid < 0, error("No fue posible escribir resumen."); end
cleanup_fid = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, "script: matlab/analysis/validate_sensorC_coupled_linear_regularized.m\n");
fprintf(fid, "dataset_manifest: %s\n", local_relpath(dataset_manifest_abs, repo_dir));
fprintf(fid, "candidates_mat: %s\n", local_relpath(candidates_mat_abs, repo_dir));
fprintf(fid, "selected_lambda: %.10g\n", best_lambda);
fprintf(fid, "selected_score_global: %.9f\n", selected_cv_row.score_global);
fprintf(fid, "global_simple_mean_err: %.9f\n", global_simple_mean_err);
fprintf(fid, "global_current_coupled_mean_err: %.9f\n", global_current_mean_err);
fprintf(fid, "global_regularized_mean_err: %.9f\n", global_regularized_mean_err);
fprintf(fid, "improve_vs_current: %.9f\n", improve_vs_current);
fprintf(fid, "improve_vs_simple: %.9f\n", improve_vs_simple);
fprintf(fid, "seq_jumps_total: %d\n", seq_jumps_total);
fprintf(fid, "final_decision: %s\n", final_decision);
fprintf(fid, "selection_csv: %s\n", local_relpath(selection_csv_out, repo_dir));
fprintf(fid, "model_csv: %s\n", local_relpath(model_csv_out, repo_dir));
fprintf(fid, "model_mat: %s\n", local_relpath(model_mat_out, repo_dir));
fprintf(fid, "runs_csv: %s\n", local_relpath(runs_csv_out, repo_dir));
fprintf(fid, "poses_csv: %s\n", local_relpath(poses_csv_out, repo_dir));
fprintf(fid, "pairs_csv: %s\n", local_relpath(pairs_csv_out, repo_dir));
fprintf(fid, "comparison_vs_current: %s\n", local_relpath(comparison_current_csv_out, repo_dir));
fprintf(fid, "comparison_vs_simple: %s\n", local_relpath(comparison_simple_csv_out, repo_dir));

fprintf("\nCOUPLED_REGULARIZED_VALIDATION_OK\n");
fprintf("SELECTED_LAMBDA: %.10g\n", best_lambda);
fprintf("MODEL_CSV: %s\n", local_relpath(model_csv_out, repo_dir));
fprintf("MODEL_MAT: %s\n", local_relpath(model_mat_out, repo_dir));
fprintf("SELECTION_CSV: %s\n", local_relpath(selection_csv_out, repo_dir));
fprintf("RUNS_CSV: %s\n", local_relpath(runs_csv_out, repo_dir));
fprintf("POSES_CSV: %s\n", local_relpath(poses_csv_out, repo_dir));
fprintf("PAIRS_CSV: %s\n", local_relpath(pairs_csv_out, repo_dir));
fprintf("COMPARISON_CURRENT: %s\n", local_relpath(comparison_current_csv_out, repo_dir));
fprintf("COMPARISON_SIMPLE: %s\n", local_relpath(comparison_simple_csv_out, repo_dir));
fprintf("SUMMARY_TXT: %s\n", local_relpath(summary_txt_out, repo_dir));
fprintf("FINAL_DECISION: %s\n", final_decision);

function rel = local_relpath(abs_path, repo_dir)
rel = strrep(abs_path, [repo_dir filesep], "");
end
