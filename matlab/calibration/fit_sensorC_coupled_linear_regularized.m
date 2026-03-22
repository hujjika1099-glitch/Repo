% fit_sensorC_coupled_linear_regularized.m
% Ajusta candidatos de modelo acoplado lineal regularizado en dominio mV:
%   g = A * v + c
% con ridge/Tikhonov sobre coeficientes (sin penalizar intercepto).

%% Configuracion
default_sensor_id = "sensor_C";
default_dataset_manifest_relpath = "reports/analysis_outputs/sensor_C_coupled_model_dataset_20260322_131829.csv";
default_expected_pose_order = ["pos_x","neg_x","pos_y","neg_y","pos_z","neg_z"];
default_lambdas = [0, 1e-4, 1e-3, 1e-2, 1e-1, 1, 10];

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

if exist("lambdas", "var") && ~isempty(lambdas)
    lambdas = double(lambdas(:))';
else
    lambdas = double(default_lambdas);
end
lambdas = unique(lambdas);
lambdas = sort(lambdas);
if any(lambdas < 0)
    error("La regularizacion lambda debe ser no negativa.");
end

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
raw_dir = fullfile(repo_dir, "data", "raw", char(sensor_id));
processed_dir = fullfile(repo_dir, "data", "processed");
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
if ~isfolder(processed_dir), mkdir(processed_dir); end
if ~isfolder(analysis_out_dir), mkdir(analysis_out_dir); end

%% Carga de manifest fijo de fase
manifest_source_abs = fullfile(repo_dir, char(dataset_manifest_relpath));
if ~isfile(manifest_source_abs)
    error("No existe manifest base: %s", manifest_source_abs);
end

manifest_tbl = readtable(manifest_source_abs, "Delimiter", ",", "TextType", "string");
required_manifest_cols = {'pose','run_file'};
missing_manifest_cols = setdiff(required_manifest_cols, manifest_tbl.Properties.VariableNames);
if ~isempty(missing_manifest_cols)
    error("Manifest sin columnas requeridas: %s", strjoin(missing_manifest_cols, ", "));
end
manifest_tbl = manifest_tbl(:, required_manifest_cols);
manifest_tbl.pose = string(manifest_tbl.pose);
manifest_tbl.run_file = string(manifest_tbl.run_file);

for i = 1:numel(expected_pose_order)
    p = expected_pose_order(i);
    if ~any(manifest_tbl.pose == p)
        error("Manifest no contiene pose requerida: %s", p);
    end
end

%% Manifest trazable de esta fase (sin cambiar dataset)
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
manifest_phase_abs = fullfile(analysis_out_dir, ...
    char(sensor_id + "_coupled_robust_dataset_" + stamp + ".csv"));
writetable(manifest_tbl, manifest_phase_abs);

%% Construccion de dataset por corrida (medias + metadatos)
runs_tbl = build_runs_table(manifest_tbl, raw_dir);
n_runs = height(runs_tbl);

X = [runs_tbl.mean_mv_x, runs_tbl.mean_mv_y, runs_tbl.mean_mv_z, ones(n_runs, 1)];
Y = [runs_tbl.target_gx, runs_tbl.target_gy, runs_tbl.target_gz];

%% Ajuste de candidatos regularizados
n_l = numel(lambdas);

lambda_col = zeros(n_l,1);
rmse_x_col = zeros(n_l,1);
rmse_y_col = zeros(n_l,1);
rmse_z_col = zeros(n_l,1);
rmse_overall_col = zeros(n_l,1);
cond_A_col = zeros(n_l,1);
rcond_A_col = zeros(n_l,1);
is_invertible_col = false(n_l,1);
b_solve_method_col = strings(n_l,1);
seq_jumps_total_col = zeros(n_l,1);
mean_expected_axis_col = zeros(n_l,1);
mean_cross_axis_col = zeros(n_l,1);
mean_abs_gnorm_err_col = zeros(n_l,1);
max_abs_gnorm_err_col = zeros(n_l,1);
mean_residual_by_pose = zeros(n_l, numel(expected_pose_order));

candidates(n_l,1) = struct( ...
    "lambda", 0, ...
    "A_mv", zeros(3), ...
    "c_mv", zeros(3,1), ...
    "M_mv", zeros(3), ...
    "b_mv", zeros(3,1), ...
    "is_invertible", false, ...
    "cond_A", NaN, ...
    "rcond_A", NaN, ...
    "b_solve_method", "", ...
    "rmse_x", NaN, ...
    "rmse_y", NaN, ...
    "rmse_z", NaN, ...
    "rmse_overall", NaN);

