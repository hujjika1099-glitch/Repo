% calibrate_sensorC_static_affine_3x3.m
% Calibracion estatica refinada para sensor_C con modelo affine 3x3:
% g_est = M * (v - b)

%% Configuracion
default_sensor_id = "sensor_C";
default_pose_order = ["pos_x","neg_x","pos_y","neg_y","pos_z","neg_z"];
default_runs_target = [3,3,3,3,5,5];
default_dataset_mode = "from_phase10_calibration"; % from_phase10_calibration | explicit_list | latest_n_per_pose
default_base_simple_calib_relpath = "";

% Fallback de dataset (mismo set de Fase 10)
default_dataset.pos_x = [
    "sensor_C_pos_x_20260321_103048.csv"
    "sensor_C_pos_x_20260321_103224.csv"
    "sensor_C_pos_x_20260321_103405.csv"
];
default_dataset.neg_x = [
    "sensor_C_neg_x_20260321_104116.csv"
    "sensor_C_neg_x_20260321_104255.csv"
    "sensor_C_neg_x_20260321_104434.csv"
];
default_dataset.pos_y = [
    "sensor_C_pos_y_20260321_105150.csv"
    "sensor_C_pos_y_20260321_105330.csv"
    "sensor_C_pos_y_20260321_105508.csv"
];
default_dataset.neg_y = [
    "sensor_C_neg_y_20260321_110157.csv"
    "sensor_C_neg_y_20260321_110339.csv"
    "sensor_C_neg_y_20260321_110521.csv"
];
default_dataset.pos_z = [
    "sensor_C_pos_z_20260321_131713.csv"
    "sensor_C_pos_z_20260321_131840.csv"
    "sensor_C_pos_z_20260321_132019.csv"
    "sensor_C_pos_z_20260321_132204.csv"
    "sensor_C_pos_z_20260321_132349.csv"
];
default_dataset.neg_z = [
    "sensor_C_neg_z_20260321_132804.csv"
    "sensor_C_neg_z_20260321_132949.csv"
    "sensor_C_neg_z_20260321_133129.csv"
    "sensor_C_neg_z_20260321_133305.csv"
    "sensor_C_neg_z_20260321_133454.csv"
];

if exist("sensor_id", "var") && strlength(string(sensor_id)) > 0
    sensor_id = string(sensor_id);
else
    sensor_id = default_sensor_id;
end

if exist("pose_order", "var") && ~isempty(pose_order)
    pose_order = string(pose_order(:))';
else
    pose_order = default_pose_order;
end

if exist("runs_target_by_pose", "var") && ~isempty(runs_target_by_pose)
    runs_target_by_pose = double(runs_target_by_pose(:))';
    if numel(runs_target_by_pose) ~= numel(pose_order)
        error("runs_target_by_pose debe tener el mismo tamano que pose_order.");
    end
else
    runs_target_by_pose = default_runs_target;
end

if exist("dataset_mode", "var") && strlength(string(dataset_mode)) > 0
    dataset_mode = lower(string(dataset_mode));
else
    dataset_mode = default_dataset_mode;
end

if exist("base_simple_calib_relpath", "var") && strlength(string(base_simple_calib_relpath)) > 0
    base_simple_calib_relpath = string(base_simple_calib_relpath);
else
    base_simple_calib_relpath = default_base_simple_calib_relpath;
end

if exist("dataset_csv_by_pose", "var") && isstruct(dataset_csv_by_pose)
    dataset_csv_by_pose = normalize_dataset_struct(dataset_csv_by_pose, pose_order);
else
    dataset_csv_by_pose = normalize_dataset_struct(default_dataset, pose_order);
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

expected_cols = {'seq','t_us','raw_x','raw_y','raw_z','mv_x','mv_y','mv_z'};

%% Reutilizar dataset de Fase 10 por defecto
dataset_source = "manual_default";
ref_simple_calib_mat = "";

if dataset_mode == "from_phase10_calibration"
    if strlength(base_simple_calib_relpath) > 0
        ref_mat_abs = fullfile(repo_dir, char(base_simple_calib_relpath));
    else
        mats = dir(fullfile(processed_dir, char(sensor_id + "_static_calibration_*.mat")));
        if isempty(mats)
            error("No se encontro .mat de calibracion base para reutilizar dataset.");
        end
        [~, idx] = sort([mats.datenum], "ascend");
        mats = mats(idx);
        ref_mat_abs = fullfile(mats(end).folder, mats(end).name);
    end

    loaded = load(ref_mat_abs);
    if ~isfield(loaded, "calibration") || ~isfield(loaded.calibration, "selected_by_pose")
        error("El .mat base no contiene calibration.selected_by_pose.");
    end
    dataset_csv_by_pose = normalize_dataset_struct(loaded.calibration.selected_by_pose, pose_order);
    dataset_source = "phase10_calibration_mat";
    ref_simple_calib_mat = make_relpath(ref_mat_abs, repo_dir);
