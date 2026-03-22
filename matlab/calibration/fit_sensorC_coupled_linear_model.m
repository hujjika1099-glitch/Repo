% fit_sensorC_coupled_linear_model.m
% Ajusta un modelo lineal acoplado en dominio mV:
%   g_est = A * v + c
% con v = [mv_x; mv_y; mv_z].

%% Configuracion
default_sensor_id = "sensor_C";
default_dataset_manifest_relpath = "reports/analysis_outputs/sensor_C_axis_mapping_search_dataset_20260322_121904.csv";
default_expected_pose_order = ["pos_x","neg_x","pos_y","neg_y","pos_z","neg_z"];

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

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
raw_dir = fullfile(repo_dir, "data", "raw", char(sensor_id));
processed_dir = fullfile(repo_dir, "data", "processed");
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
if ~isfolder(processed_dir), mkdir(processed_dir); end
if ~isfolder(analysis_out_dir), mkdir(analysis_out_dir); end

%% Carga de dataset manifest (fijo por fase)
manifest_abs = fullfile(repo_dir, char(dataset_manifest_relpath));
if ~isfile(manifest_abs)
    error("No existe manifest de dataset: %s", manifest_abs);
end

manifest_tbl = readtable(manifest_abs, "Delimiter", ",", "TextType", "string");
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
        error("Manifest no contiene pose requerida: %s", p);
    end
end

%% Lectura de corridas y medias por corrida
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
    target_vec = target_from_pose(pose_i);

    pose(i) = pose_i;
    run_file(i) = file_i;
    samples(i) = n;
    duration_s(i) = (t_us(end) - t_us(1)) / 1e6;
    freq_hz(i) = (n - 1) / max(duration_s(i), eps);
    seq_jumps(i) = nnz(diff(seq_col) ~= 1);
    mean_mv_x(i) = mean(double(tbl.mv_x));
    mean_mv_y(i) = mean(double(tbl.mv_y));
    mean_mv_z(i) = mean(double(tbl.mv_z));
    target_gx(i) = target_vec(1);
    target_gy(i) = target_vec(2);
    target_gz(i) = target_vec(3);
end

%% Ajuste lineal acoplado: Y = X * B
X = [mean_mv_x, mean_mv_y, mean_mv_z, ones(n_runs,1)]; % n x 4
Y = [target_gx, target_gy, target_gz];                 % n x 3

B = X \ Y; % 4x3
% y_row = [mvx mvy mvz 1] * B
% => g_col = A * v_col + c, con:
A_mv = B(1:3, :)'; % 3x3
c_mv = B(4, :)';   % 3x1

Y_hat = X * B;
res = Y_hat - Y;
rmse_x = sqrt(mean(res(:,1).^2));
rmse_y = sqrt(mean(res(:,2).^2));
rmse_z = sqrt(mean(res(:,3).^2));
rmse_overall = sqrt(mean(res(:).^2));

% Forma equivalente: g = M * (v - b)
M_mv = A_mv;
rcond_A = rcond(A_mv);
cond_A = cond(A_mv);
is_invertible = rcond_A > 1e-10;

if is_invertible
    b_mv = -A_mv \ c_mv;
    b_solve_method = "inverse";
else
    b_mv = -pinv(A_mv) * c_mv;
    b_solve_method = "pseudoinverse";
end

%% Metricas por corrida del ajuste
pred_gx = Y_hat(:,1);
pred_gy = Y_hat(:,2);
pred_gz = Y_hat(:,3);
res_x = res(:,1);
res_y = res(:,2);
res_z = res(:,3);
res_norm = sqrt(sum(res.^2, 2));
pred_gnorm = sqrt(pred_gx.^2 + pred_gy.^2 + pred_gz.^2);
pred_abs_gnorm_err = abs(pred_gnorm - 1.0);

runs_fit_tbl = table( ...
    pose, run_file, samples, duration_s, freq_hz, seq_jumps, ...
    mean_mv_x, mean_mv_y, mean_mv_z, ...
    target_gx, target_gy, target_gz, ...
    pred_gx, pred_gy, pred_gz, ...
    res_x, res_y, res_z, res_norm, pred_gnorm, pred_abs_gnorm_err);

