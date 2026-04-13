% run_sensorC_phase11_operational_interpretation.m
% Fase 11: capa operativa desacoplada de convencion/mapeo/signos.
%
% Flujo:
% raw -> mV -> calibracion simple Fase 10 -> remapeo/conversion -> salida operativa.

%% Configuracion
if ~exist("sensor_id", "var") || strlength(string(sensor_id)) == 0
    sensor_id = "sensor_C";
else
    sensor_id = string(sensor_id);
end

if ~exist("calibration_mat_relpath", "var") || strlength(string(calibration_mat_relpath)) == 0
    calibration_mat_relpath = "data/processed/sensor_C_static_calibration_20260321_140044.mat";
else
    calibration_mat_relpath = string(calibration_mat_relpath);
end

if ~exist("convention_json_relpath", "var") || strlength(string(convention_json_relpath)) == 0
    convention_json_relpath = "config/sensor_C_axis_convention_phase11.json";
else
    convention_json_relpath = string(convention_json_relpath);
end

if ~exist("dataset_manifest_relpath", "var") || strlength(string(dataset_manifest_relpath)) == 0
    dataset_manifest_relpath = "reports/analysis_outputs/sensor_C_static_calibration_20260321_140044_dataset.csv";
else
    dataset_manifest_relpath = string(dataset_manifest_relpath);
end

if ~exist("pair_sign_threshold_g", "var") || isempty(pair_sign_threshold_g)
    pair_sign_threshold_g = 0.35;
end
if ~exist("pair_dominance_ratio_min", "var") || isempty(pair_dominance_ratio_min)
    pair_dominance_ratio_min = 1.15;
end
if ~exist("expected_axis_abs_min", "var") || isempty(expected_axis_abs_min)
    expected_axis_abs_min = 0.55;
end
if ~exist("cross_axis_abs_max", "var") || isempty(cross_axis_abs_max)
    cross_axis_abs_max = 0.65;
end

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
raw_dir = fullfile(repo_dir, "data", "raw", char(sensor_id));
processed_dir = fullfile(repo_dir, "data", "processed");
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
if ~isfolder(processed_dir)
    mkdir(processed_dir);
end
if ~isfolder(analysis_out_dir)
    mkdir(analysis_out_dir);
end

calibration_mat_abs = fullfile(repo_dir, char(calibration_mat_relpath));
if ~isfile(calibration_mat_abs)
    error("No existe calibracion baseline: %s", calibration_mat_abs);
end

convention_json_abs = fullfile(repo_dir, char(convention_json_relpath));
if ~isfile(convention_json_abs)
    error("No existe config de convencion: %s", convention_json_abs);
end

dataset_manifest_abs = fullfile(repo_dir, char(dataset_manifest_relpath));
if ~isfile(dataset_manifest_abs)
    error("No existe manifest de dataset: %s", dataset_manifest_abs);
end

%% Cargar calibracion baseline Fase 10
loaded = load(calibration_mat_abs);
if ~isfield(loaded, "calibration") || ~isfield(loaded.calibration, "coefficients")
    error("MAT baseline invalido: falta calibration.coefficients");
end
coeff_tbl = loaded.calibration.coefficients;

offset_x_mv = get_coeff(coeff_tbl, "x", "offset_mv");
offset_y_mv = get_coeff(coeff_tbl, "y", "offset_mv");
offset_z_mv = get_coeff(coeff_tbl, "z", "offset_mv");
sens_x_mv = get_coeff(coeff_tbl, "x", "sens_mv_per_g");
sens_y_mv = get_coeff(coeff_tbl, "y", "sens_mv_per_g");
sens_z_mv = get_coeff(coeff_tbl, "z", "sens_mv_per_g");

if any(abs([sens_x_mv sens_y_mv sens_z_mv]) < eps)
    error("Sensibilidades nulas detectadas en baseline.");
end

