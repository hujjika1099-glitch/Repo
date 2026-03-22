% validate_sensorC_coupled_linear_model.m
% Valida modelo lineal acoplado para sensor_C y compara contra modelo simple.

%% Configuracion
default_sensor_id = "sensor_C";
default_coupled_model_mat_relpath = "";
default_simple_model_mat_relpath = "data/processed/sensor_C_static_calibration_20260321_140044.mat";
default_simple_pose_summary_relpath = "data/processed/sensor_C_static_validation_20260321_140524_poses.csv";
default_simple_mapping_txt_relpath = "reports/analysis_outputs/sensor_C_axis_mapping_disambiguation_20260322_130308.txt";
default_simple_mapping_hyp_relpath = "reports/analysis_outputs/sensor_C_axis_mapping_disambiguation_20260322_130308_hypotheses.csv";
default_expected_pose_order = ["pos_x","neg_x","pos_y","neg_y","pos_z","neg_z"];

if exist("sensor_id", "var") && strlength(string(sensor_id)) > 0
    sensor_id = string(sensor_id);
else
    sensor_id = default_sensor_id;
end

if exist("coupled_model_mat_relpath", "var") && strlength(string(coupled_model_mat_relpath)) > 0
    coupled_model_mat_relpath = string(coupled_model_mat_relpath);
else
    coupled_model_mat_relpath = default_coupled_model_mat_relpath;
end

if exist("simple_model_mat_relpath", "var") && strlength(string(simple_model_mat_relpath)) > 0
    simple_model_mat_relpath = string(simple_model_mat_relpath);
else
    simple_model_mat_relpath = default_simple_model_mat_relpath;
end

if exist("simple_pose_summary_relpath", "var") && strlength(string(simple_pose_summary_relpath)) > 0
    simple_pose_summary_relpath = string(simple_pose_summary_relpath);
else
    simple_pose_summary_relpath = default_simple_pose_summary_relpath;
end

if exist("simple_mapping_txt_relpath", "var") && strlength(string(simple_mapping_txt_relpath)) > 0
    simple_mapping_txt_relpath = string(simple_mapping_txt_relpath);
else
    simple_mapping_txt_relpath = default_simple_mapping_txt_relpath;
end

if exist("simple_mapping_hyp_relpath", "var") && strlength(string(simple_mapping_hyp_relpath)) > 0
    simple_mapping_hyp_relpath = string(simple_mapping_hyp_relpath);
else
    simple_mapping_hyp_relpath = default_simple_mapping_hyp_relpath;
end

if exist("expected_pose_order", "var") && ~isempty(expected_pose_order)
    expected_pose_order = string(expected_pose_order(:))';
else
    expected_pose_order = default_expected_pose_order;
end

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
raw_dir = fullfile(repo_dir, "data", "raw", char(sensor_id));
processed_dir = fullfile(repo_dir, "data", "processed");
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
if ~isfolder(processed_dir), mkdir(processed_dir); end
if ~isfolder(analysis_out_dir), mkdir(analysis_out_dir); end

%% Cargar modelo acoplado
if strlength(coupled_model_mat_relpath) > 0
    coupled_model_mat_abs = fullfile(repo_dir, char(coupled_model_mat_relpath));
    if ~isfile(coupled_model_mat_abs)
        error("No existe coupled_model_mat: %s", coupled_model_mat_abs);
    end
else
    mats = dir(fullfile(processed_dir, char(sensor_id + "_coupled_linear_model_*.mat")));
    if isempty(mats)
        error("No hay modelo acoplado en %s", processed_dir);
    end
    [~, idx] = sort([mats.datenum], "ascend");
    mats = mats(idx);
    coupled_model_mat_abs = fullfile(mats(end).folder, mats(end).name);
end

loaded_coupled = load(coupled_model_mat_abs);
if ~isfield(loaded_coupled, "model")
    error("Modelo acoplado sin variable 'model'.");