%% Metricas por pose del ajuste
pose_name = expected_pose_order(:);
runs_found = zeros(numel(pose_name),1);
seq_jumps_total = zeros(numel(pose_name),1);
freq_mean_hz = zeros(numel(pose_name),1);
mean_res_norm = zeros(numel(pose_name),1);
mean_pred_abs_gnorm_err = zeros(numel(pose_name),1);
mean_target_gx = zeros(numel(pose_name),1);
mean_target_gy = zeros(numel(pose_name),1);
mean_target_gz = zeros(numel(pose_name),1);
mean_pred_gx = zeros(numel(pose_name),1);
mean_pred_gy = zeros(numel(pose_name),1);
mean_pred_gz = zeros(numel(pose_name),1);

for i = 1:numel(pose_name)
    p = pose_name(i);
    s = runs_fit_tbl(runs_fit_tbl.pose == p, :);
    runs_found(i) = height(s);
    seq_jumps_total(i) = sum(s.seq_jumps);
    freq_mean_hz(i) = mean(s.freq_hz);
    mean_res_norm(i) = mean(s.res_norm);
    mean_pred_abs_gnorm_err(i) = mean(s.pred_abs_gnorm_err);
    mean_target_gx(i) = mean(s.target_gx);
    mean_target_gy(i) = mean(s.target_gy);
    mean_target_gz(i) = mean(s.target_gz);
    mean_pred_gx(i) = mean(s.pred_gx);
    mean_pred_gy(i) = mean(s.pred_gy);
    mean_pred_gz(i) = mean(s.pred_gz);
end

pose_fit_tbl = table( ...
    pose_name, runs_found, seq_jumps_total, freq_mean_hz, ...
    mean_res_norm, mean_pred_abs_gnorm_err, ...
    mean_target_gx, mean_target_gy, mean_target_gz, ...
    mean_pred_gx, mean_pred_gy, mean_pred_gz, ...
    'VariableNames', {'pose','runs_found','seq_jumps_total','freq_mean_hz', ...
    'mean_res_norm','mean_pred_abs_gnorm_err', ...
    'mean_target_gx','mean_target_gy','mean_target_gz', ...
    'mean_pred_gx','mean_pred_gy','mean_pred_gz'});

%% Artefactos de salida
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
coeff_base = sensor_id + "_coupled_linear_model_" + stamp;

coeff_csv_out = fullfile(processed_dir, char(coeff_base + ".csv"));
coeff_mat_out = fullfile(processed_dir, char(coeff_base + ".mat"));
runs_csv_out = fullfile(analysis_out_dir, char(coeff_base + "_runs.csv"));
pose_csv_out = fullfile(analysis_out_dir, char(coeff_base + "_poses.csv"));
summary_txt_out = fullfile(analysis_out_dir, char(coeff_base + ".txt"));
manifest_out = fullfile(analysis_out_dir, char(sensor_id + "_coupled_model_dataset_" + stamp + ".csv"));

writetable(manifest_tbl(:, {'pose','run_file'}), manifest_out);
writetable(runs_fit_tbl, runs_csv_out);
writetable(pose_fit_tbl, pose_csv_out);

coeff_name = strings(0,1);
coeff_value = zeros(0,1);
for r = 1:3
    for c = 1:3
        coeff_name(end+1,1) = "A_mv_" + r + "_" + c; %#ok<SAGROW>
        coeff_value(end+1,1) = A_mv(r,c); %#ok<SAGROW>
    end
end
for r = 1:3
    coeff_name(end+1,1) = "c_mv_" + r; %#ok<SAGROW>
    coeff_value(end+1,1) = c_mv(r); %#ok<SAGROW>
end
for r = 1:3
    for c = 1:3
        coeff_name(end+1,1) = "M_mv_" + r + "_" + c; %#ok<SAGROW>
        coeff_value(end+1,1) = M_mv(r,c); %#ok<SAGROW>
    end
end
for r = 1:3
    coeff_name(end+1,1) = "b_mv_" + r; %#ok<SAGROW>
    coeff_value(end+1,1) = b_mv(r); %#ok<SAGROW>
end
coeff_name(end+1,1) = "rmse_x"; coeff_value(end+1,1) = rmse_x;
coeff_name(end+1,1) = "rmse_y"; coeff_value(end+1,1) = rmse_y;
coeff_name(end+1,1) = "rmse_z"; coeff_value(end+1,1) = rmse_z;
coeff_name(end+1,1) = "rmse_overall"; coeff_value(end+1,1) = rmse_overall;
coeff_name(end+1,1) = "cond_A"; coeff_value(end+1,1) = cond_A;
coeff_name(end+1,1) = "rcond_A"; coeff_value(end+1,1) = rcond_A;