%% Cargar config de convencion
convention_cfg = load_json_struct(convention_json_abs);
identity_status = get_nested_string(convention_cfg, {"identity", "status"}, "unknown");

%% Cargar manifest del dataset
manifest_tbl = readtable(dataset_manifest_abs, "Delimiter", ",", "TextType", "string");
req_manifest = {'pose','run_file'};
missing_manifest = setdiff(req_manifest, manifest_tbl.Properties.VariableNames);
if ~isempty(missing_manifest)
    error("Manifest incompleto: %s", strjoin(missing_manifest, ", "));
end
manifest_tbl.pose = string(manifest_tbl.pose);
manifest_tbl.run_file = string(manifest_tbl.run_file);

required_poses = ["pos_x","neg_x","pos_y","neg_y","pos_z","neg_z"];
for i = 1:numel(required_poses)
    if ~any(manifest_tbl.pose == required_poses(i))
        error("Manifest sin pose requerida: %s", required_poses(i));
    end
end

%% Evaluacion por corrida
expected_cols = {'seq','t_us','raw_x','raw_y','raw_z','mv_x','mv_y','mv_z'};

n_runs = height(manifest_tbl);
pose = strings(n_runs,1);
run_file = strings(n_runs,1);
samples = zeros(n_runs,1);
duration_s = zeros(n_runs,1);
freq_hz = zeros(n_runs,1);
seq_jumps = zeros(n_runs,1);

mean_gx_channel = zeros(n_runs,1);
mean_gy_channel = zeros(n_runs,1);
mean_gz_channel = zeros(n_runs,1);

mean_gx_oper = zeros(n_runs,1);
mean_gy_oper = zeros(n_runs,1);
mean_gz_oper = zeros(n_runs,1);

mean_gnorm_oper = zeros(n_runs,1);
mean_abs_gnorm_err_oper = zeros(n_runs,1);
max_abs_gnorm_err_oper = zeros(n_runs,1);

expected_axis = strings(n_runs,1);
expected_sign = zeros(n_runs,1);
expected_axis_mean = zeros(n_runs,1);
cross_axis_abs_mean = zeros(n_runs,1);
dominant_axis = strings(n_runs,1);
dominant_sign = zeros(n_runs,1);
axis_match = false(n_runs,1);
sign_match = false(n_runs,1);
exact_match = false(n_runs,1);