for i = 1:n_l
    lam = lambdas(i);
    [A_mv, c_mv, M_mv, b_mv, is_inv, cond_A, rcond_A, b_solve_method, B] = ...
        fit_coupled_ridge(X, Y, lam);

    Y_hat = X * B;
    res = Y_hat - Y;
    rmse_x = sqrt(mean(res(:,1).^2));
    rmse_y = sqrt(mean(res(:,2).^2));
    rmse_z = sqrt(mean(res(:,3).^2));
    rmse_overall = sqrt(mean(res(:).^2));

    gnorm = sqrt(sum(Y_hat.^2, 2));
    abs_gnorm_err = abs(gnorm - 1.0);

    exp_axis_mean = zeros(n_runs,1);
    cross_axis_abs = zeros(n_runs,1);
    res_norm = sqrt(sum(res.^2, 2));
    for r = 1:n_runs
        [exp_axis, exp_sign] = expected_from_pose(runs_tbl.pose(r));
        exp_idx = axis_to_index(exp_axis);
        cross_idx = setdiff(1:3, exp_idx);
        exp_axis_mean(r) = Y_hat(r, exp_idx) * exp_sign;
        cross_axis_abs(r) = mean(abs(Y_hat(r, cross_idx)));
    end

    lambda_col(i) = lam;
    rmse_x_col(i) = rmse_x;
    rmse_y_col(i) = rmse_y;
    rmse_z_col(i) = rmse_z;
    rmse_overall_col(i) = rmse_overall;
    cond_A_col(i) = cond_A;
    rcond_A_col(i) = rcond_A;
    is_invertible_col(i) = is_inv;
    b_solve_method_col(i) = b_solve_method;
    seq_jumps_total_col(i) = sum(runs_tbl.seq_jumps);
    mean_expected_axis_col(i) = mean(exp_axis_mean);
    mean_cross_axis_col(i) = mean(cross_axis_abs);
    mean_abs_gnorm_err_col(i) = mean(abs_gnorm_err);
    max_abs_gnorm_err_col(i) = max(abs_gnorm_err);

    for p = 1:numel(expected_pose_order)
        pose_name = expected_pose_order(p);
        idx = runs_tbl.pose == pose_name;
        mean_residual_by_pose(i,p) = mean(res_norm(idx));
    end

    candidates(i).lambda = lam;
    candidates(i).A_mv = A_mv;
    candidates(i).c_mv = c_mv;
    candidates(i).M_mv = M_mv;
    candidates(i).b_mv = b_mv;
    candidates(i).is_invertible = is_inv;
    candidates(i).cond_A = cond_A;
    candidates(i).rcond_A = rcond_A;
    candidates(i).b_solve_method = b_solve_method;
    candidates(i).rmse_x = rmse_x;
    candidates(i).rmse_y = rmse_y;
    candidates(i).rmse_z = rmse_z;
    candidates(i).rmse_overall = rmse_overall;
end

candidates_tbl = table( ...
    lambda_col, rmse_x_col, rmse_y_col, rmse_z_col, rmse_overall_col, ...
    cond_A_col, rcond_A_col, is_invertible_col, b_solve_method_col, ...
    seq_jumps_total_col, mean_expected_axis_col, mean_cross_axis_col, ...
    mean_abs_gnorm_err_col, max_abs_gnorm_err_col, ...
    'VariableNames', { ...
    'lambda', ...
    'rmse_x', 'rmse_y', 'rmse_z', 'rmse_overall', ...
    'cond_A', 'rcond_A', 'is_invertible', 'b_solve_method', ...
    'seq_jumps_total', 'mean_expected_axis', 'mean_cross_axis_abs', ...
    'mean_abs_gnorm_err', 'max_abs_gnorm_err'});

for p = 1:numel(expected_pose_order)
    col_name = matlab.lang.makeValidName("mean_residual_norm_" + expected_pose_order(p));
    candidates_tbl.(col_name) = mean_residual_by_pose(:, p);
end

%% Salidas
base = sensor_id + "_coupled_regularized_candidates_" + stamp;
candidates_csv_out = fullfile(analysis_out_dir, char(base + ".csv"));
candidates_mat_out = fullfile(analysis_out_dir, char(base + ".mat"));
summary_txt_out = fullfile(analysis_out_dir, char(base + ".txt"));

writetable(candidates_tbl, candidates_csv_out);

fit_result = struct();
fit_result.sensor_id = sensor_id;
fit_result.created_at = string(datetime("now", "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss Z"));
fit_result.dataset_manifest_source_relpath = make_relpath(manifest_source_abs, repo_dir);
fit_result.dataset_manifest_phase_relpath = make_relpath(manifest_phase_abs, repo_dir);
fit_result.expected_pose_order = expected_pose_order;
fit_result.lambdas = lambdas;
fit_result.runs_tbl = runs_tbl;
fit_result.candidates = candidates;
fit_result.generated_files = struct( ...
    "manifest_phase", make_relpath(manifest_phase_abs, repo_dir), ...
    "candidates_csv", make_relpath(candidates_csv_out, repo_dir), ...
    "summary_txt", make_relpath(summary_txt_out, repo_dir));