coeff_tbl = table(coeff_name, coeff_value, 'VariableNames', {'parameter','value'});
writetable(coeff_tbl, coeff_csv_out);

model = struct();
model.sensor_id = sensor_id;
model.created_at = string(datetime("now", "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss Z"));
model.dataset_manifest_relpath = make_relpath(manifest_out, repo_dir);
model.dataset_manifest_source_relpath = make_relpath(manifest_abs, repo_dir);
model.expected_pose_order = expected_pose_order;
model.A_mv = A_mv;
model.c_mv = c_mv;
model.M_mv = M_mv;
model.b_mv = b_mv;
model.b_solve_method = b_solve_method;
model.is_invertible = is_invertible;
model.cond_A = cond_A;
model.rcond_A = rcond_A;
model.rmse_x = rmse_x;
model.rmse_y = rmse_y;
model.rmse_z = rmse_z;
model.rmse_overall = rmse_overall;
model.total_seq_jumps = sum(seq_jumps);
model.generated_files = struct( ...
    "coeff_csv", make_relpath(coeff_csv_out, repo_dir), ...
    "coeff_mat", make_relpath(coeff_mat_out, repo_dir), ...
    "runs_csv", make_relpath(runs_csv_out, repo_dir), ...
    "poses_csv", make_relpath(pose_csv_out, repo_dir), ...
    "summary_txt", make_relpath(summary_txt_out, repo_dir), ...
    "dataset_manifest", make_relpath(manifest_out, repo_dir));

save(coeff_mat_out, "model", "runs_fit_tbl", "pose_fit_tbl");

fid = fopen(summary_txt_out, "w");
if fid < 0
    error("No fue posible escribir resumen: %s", summary_txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/calibration/fit_sensorC_coupled_linear_model.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "dataset_manifest_source: %s\n", make_relpath(manifest_abs, repo_dir));
fprintf(fid, "dataset_manifest_used: %s\n", make_relpath(manifest_out, repo_dir));
fprintf(fid, "model_form_main: g_est = A * v + c\n");
fprintf(fid, "model_form_equiv: g_est = M * (v - b)\n");
fprintf(fid, "b_solve_method: %s\n", b_solve_method);
fprintf(fid, "is_invertible: %s\n", string(is_invertible));
fprintf(fid, "cond_A: %.9f\n", cond_A);
fprintf(fid, "rcond_A: %.9f\n", rcond_A);
fprintf(fid, "rmse_x: %.9f\n", rmse_x);
fprintf(fid, "rmse_y: %.9f\n", rmse_y);
fprintf(fid, "rmse_z: %.9f\n", rmse_z);
fprintf(fid, "rmse_overall: %.9f\n", rmse_overall);
fprintf(fid, "total_seq_jumps: %d\n", sum(seq_jumps));
fprintf(fid, "coeff_csv: %s\n", make_relpath(coeff_csv_out, repo_dir));
fprintf(fid, "coeff_mat: %s\n", make_relpath(coeff_mat_out, repo_dir));
fprintf(fid, "runs_csv: %s\n", make_relpath(runs_csv_out, repo_dir));
fprintf(fid, "poses_csv: %s\n", make_relpath(pose_csv_out, repo_dir));

fprintf("\nCOUPLED_LINEAR_FIT_OK\n");
fprintf("DATASET_MANIFEST: %s\n", make_relpath(manifest_out, repo_dir));
fprintf("MODEL_CSV: %s\n", make_relpath(coeff_csv_out, repo_dir));
fprintf("MODEL_MAT: %s\n", make_relpath(coeff_mat_out, repo_dir));
fprintf("RUNS_CSV: %s\n", make_relpath(runs_csv_out, repo_dir));
fprintf("POSES_CSV: %s\n", make_relpath(pose_csv_out, repo_dir));
fprintf("SUMMARY_TXT: %s\n", make_relpath(summary_txt_out, repo_dir));
fprintf("RMSE_OVERALL: %.9f\n", rmse_overall);

%% Funciones locales
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

function rel = make_relpath(abs_path, repo_dir)
rel = strrep(abs_path, [repo_dir filesep], "");
end
