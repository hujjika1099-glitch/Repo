% validate_sensorC_static_calibration.m
% Validacion cruzada de calibracion estatica 6 poses para sensor_C.

%% Configuracion
default_sensor_id = "sensor_C";

% Umbrales operativos para decision automatica.
norm_mean_abs_err_max = 0.20;
norm_max_abs_err_max = 0.45;
expected_axis_abs_min = 0.75;
cross_axis_abs_max = 0.45;

if exist("sensor_id", "var") && strlength(string(sensor_id)) > 0
    sensor_id = string(sensor_id);
else
    sensor_id = default_sensor_id;
end

if exist("calibration_mat_relpath", "var") && strlength(string(calibration_mat_relpath)) > 0
    calibration_mat_relpath = string(calibration_mat_relpath);
else
    calibration_mat_relpath = "";
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

%% Carga de calibracion
if strlength(calibration_mat_relpath) > 0
    calibration_mat_path = fullfile(repo_dir, char(calibration_mat_relpath));
else
    mats = dir(fullfile(processed_dir, char(sensor_id + "_static_calibration_*.mat")));
    if isempty(mats)
        error("No se encontro archivo .mat de calibracion en %s", processed_dir);
    end
    [~, idx] = sort([mats.datenum], "ascend");
    mats = mats(idx);
    calibration_mat_path = fullfile(mats(end).folder, mats(end).name);
end

loaded = load(calibration_mat_path);
if ~isfield(loaded, "calibration")
    error("El archivo de calibracion no contiene la variable 'calibration'.");
end
calibration = loaded.calibration;

if ~isfield(calibration, "selected_by_pose")
    error("La calibracion no contiene dataset seleccionado por pose.");
end
if ~isfield(calibration, "coefficients")
    error("La calibracion no contiene tabla de coeficientes.");
end

coeff_tbl = calibration.coefficients;
required_coeff_cols = ["axis","offset_raw","sens_raw_per_g","offset_mv","sens_mv_per_g"];
if ~all(ismember(required_coeff_cols, string(coeff_tbl.Properties.VariableNames)))
    error("Tabla de coeficientes incompleta en archivo .mat.");
end

pose_order = string(calibration.pose_order(:))';
selected_by_pose = calibration.selected_by_pose;

offset_x_mv = get_coeff(coeff_tbl, "x", "offset_mv");
offset_y_mv = get_coeff(coeff_tbl, "y", "offset_mv");
offset_z_mv = get_coeff(coeff_tbl, "z", "offset_mv");
sens_x_mv = get_coeff(coeff_tbl, "x", "sens_mv_per_g");
sens_y_mv = get_coeff(coeff_tbl, "y", "sens_mv_per_g");
sens_z_mv = get_coeff(coeff_tbl, "z", "sens_mv_per_g");

offset_x_raw = get_coeff(coeff_tbl, "x", "offset_raw");
offset_y_raw = get_coeff(coeff_tbl, "y", "offset_raw");
offset_z_raw = get_coeff(coeff_tbl, "z", "offset_raw");
sens_x_raw = get_coeff(coeff_tbl, "x", "sens_raw_per_g");
sens_y_raw = get_coeff(coeff_tbl, "y", "sens_raw_per_g");
sens_z_raw = get_coeff(coeff_tbl, "z", "sens_raw_per_g");

if any(abs([sens_x_mv sens_y_mv sens_z_mv sens_x_raw sens_y_raw sens_z_raw]) < eps)
    error("Sensibilidades nulas en el modelo cargado.");
end

expected_cols = {'seq','t_us','raw_x','raw_y','raw_z','mv_x','mv_y','mv_z'};

%% Validacion por corrida
pose = strings(0,1);
run_file = strings(0,1);
samples = zeros(0,1);
duration_s = zeros(0,1);
freq_hz = zeros(0,1);
seq_jumps = zeros(0,1);
expected_axis = strings(0,1);
expected_sign = zeros(0,1);

mean_gx_mv = zeros(0,1);
mean_gy_mv = zeros(0,1);
mean_gz_mv = zeros(0,1);
mean_gnorm_mv = zeros(0,1);
mean_abs_gnorm_err_mv = zeros(0,1);
max_abs_gnorm_err_mv = zeros(0,1);
expected_axis_mean_mv = zeros(0,1);
cross_axis_abs_mean_mv = zeros(0,1);