end
model = loaded_coupled.model;
required_model_fields = ["A_mv","c_mv","dataset_manifest_relpath"];
for i = 1:numel(required_model_fields)
    if ~isfield(model, required_model_fields(i))
        error("Modelo acoplado incompleto, falta: %s", required_model_fields(i));
    end
end
A_mv = model.A_mv;
c_mv = model.c_mv;
dataset_manifest_relpath = string(model.dataset_manifest_relpath);
dataset_manifest_abs = fullfile(repo_dir, char(dataset_manifest_relpath));
if ~isfile(dataset_manifest_abs)
    error("Manifest del modelo acoplado no existe: %s", dataset_manifest_abs);
end

%% Cargar modelo simple baseline
simple_model_mat_abs = fullfile(repo_dir, char(simple_model_mat_relpath));
if ~isfile(simple_model_mat_abs)
    error("No existe simple_model_mat: %s", simple_model_mat_abs);
end
loaded_simple = load(simple_model_mat_abs);
if ~isfield(loaded_simple, "calibration")
    error("Modelo simple sin variable 'calibration'.");
end
cal = loaded_simple.calibration;
if ~isfield(cal, "coefficients")
    error("Calibration simple no contiene coefficients.");
end
coeff_tbl = cal.coefficients;
offset_x_mv = get_coeff(coeff_tbl, "x", "offset_mv");
offset_y_mv = get_coeff(coeff_tbl, "y", "offset_mv");
offset_z_mv = get_coeff(coeff_tbl, "z", "offset_mv");
sens_x_mv = get_coeff(coeff_tbl, "x", "sens_mv_per_g");
sens_y_mv = get_coeff(coeff_tbl, "y", "sens_mv_per_g");
sens_z_mv = get_coeff(coeff_tbl, "z", "sens_mv_per_g");

%% Cargar manifest dataset fijo de esta validacion
manifest_tbl = readtable(dataset_manifest_abs, "Delimiter", ",", "TextType", "string");
required_manifest_cols = {'pose','run_file'};
missing_manifest_cols = setdiff(required_manifest_cols, manifest_tbl.Properties.VariableNames);
if ~isempty(missing_manifest_cols)
    error("Manifest de validacion sin columnas requeridas: %s", strjoin(missing_manifest_cols, ", "));
end
manifest_tbl.pose = string(manifest_tbl.pose);
manifest_tbl.run_file = string(manifest_tbl.run_file);

%% Validacion por corrida
expected_cols = {'seq','t_us','raw_x','raw_y','raw_z','mv_x','mv_y','mv_z'};
n_runs = height(manifest_tbl);

pose = strings(n_runs,1);
run_file = strings(n_runs,1);
samples = zeros(n_runs,1);
duration_s = zeros(n_runs,1);
freq_hz = zeros(n_runs,1);
seq_jumps = zeros(n_runs,1);
mean_mv_x = zeros(n_runs,1);
mean_mv_y = zeros(n_runs,1);
mean_mv_z = zeros(n_runs,1);

% Coupled model
coupled_mean_gx = zeros(n_runs,1);
coupled_mean_gy = zeros(n_runs,1);
coupled_mean_gz = zeros(n_runs,1);
coupled_mean_gnorm = zeros(n_runs,1);
coupled_mean_error_gnorm = zeros(n_runs,1);
coupled_max_error_gnorm = zeros(n_runs,1);
coupled_expected_axis_mean = zeros(n_runs,1);
coupled_cross_axis_abs_mean = zeros(n_runs,1);
coupled_dominant_axis = strings(n_runs,1);
coupled_dominant_sign = zeros(n_runs,1);
coupled_axis_match = false(n_runs,1);
coupled_sign_match = false(n_runs,1);
coupled_exact_match = false(n_runs,1);