for i = 1:n_runs
    pose(i) = manifest_tbl.pose(i);
    run_file(i) = manifest_tbl.run_file(i);

    csv_abs = fullfile(raw_dir, char(run_file(i)));
    if ~isfile(csv_abs)
        error("CSV no encontrado: %s", csv_abs);
    end

    tbl = readtable(csv_abs, "Delimiter", ",", "TextType", "string");
    missing_cols = setdiff(expected_cols, tbl.Properties.VariableNames);
    if ~isempty(missing_cols)
        error("CSV sin columnas esperadas (%s): %s", run_file(i), strjoin(missing_cols, ", "));
    end
    tbl = tbl(:, expected_cols);

    n = height(tbl);
    if n < 2
        error("Corrida sin suficientes muestras: %s", run_file(i));
    end

    t_us = double(tbl.t_us);
    samples(i) = n;
    duration_s(i) = (t_us(end) - t_us(1)) / 1e6;
    freq_hz(i) = (n - 1) / max(duration_s(i), eps);
    seq_jumps(i) = nnz(diff(double(tbl.seq)) ~= 1);

    mv_x = double(tbl.mv_x);
    mv_y = double(tbl.mv_y);
    mv_z = double(tbl.mv_z);

    g_ch = [ ...
        (mv_x - offset_x_mv) ./ sens_x_mv, ...
        (mv_y - offset_y_mv) ./ sens_y_mv, ...
        (mv_z - offset_z_mv) ./ sens_z_mv];

    [g_oper_ts, ~] = apply_sensor_axis_convention(g_ch, convention_cfg);

    mean_gx_channel(i) = mean(g_ch(:,1));
    mean_gy_channel(i) = mean(g_ch(:,2));
    mean_gz_channel(i) = mean(g_ch(:,3));

    mean_gx_oper(i) = mean(g_oper_ts(:,1));
    mean_gy_oper(i) = mean(g_oper_ts(:,2));
    mean_gz_oper(i) = mean(g_oper_ts(:,3));

    gnorm = sqrt(sum(g_oper_ts.^2, 2));
    gerr = abs(gnorm - 1.0);
    mean_gnorm_oper(i) = mean(gnorm);
    mean_abs_gnorm_err_oper(i) = mean(gerr);
    max_abs_gnorm_err_oper(i) = max(gerr);

    [exp_axis, exp_sign] = expected_from_pose(pose(i));
    expected_axis(i) = exp_axis;
    expected_sign(i) = exp_sign;

    [exp_axis_mean_val, cross_mean_val] = axis_alignment_metrics(g_oper_ts, exp_axis, exp_sign);
    expected_axis_mean(i) = exp_axis_mean_val;
    cross_axis_abs_mean(i) = cross_mean_val;

    mean_vec = [mean_gx_oper(i), mean_gy_oper(i), mean_gz_oper(i)];
    [~, didx] = max(abs(mean_vec));
    dominant_axis(i) = idx_to_axis(didx);
    dominant_sign(i) = sign(mean_vec(didx));

    exp_idx = axis_to_index(exp_axis);
    axis_match(i) = didx == exp_idx;
    sign_match(i) = sign(mean_vec(exp_idx)) == exp_sign;
    exact_match(i) = axis_match(i) && sign_match(i);
end

run_tbl = table( ...
    pose, run_file, samples, duration_s, freq_hz, seq_jumps, ...
    mean_gx_channel, mean_gy_channel, mean_gz_channel, ...
    mean_gx_oper, mean_gy_oper, mean_gz_oper, ...
    mean_gnorm_oper, mean_abs_gnorm_err_oper, max_abs_gnorm_err_oper, ...
    expected_axis, expected_sign, expected_axis_mean, cross_axis_abs_mean, ...
    dominant_axis, dominant_sign, axis_match, sign_match, exact_match, ...
    'VariableNames', {'pose','run_file','samples','duration_s','freq_hz','seq_jumps', ...
    'mean_gx_channel','mean_gy_channel','mean_gz_channel', ...
    'mean_gx_oper','mean_gy_oper','mean_gz_oper', ...
    'mean_gnorm_oper','mean_abs_gnorm_err_oper','max_abs_gnorm_err_oper', ...
    'expected_axis','expected_sign','expected_axis_mean','cross_axis_abs_mean', ...
    'dominant_axis','dominant_sign','axis_match','sign_match','exact_match'});

%% Resumen por pose
pose_name = required_poses(:);
runs_found = zeros(numel(required_poses),1);
freq_mean_hz = zeros(numel(required_poses),1);
seq_jumps_total = zeros(numel(required_poses),1);

mean_gx_pose = zeros(numel(required_poses),1);
mean_gy_pose = zeros(numel(required_poses),1);
mean_gz_pose = zeros(numel(required_poses),1);

mean_gnorm_pose = zeros(numel(required_poses),1);
mean_abs_gnorm_err_pose = zeros(numel(required_poses),1);
max_abs_gnorm_err_pose = zeros(numel(required_poses),1);

mean_expected_axis_pose = zeros(numel(required_poses),1);
mean_cross_axis_abs_pose = zeros(numel(required_poses),1);

dominant_axis_pose = strings(numel(required_poses),1);
dominant_sign_pose = zeros(numel(required_poses),1);
axis_match_count_pose = zeros(numel(required_poses),1);
sign_match_count_pose = zeros(numel(required_poses),1);
exact_match_count_pose = zeros(numel(required_poses),1);