end

%% Seleccion de dataset
selected_by_pose = struct();
for i = 1:numel(pose_order)
    pose = pose_order(i);
    pose_key = char(pose);
    target_n = runs_target_by_pose(i);

    switch dataset_mode
        case {"from_phase10_calibration","explicit_list"}
            if ~isfield(dataset_csv_by_pose, pose_key)
                error("No existe definicion explicita para pose %s.", pose);
            end
            files = string(dataset_csv_by_pose.(pose_key));
            files = files(strlength(files) > 0);
            if numel(files) ~= target_n
                error("Pose %s requiere %d corridas y se definieron %d.", pose, target_n, numel(files));
            end
        case "latest_n_per_pose"
            pattern = char(sensor_id + "_" + pose + "_*.csv");
            found = dir(fullfile(raw_dir, pattern));
            if numel(found) < target_n
                error("Pose %s no tiene suficientes corridas (%d < %d).", pose, numel(found), target_n);
            end
            [~, order] = sort([found.datenum], "ascend");
            found = found(order);
            found = found((end-target_n+1):end);
            files = string({found.name})';
        otherwise
            error("dataset_mode no soportado: %s", dataset_mode);
    end

    for k = 1:numel(files)
        csv_abs = fullfile(raw_dir, char(files(k)));
        if ~isfile(csv_abs)
            error("CSV no encontrado para pose %s: %s", pose, csv_abs);
        end
    end

    selected_by_pose.(pose_key) = files;
end

%% Construccion de observaciones (medias por corrida)
run_pose = strings(0,1);
run_file = strings(0,1);
samples = zeros(0,1);
duration_s = zeros(0,1);
freq_hz = zeros(0,1);
seq_jumps = zeros(0,1);
mean_raw_x = zeros(0,1);
mean_raw_y = zeros(0,1);
mean_raw_z = zeros(0,1);
mean_mv_x = zeros(0,1);
mean_mv_y = zeros(0,1);
mean_mv_z = zeros(0,1);
target_gx = zeros(0,1);
target_gy = zeros(0,1);
target_gz = zeros(0,1);

for i = 1:numel(pose_order)
    pose = pose_order(i);
    files = selected_by_pose.(char(pose));
    tgt = pose_to_target(pose);

    for k = 1:numel(files)
        csv_path = fullfile(raw_dir, char(files(k)));
        tbl = readtable(csv_path, "Delimiter", ",", "TextType", "string");
        missing_cols = setdiff(expected_cols, tbl.Properties.VariableNames);
        if ~isempty(missing_cols)
            error("CSV sin columnas esperadas (%s): %s", files(k), strjoin(missing_cols, ", "));
        end
        tbl = tbl(:, expected_cols);
        n = height(tbl);
        if n < 2
            error("Corrida con muestras insuficientes: %s", files(k));
        end

        t_us = double(tbl.t_us);
        run_pose(end+1,1) = pose; %#ok<SAGROW>
        run_file(end+1,1) = string(files(k)); %#ok<SAGROW>
        samples(end+1,1) = n; %#ok<SAGROW>
        duration_s(end+1,1) = (t_us(end)-t_us(1)) / 1e6; %#ok<SAGROW>
        freq_hz(end+1,1) = (n-1) / max(duration_s(end), eps); %#ok<SAGROW>
        seq_jumps(end+1,1) = nnz(diff(double(tbl.seq)) ~= 1); %#ok<SAGROW>
        mean_raw_x(end+1,1) = mean(double(tbl.raw_x)); %#ok<SAGROW>
        mean_raw_y(end+1,1) = mean(double(tbl.raw_y)); %#ok<SAGROW>
        mean_raw_z(end+1,1) = mean(double(tbl.raw_z)); %#ok<SAGROW>
        mean_mv_x(end+1,1) = mean(double(tbl.mv_x)); %#ok<SAGROW>
        mean_mv_y(end+1,1) = mean(double(tbl.mv_y)); %#ok<SAGROW>
        mean_mv_z(end+1,1) = mean(double(tbl.mv_z)); %#ok<SAGROW>
        target_gx(end+1,1) = tgt(1); %#ok<SAGROW>
        target_gy(end+1,1) = tgt(2); %#ok<SAGROW>
        target_gz(end+1,1) = tgt(3); %#ok<SAGROW>
    end