% Simple model on same dataset
simple_mean_gx = zeros(n_runs,1);
simple_mean_gy = zeros(n_runs,1);
simple_mean_gz = zeros(n_runs,1);
simple_mean_gnorm = zeros(n_runs,1);
simple_mean_error_gnorm = zeros(n_runs,1);
simple_max_error_gnorm = zeros(n_runs,1);
simple_expected_axis_mean = zeros(n_runs,1);
simple_cross_axis_abs_mean = zeros(n_runs,1);

for i = 1:n_runs
    pose_i = string(manifest_tbl.pose(i));
    file_i = string(manifest_tbl.run_file(i));
    csv_abs = fullfile(raw_dir, char(file_i));
    if ~isfile(csv_abs)
        error("CSV no encontrado: %s", csv_abs);
    end

    tbl = readtable(csv_abs, "Delimiter", ",", "TextType", "string");
    missing_cols = setdiff(expected_cols, tbl.Properties.VariableNames);
    if ~isempty(missing_cols)
        error("CSV sin columnas esperadas (%s): %s", file_i, strjoin(missing_cols, ", "));
    end
    tbl = tbl(:, expected_cols);
    n = height(tbl);
    if n < 2
        error("Corrida con muestras insuficientes: %s", file_i);
    end

    seq_col = double(tbl.seq);
    t_us = double(tbl.t_us);
    mv_vec = [
        mean(double(tbl.mv_x));
        mean(double(tbl.mv_y));
        mean(double(tbl.mv_z))
    ];
    [exp_axis, exp_sign] = expected_from_pose(pose_i);
    exp_idx = axis_to_index(exp_axis);

    % Coupled
    g_c = A_mv * mv_vec + c_mv;
    gnorm_c = norm(g_c);
    gerr_c = abs(gnorm_c - 1.0);
    cross_idx = setdiff(1:3, exp_idx);

    [~, dom_idx] = max(abs(g_c));
    dom_axis = ["x","y","z"];
    dom_sign = sign(g_c(dom_idx));
    axis_match = (dom_idx == exp_idx);
    sign_match = (sign(g_c(exp_idx)) == exp_sign) && (abs(g_c(exp_idx)) >= 0.20);

    % Simple
    gx_s = (mv_vec(1) - offset_x_mv) / sens_x_mv;
    gy_s = (mv_vec(2) - offset_y_mv) / sens_y_mv;
    gz_s = (mv_vec(3) - offset_z_mv) / sens_z_mv;
    g_s = [gx_s; gy_s; gz_s];
    gnorm_s = norm(g_s);
    gerr_s = abs(gnorm_s - 1.0);

    pose(i) = pose_i;
    run_file(i) = file_i;
    samples(i) = n;
    duration_s(i) = (t_us(end) - t_us(1)) / 1e6;
    freq_hz(i) = (n - 1) / max(duration_s(i), eps);
    seq_jumps(i) = nnz(diff(seq_col) ~= 1);
    mean_mv_x(i) = mv_vec(1);
    mean_mv_y(i) = mv_vec(2);
    mean_mv_z(i) = mv_vec(3);

    coupled_mean_gx(i) = g_c(1);
    coupled_mean_gy(i) = g_c(2);
    coupled_mean_gz(i) = g_c(3);
    coupled_mean_gnorm(i) = gnorm_c;
    coupled_mean_error_gnorm(i) = gerr_c;
    coupled_max_error_gnorm(i) = gerr_c;
    coupled_expected_axis_mean(i) = g_c(exp_idx) * exp_sign;
    coupled_cross_axis_abs_mean(i) = mean(abs(g_c(cross_idx)));
    coupled_dominant_axis(i) = dom_axis(dom_idx);
    coupled_dominant_sign(i) = dom_sign;
    coupled_axis_match(i) = axis_match;
    coupled_sign_match(i) = sign_match;
    coupled_exact_match(i) = axis_match && sign_match;

    simple_mean_gx(i) = gx_s;
    simple_mean_gy(i) = gy_s;
    simple_mean_gz(i) = gz_s;
    simple_mean_gnorm(i) = gnorm_s;
    simple_mean_error_gnorm(i) = gerr_s;
    simple_max_error_gnorm(i) = gerr_s;
    simple_expected_axis_mean(i) = g_s(exp_idx) * exp_sign;
    simple_cross_axis_abs_mean(i) = mean(abs(g_s(cross_idx)));