save(candidates_mat_out, "fit_result", "candidates_tbl");

fid = fopen(summary_txt_out, "w");
if fid < 0
    error("No fue posible escribir resumen: %s", summary_txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/calibration/fit_sensorC_coupled_linear_regularized.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "dataset_manifest_source: %s\n", make_relpath(manifest_source_abs, repo_dir));
fprintf(fid, "dataset_manifest_phase: %s\n", make_relpath(manifest_phase_abs, repo_dir));
fprintf(fid, "lambdas: %s\n", strjoin(string(lambdas), ", "));
fprintf(fid, "n_runs: %d\n", n_runs);
fprintf(fid, "candidates_csv: %s\n", make_relpath(candidates_csv_out, repo_dir));
fprintf(fid, "candidates_mat: %s\n", make_relpath(candidates_mat_out, repo_dir));
fprintf(fid, "summary_txt: %s\n", make_relpath(summary_txt_out, repo_dir));

[best_rmse, idx_best_rmse] = min(candidates_tbl.rmse_overall);
fprintf(fid, "best_training_lambda_by_rmse: %.10g\n", candidates_tbl.lambda(idx_best_rmse));
fprintf(fid, "best_training_rmse_overall: %.9f\n", best_rmse);

fprintf("\nCOUPLED_REGULARIZED_FIT_OK\n");
fprintf("DATASET_MANIFEST_PHASE: %s\n", make_relpath(manifest_phase_abs, repo_dir));
fprintf("CANDIDATES_CSV: %s\n", make_relpath(candidates_csv_out, repo_dir));
fprintf("CANDIDATES_MAT: %s\n", make_relpath(candidates_mat_out, repo_dir));
fprintf("SUMMARY_TXT: %s\n", make_relpath(summary_txt_out, repo_dir));

%% Funciones locales
function runs_tbl = build_runs_table(manifest_tbl, raw_dir)
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
target_gx = zeros(n_runs,1);
target_gy = zeros(n_runs,1);
target_gz = zeros(n_runs,1);

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
    tgt = target_from_pose(pose_i);

    pose(i) = pose_i;
    run_file(i) = file_i;
    samples(i) = n;
    duration_s(i) = (t_us(end) - t_us(1)) / 1e6;
    freq_hz(i) = (n - 1) / max(duration_s(i), eps);
    seq_jumps(i) = nnz(diff(seq_col) ~= 1);
    mean_mv_x(i) = mean(double(tbl.mv_x));
    mean_mv_y(i) = mean(double(tbl.mv_y));
    mean_mv_z(i) = mean(double(tbl.mv_z));
    target_gx(i) = tgt(1);
    target_gy(i) = tgt(2);
    target_gz(i) = tgt(3);
end

runs_tbl = table( ...
    pose, run_file, samples, duration_s, freq_hz, seq_jumps, ...
    mean_mv_x, mean_mv_y, mean_mv_z, target_gx, target_gy, target_gz);
end

function [A_mv, c_mv, M_mv, b_mv, is_inv, cond_A, rcond_A, b_solve_method, B] = fit_coupled_ridge(X, Y, lambda)
R = diag([1, 1, 1, 0]);
lhs = (X' * X) + lambda * R;
rhs = (X' * Y);

if lambda == 0
    B = X \ Y;
else
    if rcond(lhs) > 1e-12
        B = lhs \ rhs;
    else
        B = pinv(lhs) * rhs;
    end
end

A_mv = B(1:3, :)';
c_mv = B(4, :)';
M_mv = A_mv;
rcond_A = rcond(A_mv);
cond_A = cond(A_mv);
is_inv = rcond_A > 1e-10;
if is_inv
    b_mv = -A_mv \ c_mv;
    b_solve_method = "inverse";
else
    b_mv = -pinv(A_mv) * c_mv;
    b_solve_method = "pseudoinverse";
end
end

function tgt = target_from_pose(pose_name)
switch pose_name
    case "pos_x"
        tgt = [1, 0, 0];
    case "neg_x"
        tgt = [-1, 0, 0];
    case "pos_y"
        tgt = [0, 1, 0];
    case "neg_y"
        tgt = [0, -1, 0];
    case "pos_z"
        tgt = [0, 0, 1];
    case "neg_z"
        tgt = [0, 0, -1];
    otherwise
        error("Pose no reconocida: %s", pose_name);
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

function rel = make_relpath(abs_path, repo_dir)
rel = strrep(abs_path, [repo_dir filesep], "");
end