mean_gx_raw = zeros(0,1);
mean_gy_raw = zeros(0,1);
mean_gz_raw = zeros(0,1);
mean_gnorm_raw = zeros(0,1);
mean_abs_gnorm_err_raw = zeros(0,1);
max_abs_gnorm_err_raw = zeros(0,1);
expected_axis_mean_raw = zeros(0,1);
cross_axis_abs_mean_raw = zeros(0,1);

for i = 1:numel(pose_order)
    p = pose_order(i);
    pose_key = char(p);
    if ~isfield(selected_by_pose, pose_key)
        error("Pose %s no existe en dataset seleccionado.", p);
    end
    files = string(selected_by_pose.(pose_key));
    files = files(strlength(files) > 0);
    if isempty(files)
        error("Pose %s no tiene archivos en dataset seleccionado.", p);
    end

    [exp_axis, exp_sign] = expected_from_pose(p);

    for k = 1:numel(files)
        csv_path = fullfile(raw_dir, char(files(k)));
        if ~isfile(csv_path)
            error("CSV del dataset no encontrado: %s", csv_path);
        end
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

        raw_x = double(tbl.raw_x);
        raw_y = double(tbl.raw_y);
        raw_z = double(tbl.raw_z);
        mv_x = double(tbl.mv_x);
        mv_y = double(tbl.mv_y);
        mv_z = double(tbl.mv_z);
        t_us = double(tbl.t_us);

        gx_mv = (mv_x - offset_x_mv) ./ sens_x_mv;
        gy_mv = (mv_y - offset_y_mv) ./ sens_y_mv;
        gz_mv = (mv_z - offset_z_mv) ./ sens_z_mv;
        gnorm_mv = sqrt(gx_mv.^2 + gy_mv.^2 + gz_mv.^2);
        gerr_mv = abs(gnorm_mv - 1.0);

        gx_raw = (raw_x - offset_x_raw) ./ sens_x_raw;
        gy_raw = (raw_y - offset_y_raw) ./ sens_y_raw;
        gz_raw = (raw_z - offset_z_raw) ./ sens_z_raw;
        gnorm_raw = sqrt(gx_raw.^2 + gy_raw.^2 + gz_raw.^2);
        gerr_raw = abs(gnorm_raw - 1.0);

        pose(end+1,1) = p; %#ok<SAGROW>
        run_file(end+1,1) = string(files(k)); %#ok<SAGROW>
        samples(end+1,1) = n; %#ok<SAGROW>
        duration_s(end+1,1) = (t_us(end) - t_us(1)) / 1e6; %#ok<SAGROW>
        freq_hz(end+1,1) = (n - 1) / max(duration_s(end), eps); %#ok<SAGROW>
        seq_jumps(end+1,1) = nnz(diff(double(tbl.seq)) ~= 1); %#ok<SAGROW>
        expected_axis(end+1,1) = exp_axis; %#ok<SAGROW>
        expected_sign(end+1,1) = exp_sign; %#ok<SAGROW>

        mean_gx_mv(end+1,1) = mean(gx_mv); %#ok<SAGROW>
        mean_gy_mv(end+1,1) = mean(gy_mv); %#ok<SAGROW>
        mean_gz_mv(end+1,1) = mean(gz_mv); %#ok<SAGROW>
        mean_gnorm_mv(end+1,1) = mean(gnorm_mv); %#ok<SAGROW>
        mean_abs_gnorm_err_mv(end+1,1) = mean(gerr_mv); %#ok<SAGROW>
        max_abs_gnorm_err_mv(end+1,1) = max(gerr_mv); %#ok<SAGROW>

        [exp_axis_mean_mv, cross_abs_mv] = axis_alignment_metrics(gx_mv, gy_mv, gz_mv, exp_axis, exp_sign);
        expected_axis_mean_mv(end+1,1) = exp_axis_mean_mv; %#ok<SAGROW>
        cross_axis_abs_mean_mv(end+1,1) = cross_abs_mv; %#ok<SAGROW>

        mean_gx_raw(end+1,1) = mean(gx_raw); %#ok<SAGROW>
        mean_gy_raw(end+1,1) = mean(gy_raw); %#ok<SAGROW>
        mean_gz_raw(end+1,1) = mean(gz_raw); %#ok<SAGROW>
        mean_gnorm_raw(end+1,1) = mean(gnorm_raw); %#ok<SAGROW>
        mean_abs_gnorm_err_raw(end+1,1) = mean(gerr_raw); %#ok<SAGROW>
        max_abs_gnorm_err_raw(end+1,1) = max(gerr_raw); %#ok<SAGROW>

        [exp_axis_mean_raw, cross_abs_raw] = axis_alignment_metrics(gx_raw, gy_raw, gz_raw, exp_axis, exp_sign);
        expected_axis_mean_raw(end+1,1) = exp_axis_mean_raw; %#ok<SAGROW>
        cross_axis_abs_mean_raw(end+1,1) = cross_abs_raw; %#ok<SAGROW>
    end