end

runs_tbl = table( ...
    pose, run_file, samples, duration_s, freq_hz, seq_jumps, ...
    mean_mv_x, mean_mv_y, mean_mv_z, ...
    coupled_mean_gx, coupled_mean_gy, coupled_mean_gz, ...
    coupled_mean_gnorm, coupled_mean_error_gnorm, coupled_max_error_gnorm, ...
    coupled_expected_axis_mean, coupled_cross_axis_abs_mean, ...
    coupled_dominant_axis, coupled_dominant_sign, coupled_axis_match, coupled_sign_match, coupled_exact_match, ...
    simple_mean_gx, simple_mean_gy, simple_mean_gz, ...
    simple_mean_gnorm, simple_mean_error_gnorm, simple_max_error_gnorm, ...
    simple_expected_axis_mean, simple_cross_axis_abs_mean);

%% Resumen por pose (coupled + simple)
pose_name = expected_pose_order(:);
runs_found = zeros(numel(pose_name),1);
seq_jumps_total = zeros(numel(pose_name),1);
freq_mean_hz = zeros(numel(pose_name),1);

% Coupled
coupled_pose_mean_gx = zeros(numel(pose_name),1);
coupled_pose_mean_gy = zeros(numel(pose_name),1);
coupled_pose_mean_gz = zeros(numel(pose_name),1);
coupled_pose_mean_gnorm = zeros(numel(pose_name),1);
coupled_pose_mean_err = zeros(numel(pose_name),1);
coupled_pose_max_err = zeros(numel(pose_name),1);
coupled_pose_mean_expected_axis = zeros(numel(pose_name),1);
coupled_pose_mean_cross_axis = zeros(numel(pose_name),1);
coupled_pose_dominant_axis = strings(numel(pose_name),1);
coupled_pose_dominant_sign = zeros(numel(pose_name),1);
coupled_pose_axis_match = false(numel(pose_name),1);
coupled_pose_sign_match = false(numel(pose_name),1);
coupled_pose_exact_match = false(numel(pose_name),1);

% Simple
simple_pose_mean_gnorm = zeros(numel(pose_name),1);
simple_pose_mean_err = zeros(numel(pose_name),1);
simple_pose_max_err = zeros(numel(pose_name),1);
simple_pose_mean_expected_axis = zeros(numel(pose_name),1);
simple_pose_mean_cross_axis = zeros(numel(pose_name),1);

for i = 1:numel(pose_name)
    p = pose_name(i);
    s = runs_tbl(runs_tbl.pose == p, :);
    runs_found(i) = height(s);
    seq_jumps_total(i) = sum(s.seq_jumps);
    freq_mean_hz(i) = mean(s.freq_hz);

    coupled_pose_mean_gx(i) = mean(s.coupled_mean_gx);
    coupled_pose_mean_gy(i) = mean(s.coupled_mean_gy);
    coupled_pose_mean_gz(i) = mean(s.coupled_mean_gz);
    coupled_pose_mean_gnorm(i) = mean(s.coupled_mean_gnorm);
    coupled_pose_mean_err(i) = mean(s.coupled_mean_error_gnorm);
    coupled_pose_max_err(i) = max(s.coupled_max_error_gnorm);
    coupled_pose_mean_expected_axis(i) = mean(s.coupled_expected_axis_mean);
    coupled_pose_mean_cross_axis(i) = mean(s.coupled_cross_axis_abs_mean);

    [exp_axis, exp_sign] = expected_from_pose(p);
    exp_idx = axis_to_index(exp_axis);
    g_pose = [coupled_pose_mean_gx(i), coupled_pose_mean_gy(i), coupled_pose_mean_gz(i)];
    [~, dom_idx] = max(abs(g_pose));
    dom_axes = ["x","y","z"];
    coupled_pose_dominant_axis(i) = dom_axes(dom_idx);
    coupled_pose_dominant_sign(i) = sign(g_pose(dom_idx));
    coupled_pose_axis_match(i) = (dom_idx == exp_idx);
    coupled_pose_sign_match(i) = (sign(g_pose(exp_idx)) == exp_sign) && (abs(g_pose(exp_idx)) >= 0.20);
    coupled_pose_exact_match(i) = coupled_pose_axis_match(i) && coupled_pose_sign_match(i);

    simple_pose_mean_gnorm(i) = mean(s.simple_mean_gnorm);
    simple_pose_mean_err(i) = mean(s.simple_mean_error_gnorm);
    simple_pose_max_err(i) = max(s.simple_max_error_gnorm);
    simple_pose_mean_expected_axis(i) = mean(s.simple_expected_axis_mean);
    simple_pose_mean_cross_axis(i) = mean(s.simple_cross_axis_abs_mean);