for i = 1:numel(required_poses)
    p = required_poses(i);
    s = run_tbl(run_tbl.pose == p, :);
    if isempty(s)
        error("Sin corridas para pose %s", p);
    end

    runs_found(i) = height(s);
    freq_mean_hz(i) = mean(s.freq_hz);
    seq_jumps_total(i) = sum(s.seq_jumps);

    mean_gx_pose(i) = mean(s.mean_gx_oper);
    mean_gy_pose(i) = mean(s.mean_gy_oper);
    mean_gz_pose(i) = mean(s.mean_gz_oper);

    mean_gnorm_pose(i) = mean(s.mean_gnorm_oper);
    mean_abs_gnorm_err_pose(i) = mean(s.mean_abs_gnorm_err_oper);
    max_abs_gnorm_err_pose(i) = max(s.max_abs_gnorm_err_oper);

    mean_expected_axis_pose(i) = mean(s.expected_axis_mean);
    mean_cross_axis_abs_pose(i) = mean(s.cross_axis_abs_mean);

    mean_vec = [mean_gx_pose(i), mean_gy_pose(i), mean_gz_pose(i)];
    [~, didx] = max(abs(mean_vec));
    dominant_axis_pose(i) = idx_to_axis(didx);
    dominant_sign_pose(i) = sign(mean_vec(didx));

    axis_match_count_pose(i) = sum(s.axis_match);
    sign_match_count_pose(i) = sum(s.sign_match);
    exact_match_count_pose(i) = sum(s.exact_match);
end

pose_tbl = table( ...
    pose_name, runs_found, freq_mean_hz, seq_jumps_total, ...
    mean_gx_pose, mean_gy_pose, mean_gz_pose, ...
    mean_gnorm_pose, mean_abs_gnorm_err_pose, max_abs_gnorm_err_pose, ...
    mean_expected_axis_pose, mean_cross_axis_abs_pose, ...
    dominant_axis_pose, dominant_sign_pose, axis_match_count_pose, sign_match_count_pose, exact_match_count_pose, ...
    'VariableNames', {'pose','runs_found','freq_mean_hz','seq_jumps_total', ...
    'mean_gx','mean_gy','mean_gz', ...
    'mean_gnorm','mean_abs_gnorm_err','max_abs_gnorm_err', ...
    'mean_expected_axis','mean_cross_axis_abs', ...
    'dominant_axis','dominant_sign','axis_match_count','sign_match_count','exact_match_count'});

%% Resumen por pares
axis_pair = ["x";"y";"z"];

delta_gx = zeros(3,1);
delta_gy = zeros(3,1);
delta_gz = zeros(3,1);
dominant_pair_axis = strings(3,1);
pair_axis_match = false(3,1);
pair_sign_opposition_ok = false(3,1);
pair_dominance_ratio = zeros(3,1);

for i = 1:3
    ax = axis_pair(i);
    pos_idx = pose_tbl.pose == ("pos_" + ax);
    neg_idx = pose_tbl.pose == ("neg_" + ax);

    g_pos = [pose_tbl.mean_gx(pos_idx), pose_tbl.mean_gy(pos_idx), pose_tbl.mean_gz(pos_idx)];
    g_neg = [pose_tbl.mean_gx(neg_idx), pose_tbl.mean_gy(neg_idx), pose_tbl.mean_gz(neg_idx)];

    d = g_pos - g_neg;
    delta_gx(i) = d(1);
    delta_gy(i) = d(2);
    delta_gz(i) = d(3);

    [~, didx] = max(abs(d));
    dominant_pair_axis(i) = idx_to_axis(didx);
    pair_axis_match(i) = didx == i;

    pair_dominance_ratio(i) = abs(d(i)) / max(max(abs(d(setdiff(1:3, i)))), eps);
    pair_sign_opposition_ok(i) = (g_pos(i) >= pair_sign_threshold_g) && (g_neg(i) <= -pair_sign_threshold_g);
end