end

run_validation_tbl = table( ...
    pose, run_file, samples, duration_s, freq_hz, seq_jumps, expected_axis, expected_sign, ...
    mean_gx_mv, mean_gy_mv, mean_gz_mv, mean_gnorm_mv, mean_abs_gnorm_err_mv, max_abs_gnorm_err_mv, expected_axis_mean_mv, cross_axis_abs_mean_mv, ...
    mean_gx_raw, mean_gy_raw, mean_gz_raw, mean_gnorm_raw, mean_abs_gnorm_err_raw, max_abs_gnorm_err_raw, expected_axis_mean_raw, cross_axis_abs_mean_raw, ...
    'VariableNames', {'pose','run_file','samples','duration_s','freq_hz','seq_jumps','expected_axis','expected_sign', ...
    'mean_gx_mv','mean_gy_mv','mean_gz_mv','mean_gnorm_mv','mean_abs_gnorm_err_mv','max_abs_gnorm_err_mv','expected_axis_mean_mv','cross_axis_abs_mean_mv', ...
    'mean_gx_raw','mean_gy_raw','mean_gz_raw','mean_gnorm_raw','mean_abs_gnorm_err_raw','max_abs_gnorm_err_raw','expected_axis_mean_raw','cross_axis_abs_mean_raw'});

%% Resumen por pose (modelo mV principal)
pose_name = pose_order(:);
runs_found = zeros(numel(pose_order),1);
freq_mean_hz = zeros(numel(pose_order),1);
seq_jumps_total = zeros(numel(pose_order),1);
mean_gx_pose = zeros(numel(pose_order),1);
mean_gy_pose = zeros(numel(pose_order),1);
mean_gz_pose = zeros(numel(pose_order),1);
mean_gnorm_pose = zeros(numel(pose_order),1);
mean_abs_gnorm_err_pose = zeros(numel(pose_order),1);
max_abs_gnorm_err_pose = zeros(numel(pose_order),1);
mean_expected_axis_pose = zeros(numel(pose_order),1);
mean_cross_axis_abs_pose = zeros(numel(pose_order),1);

for i = 1:numel(pose_order)
    p = pose_order(i);
    s = run_validation_tbl(run_validation_tbl.pose == p, :);
    runs_found(i) = height(s);
    freq_mean_hz(i) = mean(s.freq_hz);
    seq_jumps_total(i) = sum(s.seq_jumps);
    mean_gx_pose(i) = mean(s.mean_gx_mv);
    mean_gy_pose(i) = mean(s.mean_gy_mv);
    mean_gz_pose(i) = mean(s.mean_gz_mv);
    mean_gnorm_pose(i) = mean(s.mean_gnorm_mv);
    mean_abs_gnorm_err_pose(i) = mean(s.mean_abs_gnorm_err_mv);
    max_abs_gnorm_err_pose(i) = max(s.max_abs_gnorm_err_mv);
    mean_expected_axis_pose(i) = mean(s.expected_axis_mean_mv);
    mean_cross_axis_abs_pose(i) = mean(s.cross_axis_abs_mean_mv);
end

pose_validation_tbl = table( ...
    pose_name, runs_found, freq_mean_hz, seq_jumps_total, ...
    mean_gx_pose, mean_gy_pose, mean_gz_pose, ...
    mean_gnorm_pose, ...
    mean_expected_axis_pose, mean_cross_axis_abs_pose, ...
    mean_abs_gnorm_err_pose, max_abs_gnorm_err_pose, ...
    'VariableNames', {'pose','runs_found','freq_mean_hz','seq_jumps_total', ...
    'mean_gx','mean_gy','mean_gz','mean_gnorm','mean_expected_axis','mean_cross_axis_abs', ...
    'mean_abs_gnorm_err','max_abs_gnorm_err'});