end

poses_tbl = table( ...
    pose_name, runs_found, seq_jumps_total, freq_mean_hz, ...
    coupled_pose_mean_gx, coupled_pose_mean_gy, coupled_pose_mean_gz, ...
    coupled_pose_mean_gnorm, coupled_pose_mean_err, coupled_pose_max_err, ...
    coupled_pose_mean_expected_axis, coupled_pose_mean_cross_axis, ...
    coupled_pose_dominant_axis, coupled_pose_dominant_sign, ...
    coupled_pose_axis_match, coupled_pose_sign_match, coupled_pose_exact_match, ...
    simple_pose_mean_gnorm, simple_pose_mean_err, simple_pose_max_err, ...
    simple_pose_mean_expected_axis, simple_pose_mean_cross_axis, ...
    'VariableNames', {'pose','runs_found','seq_jumps_total','freq_mean_hz', ...
    'mean_gx','mean_gy','mean_gz', ...
    'mean_gnorm','mean_error_gnorm','max_error_gnorm', ...
    'mean_expected_axis','mean_cross_axis_abs', ...
    'dominant_axis','dominant_sign', ...
    'axis_match','sign_match','exact_match', ...
    'simple_mean_gnorm','simple_mean_error_gnorm','simple_max_error_gnorm', ...
    'simple_mean_expected_axis','simple_mean_cross_axis_abs'});

%% Analisis por pares (modelo acoplado)
pair_name = ["x_pair","y_pair","z_pair"]';
expected_pair_axis = ["x","y","z"]';
delta_gx_pair = zeros(3,1);
delta_gy_pair = zeros(3,1);
delta_gz_pair = zeros(3,1);
dominant_pair_axis = strings(3,1);
pair_axis_match = false(3,1);
pair_sign_opposition_ok = false(3,1);
pair_dominance_ratio = zeros(3,1);

for i = 1:3
    ax = expected_pair_axis(i);
    pos_idx = poses_tbl.pose == ("pos_" + ax);
    neg_idx = poses_tbl.pose == ("neg_" + ax);

    gpos = [poses_tbl.mean_gx(pos_idx), poses_tbl.mean_gy(pos_idx), poses_tbl.mean_gz(pos_idx)];
    gneg = [poses_tbl.mean_gx(neg_idx), poses_tbl.mean_gy(neg_idx), poses_tbl.mean_gz(neg_idx)];
    d = gpos - gneg;

    delta_gx_pair(i) = d(1);
    delta_gy_pair(i) = d(2);
    delta_gz_pair(i) = d(3);

    [~, dom_idx] = max(abs(d));
    dom_axes = ["x","y","z"];
    dominant_pair_axis(i) = dom_axes(dom_idx);
    expected_idx = axis_to_index(ax);
    pair_axis_match(i) = (dom_idx == expected_idx);

    pair_sign_opposition_ok(i) = (gpos(expected_idx) >= 0.35) && (gneg(expected_idx) <= -0.35);
    pair_dominance_ratio(i) = abs(d(expected_idx)) / max(max(abs(d(setdiff(1:3, expected_idx)))), eps);