end

run_tbl = table(run_pose, run_file, samples, duration_s, freq_hz, seq_jumps, ...
    mean_raw_x, mean_raw_y, mean_raw_z, mean_mv_x, mean_mv_y, mean_mv_z, ...
    target_gx, target_gy, target_gz, ...
    'VariableNames', {'pose','run_file','samples','duration_s','freq_hz','seq_jumps', ...
    'mean_raw_x','mean_raw_y','mean_raw_z','mean_mv_x','mean_mv_y','mean_mv_z', ...
    'target_gx','target_gy','target_gz'});

%% Ajuste affine por minimos cuadrados (mV principal)
G_target = [target_gx, target_gy, target_gz]; % Nx3
V_mv = [mean_mv_x, mean_mv_y, mean_mv_z];     % Nx3
V_raw = [mean_raw_x, mean_raw_y, mean_raw_z]; % Nx3

[M_mv, b_mv, c_mv, B_mv, fit_mv] = solve_affine(V_mv, G_target);
[M_raw, b_raw, c_raw, B_raw, fit_raw] = solve_affine(V_raw, G_target);

%% Tabla de coeficientes
coeff_model = strings(0,1);
coeff_param = strings(0,1);
coeff_value = zeros(0,1);

[coeff_model, coeff_param, coeff_value] = append_affine_coeff(coeff_model, coeff_param, coeff_value, "mv", M_mv, b_mv, c_mv);
[coeff_model, coeff_param, coeff_value] = append_affine_coeff(coeff_model, coeff_param, coeff_value, "raw", M_raw, b_raw, c_raw);

coeff_tbl = table(coeff_model, coeff_param, coeff_value, ...
    'VariableNames', {'model','parameter','value'});

%% Guardado de artefactos
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
base = sensor_id + "_static_affine_3x3_" + stamp;
mat_out = fullfile(processed_dir, char(base + ".mat"));
coeff_csv_out = fullfile(processed_dir, char(base + ".csv"));
run_csv_out = fullfile(analysis_out_dir, char(base + "_runs.csv"));
dataset_csv_out = fullfile(analysis_out_dir, char(base + "_dataset.csv"));
txt_out = fullfile(analysis_out_dir, char(base + ".txt"));

dataset_tbl = build_dataset_table(pose_order, selected_by_pose);
writetable(coeff_tbl, coeff_csv_out);
writetable(run_tbl, run_csv_out);
writetable(dataset_tbl, dataset_csv_out);

affine_model = struct();
affine_model.sensor_id = sensor_id;
affine_model.created_at = string(datetime("now", "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss Z"));
affine_model.dataset_mode = dataset_mode;
affine_model.dataset_source = dataset_source;
affine_model.reference_simple_calibration_mat = ref_simple_calib_mat;
affine_model.pose_order = pose_order;
affine_model.runs_target_by_pose = runs_target_by_pose;
affine_model.selected_by_pose = selected_by_pose;
affine_model.formula_mv = "g_est_mv = M_mv * (v_mv - b_mv)";
affine_model.formula_raw = "g_est_raw = M_raw * (v_raw - b_raw)";
affine_model.mv = struct("M", M_mv, "b", b_mv, "c", c_mv, "B", B_mv, "fit", fit_mv);
affine_model.raw = struct("M", M_raw, "b", b_raw, "c", c_raw, "B", B_raw, "fit", fit_raw);
affine_model.generated_files = struct( ...
    "coeff_csv", make_relpath(coeff_csv_out, repo_dir), ...
    "run_csv", make_relpath(run_csv_out, repo_dir), ...
    "dataset_csv", make_relpath(dataset_csv_out, repo_dir), ...
    "summary_txt", make_relpath(txt_out, repo_dir));

save(mat_out, "affine_model", "coeff_tbl", "run_tbl", "dataset_tbl");

fid = fopen(txt_out, "w");
if fid < 0
    error("No fue posible crear salida affine 3x3: %s", txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/calibration/calibrate_sensorC_static_affine_3x3.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "dataset_mode: %s\n", dataset_mode);