pair_tbl = table( ...
    axis_pair, delta_gx, delta_gy, delta_gz, dominant_pair_axis, pair_axis_match, pair_sign_opposition_ok, pair_dominance_ratio, ...
    'VariableNames', {'axis_pair','delta_gx','delta_gy','delta_gz','dominant_axis','pair_axis_match','pair_sign_opposition_ok','pair_dominance_ratio'});

%% Decision operativa
pair_axis_match_count = sum(pair_tbl.pair_axis_match);
pair_sign_opposition_count = sum(pair_tbl.pair_sign_opposition_ok);
avg_pair_dominance_ratio = mean(pair_tbl.pair_dominance_ratio);
any_seq_jumps = any(run_tbl.seq_jumps > 0);
mean_expected_axis_global = mean(run_tbl.expected_axis_mean);
mean_cross_axis_global = mean(run_tbl.cross_axis_abs_mean);

metrics_ok = ...
    (pair_axis_match_count >= 2) && ...
    (pair_sign_opposition_count >= 2) && ...
    (avg_pair_dominance_ratio >= pair_dominance_ratio_min) && ...
    (mean_expected_axis_global >= expected_axis_abs_min) && ...
    (mean_cross_axis_global <= cross_axis_abs_max);

if any_seq_jumps
    final_decision = "blocked_data_integrity";
    promotion_decision = "no";
elseif identity_status == "identity_closed" && metrics_ok
    final_decision = "operationally_usable";
    promotion_decision = "yes";
elseif metrics_ok
    final_decision = "operationally_usable_provisional_identity";
    promotion_decision = "no";
else
    final_decision = "identity_or_convention_review_needed";
    promotion_decision = "no";
end

%% Guardado
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
out_base = sensor_id + "_phase11_operational_interpretation_" + stamp;
run_csv_out = fullfile(analysis_out_dir, char(out_base + "_runs.csv"));
pose_csv_out = fullfile(analysis_out_dir, char(out_base + "_poses.csv"));
pair_csv_out = fullfile(analysis_out_dir, char(out_base + "_pairs.csv"));
summary_txt_out = fullfile(analysis_out_dir, char(out_base + ".txt"));
mat_out = fullfile(processed_dir, char(out_base + ".mat"));

writetable(run_tbl, run_csv_out);
writetable(pose_tbl, pose_csv_out);
writetable(pair_tbl, pair_csv_out);

phase11_operational_result = struct();
phase11_operational_result.sensor_id = sensor_id;
phase11_operational_result.calibration_mat_relpath = calibration_mat_relpath;
phase11_operational_result.convention_json_relpath = convention_json_relpath;
phase11_operational_result.dataset_manifest_relpath = dataset_manifest_relpath;
phase11_operational_result.identity_status = identity_status;
phase11_operational_result.final_decision = final_decision;
phase11_operational_result.promotion_decision = promotion_decision;
phase11_operational_result.pair_axis_match_count = pair_axis_match_count;
phase11_operational_result.pair_sign_opposition_count = pair_sign_opposition_count;
phase11_operational_result.avg_pair_dominance_ratio = avg_pair_dominance_ratio;
phase11_operational_result.mean_expected_axis_global = mean_expected_axis_global;
phase11_operational_result.mean_cross_axis_global = mean_cross_axis_global;
phase11_operational_result.run_csv = make_relpath(run_csv_out, repo_dir);
phase11_operational_result.pose_csv = make_relpath(pose_csv_out, repo_dir);
phase11_operational_result.pair_csv = make_relpath(pair_csv_out, repo_dir);
phase11_operational_result.summary_txt = make_relpath(summary_txt_out, repo_dir);
phase11_operational_result.mat_file = make_relpath(mat_out, repo_dir);

save(mat_out, "phase11_operational_result", "run_tbl", "pose_tbl", "pair_tbl");