end

pairs_tbl = table( ...
    pair_name, expected_pair_axis, ...
    delta_gx_pair, delta_gy_pair, delta_gz_pair, ...
    dominant_pair_axis, pair_axis_match, pair_sign_opposition_ok, pair_dominance_ratio);

%% Comparacion por pose vs modelo simple
comparison_tbl = table( ...
    poses_tbl.pose, ...
    poses_tbl.simple_mean_gnorm, poses_tbl.mean_gnorm, poses_tbl.mean_gnorm - poses_tbl.simple_mean_gnorm, ...
    poses_tbl.simple_mean_error_gnorm, poses_tbl.mean_error_gnorm, poses_tbl.mean_error_gnorm - poses_tbl.simple_mean_error_gnorm, ...
    poses_tbl.simple_max_error_gnorm, poses_tbl.max_error_gnorm, poses_tbl.max_error_gnorm - poses_tbl.simple_max_error_gnorm, ...
    poses_tbl.simple_mean_expected_axis, poses_tbl.mean_expected_axis, poses_tbl.mean_expected_axis - poses_tbl.simple_mean_expected_axis, ...
    poses_tbl.simple_mean_cross_axis_abs, poses_tbl.mean_cross_axis_abs, poses_tbl.mean_cross_axis_abs - poses_tbl.simple_mean_cross_axis_abs, ...
    'VariableNames', {'pose', ...
    'simple_mean_gnorm','coupled_mean_gnorm','delta_mean_gnorm', ...
    'simple_mean_abs_gnorm_err','coupled_mean_abs_gnorm_err','delta_mean_abs_gnorm_err', ...
    'simple_max_abs_gnorm_err','coupled_max_abs_gnorm_err','delta_max_abs_gnorm_err', ...
    'simple_mean_expected_axis','coupled_mean_expected_axis','delta_mean_expected_axis', ...
    'simple_mean_cross_axis_abs','coupled_mean_cross_axis_abs','delta_mean_cross_axis_abs'});

global_simple_mean_err = mean(runs_tbl.simple_mean_error_gnorm);
global_coupled_mean_err = mean(runs_tbl.coupled_mean_error_gnorm);
global_improvement = global_simple_mean_err - global_coupled_mean_err;

simple_sorted = sortrows(comparison_tbl, 'simple_mean_abs_gnorm_err', 'descend');
worst_pose_1 = simple_sorted.pose(1);
worst_pose_2 = simple_sorted.pose(min(2,height(simple_sorted)));
worst_pose_1_delta_err = simple_sorted.delta_mean_abs_gnorm_err(1);
worst_pose_2_delta_err = simple_sorted.delta_mean_abs_gnorm_err(min(2,height(simple_sorted)));

%% Comparacion conceptual contra mejor modelo simple de Fase 10.6
simple_mapping_txt_abs = fullfile(repo_dir, char(simple_mapping_txt_relpath));
simple_mapping_hyp_abs = fullfile(repo_dir, char(simple_mapping_hyp_relpath));
simple_best_hyp_id = NaN;
simple_score_gap = NaN;
simple_best_vs_null_p95 = NaN;
simple_pair_axis_match_count = NaN;

if isfile(simple_mapping_txt_abs)
    kv = parse_key_value_file(simple_mapping_txt_abs);
    simple_best_hyp_id = parse_num(kv, "best_hypothesis_id");
    simple_score_gap = parse_num(kv, "score_gap");
    simple_best_vs_null_p95 = parse_num(kv, "best_vs_null_p95");
end