%% Decision operativa
seq_ok = all(pose_validation_tbl.seq_jumps_total == 0);
norm_ok = all(pose_validation_tbl.mean_abs_gnorm_err <= norm_mean_abs_err_max) && ...
          all(pose_validation_tbl.max_abs_gnorm_err <= norm_max_abs_err_max);
axis_ok = all(abs(pose_validation_tbl.mean_expected_axis) >= expected_axis_abs_min) && ...
          all(pose_validation_tbl.mean_cross_axis_abs <= cross_axis_abs_max);

if seq_ok && norm_ok && axis_ok
    final_decision = "calibrated_and_validated";
elseif seq_ok
    final_decision = "calibrated_but_review_needed";
else
    final_decision = "blocked";
end

%% Guardado de artefactos
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
base = sensor_id + "_static_validation_" + stamp;
run_csv_out = fullfile(processed_dir, char(base + ".csv"));
pose_csv_out = fullfile(processed_dir, char(base + "_poses.csv"));
txt_out = fullfile(analysis_out_dir, char(base + ".txt"));

writetable(run_validation_tbl, run_csv_out);
writetable(pose_validation_tbl, pose_csv_out);

validation = struct();
validation.sensor_id = sensor_id;
validation.calibration_mat = make_relpath(calibration_mat_path, repo_dir);
validation.created_at = string(datetime("now", "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss Z"));
validation.final_decision = final_decision;
validation.criteria = struct( ...
    "seq_ok", seq_ok, ...
    "norm_ok", norm_ok, ...
    "axis_ok", axis_ok, ...
    "norm_mean_abs_err_max", norm_mean_abs_err_max, ...
    "norm_max_abs_err_max", norm_max_abs_err_max, ...
    "expected_axis_abs_min", expected_axis_abs_min, ...
    "cross_axis_abs_max", cross_axis_abs_max);
validation.generated_files = struct( ...
    "run_csv", make_relpath(run_csv_out, repo_dir), ...
    "pose_csv", make_relpath(pose_csv_out, repo_dir), ...
    "summary_txt", make_relpath(txt_out, repo_dir));

fid = fopen(txt_out, "w");
if fid < 0
    error("No fue posible crear resumen de validacion: %s", txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/analysis/validate_sensorC_static_calibration.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "calibration_mat: %s\n", make_relpath(calibration_mat_path, repo_dir));
fprintf(fid, "run_csv: %s\n", make_relpath(run_csv_out, repo_dir));
fprintf(fid, "pose_csv: %s\n", make_relpath(pose_csv_out, repo_dir));
fprintf(fid, "seq_ok: %s\n", string(seq_ok));
fprintf(fid, "norm_ok: %s\n", string(norm_ok));
fprintf(fid, "axis_ok: %s\n", string(axis_ok));
fprintf(fid, "final_decision: %s\n", final_decision);

%% Consola
fprintf("\nSTATIC_VALIDATION_OK\n");
fprintf("CALIBRATION_MAT: %s\n", make_relpath(calibration_mat_path, repo_dir));
fprintf("RUN_VALIDATION_CSV: %s\n", make_relpath(run_csv_out, repo_dir));
fprintf("POSE_VALIDATION_CSV: %s\n", make_relpath(pose_csv_out, repo_dir));
fprintf("SEQ_OK: %s\n", string(seq_ok));
fprintf("NORM_OK: %s\n", string(norm_ok));
fprintf("AXIS_OK: %s\n", string(axis_ok));
fprintf("FINAL_DECISION: %s\n", final_decision);

%% Funciones locales
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
    error("Pose con eje no soportado: %s", pose_name);
end
end

function [expected_axis_mean, cross_axis_abs_mean] = axis_alignment_metrics(gx, gy, gz, expected_axis, expected_sign)
switch expected_axis
    case "x"
        expected_vec = gx * expected_sign;
        cross_vec = [gy, gz];
    case "y"
        expected_vec = gy * expected_sign;
        cross_vec = [gx, gz];
    case "z"
        expected_vec = gz * expected_sign;
        cross_vec = [gx, gy];
    otherwise
        error("Eje esperado no soportado: %s", expected_axis);
end

expected_axis_mean = mean(expected_vec);
cross_axis_abs_mean = mean(abs(cross_vec), "all");
end

function rel = make_relpath(abs_path, repo_dir)
rel = strrep(abs_path, [repo_dir filesep], "");
end