fprintf(fid, "dataset_source: %s\n", dataset_source);
fprintf(fid, "reference_simple_calibration_mat: %s\n", ref_simple_calib_mat);
fprintf(fid, "coeff_mat: %s\n", make_relpath(mat_out, repo_dir));
fprintf(fid, "coeff_csv: %s\n", make_relpath(coeff_csv_out, repo_dir));
fprintf(fid, "run_csv: %s\n", make_relpath(run_csv_out, repo_dir));
fprintf(fid, "dataset_csv: %s\n", make_relpath(dataset_csv_out, repo_dir));
fprintf(fid, "mv_fit_rmse_g: %.9f\n", fit_mv.rmse_overall);
fprintf(fid, "raw_fit_rmse_g: %.9f\n", fit_raw.rmse_overall);
fprintf(fid, "mv_bias: [%.9f %.9f %.9f]\n", b_mv(1), b_mv(2), b_mv(3));
fprintf(fid, "raw_bias: [%.9f %.9f %.9f]\n", b_raw(1), b_raw(2), b_raw(3));

%% Consola
fprintf("\nAFFINE_CALIBRATION_OK\n");
fprintf("SENSOR_ID: %s\n", sensor_id);
fprintf("DATASET_SOURCE: %s\n", dataset_source);
fprintf("REFERENCE_SIMPLE_CALIB_MAT: %s\n", ref_simple_calib_mat);
fprintf("AFFINE_MAT: %s\n", make_relpath(mat_out, repo_dir));
fprintf("AFFINE_CSV: %s\n", make_relpath(coeff_csv_out, repo_dir));
fprintf("RUN_CSV: %s\n", make_relpath(run_csv_out, repo_dir));
fprintf("DATASET_CSV: %s\n", make_relpath(dataset_csv_out, repo_dir));
fprintf("BIAS_MV: [%.6f %.6f %.6f]\n", b_mv(1), b_mv(2), b_mv(3));
fprintf("M_MV_ROW1: [%.6f %.6f %.6f]\n", M_mv(1,1), M_mv(1,2), M_mv(1,3));
fprintf("M_MV_ROW2: [%.6f %.6f %.6f]\n", M_mv(2,1), M_mv(2,2), M_mv(2,3));
fprintf("M_MV_ROW3: [%.6f %.6f %.6f]\n", M_mv(3,1), M_mv(3,2), M_mv(3,3));
fprintf("FIT_RMSE_MV_G: %.9f\n", fit_mv.rmse_overall);

%% Funciones locales
function out = normalize_dataset_struct(in_struct, pose_order)
out = struct();
for i = 1:numel(pose_order)
    key = char(pose_order(i));
    if isfield(in_struct, key)
        out.(key) = string(in_struct.(key));
    else
        out.(key) = strings(0,1);
    end
end
end

function tgt = pose_to_target(pose)
switch pose
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
        error("Pose no soportada: %s", pose);
end
end

function [M, b, c, B, fit] = solve_affine(V, G)
X = [V, ones(size(V,1),1)]; % Nx4
B = X \ G;                  % 4x3
G_hat = X * B;              % Nx3
res = G - G_hat;            % Nx3

M = B(1:3,:).';  % 3x3
c = B(4,:).';    % 3x1
if rcond(M) > 1e-10
    b = -M \ c;
else
    b = -pinv(M) * c;
end

fit = struct();
fit.rmse_x = sqrt(mean(res(:,1).^2));
fit.rmse_y = sqrt(mean(res(:,2).^2));
fit.rmse_z = sqrt(mean(res(:,3).^2));
fit.rmse_overall = sqrt(mean(sum(res.^2, 2)));
end

function [mdl, prm, val] = append_affine_coeff(mdl, prm, val, model_name, M, b, c)
mdl = [mdl; repmat(model_name, 15, 1)];
prm = [prm; ...
    "m11"; "m12"; "m13"; ...
    "m21"; "m22"; "m23"; ...
    "m31"; "m32"; "m33"; ...
    "b1"; "b2"; "b3"; ...
    "c1"; "c2"; "c3"];
val = [val; ...
    M(1,1); M(1,2); M(1,3); ...
    M(2,1); M(2,2); M(2,3); ...
    M(3,1); M(3,2); M(3,3); ...
    b(1); b(2); b(3); ...
    c(1); c(2); c(3)];
end

function tbl = build_dataset_table(pose_order, selected_by_pose)
pose = strings(0,1);
run_file = strings(0,1);
for i = 1:numel(pose_order)
    p = pose_order(i);
    files = selected_by_pose.(char(p));
    pose = [pose; repmat(p, numel(files), 1)]; %#ok<AGROW>
    run_file = [run_file; files(:)]; %#ok<AGROW>
end
tbl = table(pose, run_file);
end

function rel = make_relpath(abs_path, repo_dir)
rel = strrep(abs_path, [repo_dir filesep], "");
end