if isfile(simple_mapping_hyp_abs) && ~isnan(simple_best_hyp_id)
    hyp_tbl = readtable(simple_mapping_hyp_abs, "Delimiter", ",", "TextType", "string");
    hid = double(hyp_tbl.hypothesis_id) == simple_best_hyp_id;
    if any(hid) && ismember("pair_axis_match_count", hyp_tbl.Properties.VariableNames)
        simple_pair_axis_match_count = double(hyp_tbl.pair_axis_match_count(hid));
    end
end

%% Decision final automatica
seq_jumps_total = sum(runs_tbl.seq_jumps);
pair_axis_match_count = sum(pairs_tbl.pair_axis_match);
pair_sign_opposition_count = sum(pairs_tbl.pair_sign_opposition_ok);
avg_pair_dominance_ratio = mean(pairs_tbl.pair_dominance_ratio);
coupled_exact_pose_count = sum(poses_tbl.exact_match);
simple_exact_pose_count = sum(abs(comparison_tbl.simple_mean_expected_axis) >= 0.20); % proxy

expected_axis_gain = mean(comparison_tbl.delta_mean_expected_axis);
cross_axis_gain = -mean(comparison_tbl.delta_mean_cross_axis_abs); % positivo si mejora

if seq_jumps_total == 0 && ...
        global_improvement >= 0.10 && ...
        pair_axis_match_count >= 2 && ...
        pair_sign_opposition_count >= 2 && ...
        avg_pair_dominance_ratio >= 1.15 && ...
        expected_axis_gain > 0 && ...
        cross_axis_gain > 0
    final_decision = "coupled_model_supported";
elseif seq_jumps_total == 0 && ...
        global_improvement > 0.02 && ...
        (pair_axis_match_count >= 1 || coupled_exact_pose_count > simple_exact_pose_count)
    final_decision = "coupled_model_weak";
else
    final_decision = "coupled_model_not_supported";
end

%% Artefactos de salida
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
base = sensor_id + "_coupled_linear_validation_" + stamp;

runs_csv_out = fullfile(processed_dir, char(base + ".csv"));
poses_csv_out = fullfile(processed_dir, char(base + "_poses.csv"));
comparison_csv_out = fullfile(analysis_out_dir, char(base + "_comparison_vs_simple.csv"));
pairs_csv_out = fullfile(analysis_out_dir, char(base + "_pairs.csv"));
summary_txt_out = fullfile(analysis_out_dir, char(base + ".txt"));

writetable(runs_tbl, runs_csv_out);
writetable(poses_tbl, poses_csv_out);
writetable(comparison_tbl, comparison_csv_out);
writetable(pairs_tbl, pairs_csv_out);

fid = fopen(summary_txt_out, "w");
if fid < 0
    error("No fue posible escribir resumen de validacion: %s", summary_txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/analysis/validate_sensorC_coupled_linear_model.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "coupled_model_mat: %s\n", make_relpath(coupled_model_mat_abs, repo_dir));