fid = fopen(summary_txt_out, "w");
if fid < 0
    error("No fue posible crear resumen phase11: %s", summary_txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/analysis/run_sensorC_phase11_operational_interpretation.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "calibration_mat: %s\n", calibration_mat_relpath);
fprintf(fid, "convention_json: %s\n", convention_json_relpath);
fprintf(fid, "dataset_manifest: %s\n", dataset_manifest_relpath);
fprintf(fid, "identity_status: %s\n", identity_status);
fprintf(fid, "pair_sign_threshold_g: %.4f\n", pair_sign_threshold_g);
fprintf(fid, "pair_dominance_ratio_min: %.4f\n", pair_dominance_ratio_min);
fprintf(fid, "expected_axis_abs_min: %.4f\n", expected_axis_abs_min);
fprintf(fid, "cross_axis_abs_max: %.4f\n", cross_axis_abs_max);
fprintf(fid, "pair_axis_match_count: %d\n", pair_axis_match_count);
fprintf(fid, "pair_sign_opposition_count: %d\n", pair_sign_opposition_count);
fprintf(fid, "avg_pair_dominance_ratio: %.6f\n", avg_pair_dominance_ratio);
fprintf(fid, "mean_expected_axis_global: %.6f\n", mean_expected_axis_global);
fprintf(fid, "mean_cross_axis_global: %.6f\n", mean_cross_axis_global);
fprintf(fid, "final_decision: %s\n", final_decision);
fprintf(fid, "promotion_decision: %s\n", promotion_decision);
fprintf(fid, "run_csv: %s\n", phase11_operational_result.run_csv);
fprintf(fid, "pose_csv: %s\n", phase11_operational_result.pose_csv);
fprintf(fid, "pair_csv: %s\n", phase11_operational_result.pair_csv);
fprintf(fid, "mat_file: %s\n", phase11_operational_result.mat_file);

fprintf("\nPHASE11_OPERATIONAL_INTERPRETATION_OK\n");
fprintf("CONVENTION_JSON: %s\n", convention_json_relpath);
fprintf("IDENTITY_STATUS: %s\n", identity_status);
fprintf("FINAL_DECISION: %s\n", final_decision);
fprintf("PROMOTION_DECISION: %s\n", promotion_decision);
fprintf("RUN_CSV: %s\n", phase11_operational_result.run_csv);
fprintf("POSE_CSV: %s\n", phase11_operational_result.pose_csv);
fprintf("PAIR_CSV: %s\n", phase11_operational_result.pair_csv);

%% Local functions
function val = get_coeff(coeff_tbl, axis_name, col_name)
idx = string(coeff_tbl.axis) == axis_name;
if ~any(idx)
    error("No existe coeficiente para eje %s.", axis_name);
end
val = double(coeff_tbl.(col_name)(idx));
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
    error("Pose con eje invalido: %s", pose_name);
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

function axis_name = idx_to_axis(idx)
axis_labels = ["x","y","z"];
axis_name = axis_labels(idx);
end

function [expected_axis_mean, cross_axis_abs_mean] = axis_alignment_metrics(g_oper_ts, expected_axis, expected_sign)
exp_idx = axis_to_index(expected_axis);
exp_vec = g_oper_ts(:,exp_idx) * expected_sign;
cross_idx = setdiff(1:3, exp_idx);
cross_vec = g_oper_ts(:,cross_idx);

expected_axis_mean = mean(exp_vec);
cross_axis_abs_mean = mean(abs(cross_vec), "all");
end

function cfg = load_json_struct(json_abs)
raw = fileread(json_abs);
cfg = jsondecode(raw);
end

function out = get_nested_string(s, path_cells, default_val)
out = string(default_val);
cur = s;
for i = 1:numel(path_cells)
    key = path_cells{i};
    if ~isstruct(cur) || ~isfield(cur, key)
        return;
    end
    cur = cur.(key);
end
out = string(cur);
end

function rel = make_relpath(abs_path, repo_dir)
rel = strrep(abs_path, [repo_dir filesep], "");
end