fprintf(fid, "dataset_manifest: %s\n", make_relpath(dataset_manifest_abs, repo_dir));
fprintf(fid, "simple_model_mat: %s\n", make_relpath(simple_model_mat_abs, repo_dir));
fprintf(fid, "simple_pose_summary_ref: %s\n", simple_pose_summary_relpath);
fprintf(fid, "simple_mapping_txt_ref: %s\n", simple_mapping_txt_relpath);
fprintf(fid, "simple_mapping_hyp_ref: %s\n", simple_mapping_hyp_relpath);
fprintf(fid, "global_simple_mean_abs_gnorm_err: %.9f\n", global_simple_mean_err);
fprintf(fid, "global_coupled_mean_abs_gnorm_err: %.9f\n", global_coupled_mean_err);
fprintf(fid, "global_improvement_simple_minus_coupled: %.9f\n", global_improvement);
fprintf(fid, "pair_axis_match_count: %d\n", pair_axis_match_count);
fprintf(fid, "pair_sign_opposition_count: %d\n", pair_sign_opposition_count);
fprintf(fid, "avg_pair_dominance_ratio: %.9f\n", avg_pair_dominance_ratio);
fprintf(fid, "seq_jumps_total: %d\n", seq_jumps_total);
fprintf(fid, "coupled_exact_pose_count: %d\n", coupled_exact_pose_count);
fprintf(fid, "simple_exact_pose_proxy_count: %d\n", simple_exact_pose_count);
fprintf(fid, "expected_axis_gain: %.9f\n", expected_axis_gain);
fprintf(fid, "cross_axis_gain: %.9f\n", cross_axis_gain);
fprintf(fid, "worst_pose_1: %s\n", worst_pose_1);
fprintf(fid, "worst_pose_1_delta_mean_abs_gnorm_err: %.9f\n", worst_pose_1_delta_err);
fprintf(fid, "worst_pose_2: %s\n", worst_pose_2);
fprintf(fid, "worst_pose_2_delta_mean_abs_gnorm_err: %.9f\n", worst_pose_2_delta_err);
fprintf(fid, "simple_best_hypothesis_id_phase106: %.0f\n", simple_best_hyp_id);
fprintf(fid, "simple_score_gap_phase106: %.9f\n", simple_score_gap);
fprintf(fid, "simple_best_vs_null_p95_phase106: %.9f\n", simple_best_vs_null_p95);
fprintf(fid, "simple_pair_axis_match_count_phase106: %.9f\n", simple_pair_axis_match_count);
fprintf(fid, "final_decision: %s\n", final_decision);
fprintf(fid, "runs_csv: %s\n", make_relpath(runs_csv_out, repo_dir));
fprintf(fid, "poses_csv: %s\n", make_relpath(poses_csv_out, repo_dir));
fprintf(fid, "comparison_csv: %s\n", make_relpath(comparison_csv_out, repo_dir));
fprintf(fid, "pairs_csv: %s\n", make_relpath(pairs_csv_out, repo_dir));

fprintf("\nCOUPLED_LINEAR_VALIDATION_OK\n");
fprintf("RUNS_CSV: %s\n", make_relpath(runs_csv_out, repo_dir));
fprintf("POSES_CSV: %s\n", make_relpath(poses_csv_out, repo_dir));
fprintf("COMPARISON_CSV: %s\n", make_relpath(comparison_csv_out, repo_dir));
fprintf("PAIRS_CSV: %s\n", make_relpath(pairs_csv_out, repo_dir));
fprintf("SUMMARY_TXT: %s\n", make_relpath(summary_txt_out, repo_dir));
fprintf("GLOBAL_SIMPLE_MEAN_ERR: %.9f\n", global_simple_mean_err);
fprintf("GLOBAL_COUPLED_MEAN_ERR: %.9f\n", global_coupled_mean_err);
fprintf("FINAL_DECISION: %s\n", final_decision);

%% Funciones locales
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

function val = get_coeff(coeff_tbl, axis_name, col_name)
idx = string(coeff_tbl.axis) == axis_name;
if ~any(idx)
    error("No existe coeficiente para eje %s.", axis_name);
end
val = double(coeff_tbl.(col_name)(idx));
end

function rel = make_relpath(abs_path, repo_dir)
rel = strrep(abs_path, [repo_dir filesep], "");
end

function kv = parse_key_value_file(path_txt)
kv = containers.Map('KeyType', 'char', 'ValueType', 'char');
lines = string(splitlines(string(fileread(path_txt))));
for i = 1:numel(lines)
    ln = strtrim(lines(i));
    if strlength(ln) == 0 || ~contains(ln, ":")
        continue;
    end
    parts = split(ln, ":", 2);
    key = strtrim(lower(parts(1)));
    value = strtrim(parts(2));
    kv(char(key)) = char(value);
end
end

function num = parse_num(kv, key)
if isKey(kv, char(lower(key)))
    num = str2double(kv(char(lower(key))));
else
    num = NaN;
end
end
