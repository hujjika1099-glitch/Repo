% calibrate_sensorC_static_6pose.m
% Calibracion estatica final 6 poses para sensor_C.

%% Configuracion
default_sensor_id = "sensor_C";
default_pose_order = ["pos_x","neg_x","pos_y","neg_y","pos_z","neg_z"];
default_runs_target = [3,3,3,3,5,5];
default_dataset_mode = "explicit_list"; % explicit_list | latest_n_per_pose

% Dataset por defecto solicitado para Fase 10
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

%% Seleccion de dataset
selected_by_pose = struct();
for i = 1:numel(pose_order)
    pose = pose_order(i);
    pose_key = char(pose);
    target_n = runs_target_by_pose(i);

    switch dataset_mode
        case "explicit_list"
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

%% Recoleccion de metricas por corrida
run_pose = strings(0,1);
run_file = strings(0,1);
samples = zeros(0,1);
duration_s = zeros(0,1);
freq_hz = zeros(0,1);
seq_jumps = zeros(0,1);
raw_x_mean = zeros(0,1);
raw_y_mean = zeros(0,1);
raw_z_mean = zeros(0,1);
mv_x_mean = zeros(0,1);
mv_y_mean = zeros(0,1);
mv_z_mean = zeros(0,1);

for i = 1:numel(pose_order)
    pose = pose_order(i);
    pose_files = selected_by_pose.(char(pose));
    for k = 1:numel(pose_files)
        csv_path = fullfile(raw_dir, char(pose_files(k)));
        tbl = readtable(csv_path, "Delimiter", ",", "TextType", "string");
        missing_cols = setdiff(expected_cols, tbl.Properties.VariableNames);
        if ~isempty(missing_cols)
            error("CSV sin columnas esperadas (%s): %s", pose_files(k), strjoin(missing_cols, ", "));
        end
        tbl = tbl(:, expected_cols);
        n = height(tbl);
        if n < 2
            error("Corrida con muestras insuficientes: %s", pose_files(k));
        end

        t_us = double(tbl.t_us);
        run_pose(end+1,1) = pose; %#ok<SAGROW>
        run_file(end+1,1) = string(pose_files(k)); %#ok<SAGROW>
        samples(end+1,1) = n; %#ok<SAGROW>
        duration_s(end+1,1) = (t_us(end) - t_us(1)) / 1e6; %#ok<SAGROW>
        freq_hz(end+1,1) = (n - 1) / max(duration_s(end), eps); %#ok<SAGROW>
        seq_jumps(end+1,1) = nnz(diff(double(tbl.seq)) ~= 1); %#ok<SAGROW>
        raw_x_mean(end+1,1) = mean(double(tbl.raw_x)); %#ok<SAGROW>
        raw_y_mean(end+1,1) = mean(double(tbl.raw_y)); %#ok<SAGROW>
        raw_z_mean(end+1,1) = mean(double(tbl.raw_z)); %#ok<SAGROW>
        mv_x_mean(end+1,1) = mean(double(tbl.mv_x)); %#ok<SAGROW>
        mv_y_mean(end+1,1) = mean(double(tbl.mv_y)); %#ok<SAGROW>
        mv_z_mean(end+1,1) = mean(double(tbl.mv_z)); %#ok<SAGROW>
    end
end

run_tbl = table(run_pose, run_file, samples, duration_s, freq_hz, seq_jumps, ...
    raw_x_mean, raw_y_mean, raw_z_mean, mv_x_mean, mv_y_mean, mv_z_mean, ...
    'VariableNames', {'pose','run_file','samples','duration_s','freq_hz','seq_jumps', ...
    'raw_x_mean','raw_y_mean','raw_z_mean','mv_x_mean','mv_y_mean','mv_z_mean'});

%% Medias por pose
pose_name = pose_order(:);
runs_found = zeros(numel(pose_order),1);
raw_x_pose_mean = zeros(numel(pose_order),1);
raw_y_pose_mean = zeros(numel(pose_order),1);
raw_z_pose_mean = zeros(numel(pose_order),1);
mv_x_pose_mean = zeros(numel(pose_order),1);
mv_y_pose_mean = zeros(numel(pose_order),1);
mv_z_pose_mean = zeros(numel(pose_order),1);
freq_mean_hz = zeros(numel(pose_order),1);
seq_jumps_total = zeros(numel(pose_order),1);

for i = 1:numel(pose_order)
    pose = pose_order(i);
    subset = run_tbl(run_tbl.pose == pose, :);
    runs_found(i) = height(subset);
    raw_x_pose_mean(i) = mean(subset.raw_x_mean);
    raw_y_pose_mean(i) = mean(subset.raw_y_mean);
    raw_z_pose_mean(i) = mean(subset.raw_z_mean);
    mv_x_pose_mean(i) = mean(subset.mv_x_mean);
    mv_y_pose_mean(i) = mean(subset.mv_y_mean);
    mv_z_pose_mean(i) = mean(subset.mv_z_mean);
    freq_mean_hz(i) = mean(subset.freq_hz);
    seq_jumps_total(i) = sum(subset.seq_jumps);
end

pose_tbl = table(pose_name, runs_found, freq_mean_hz, seq_jumps_total, ...
    raw_x_pose_mean, raw_y_pose_mean, raw_z_pose_mean, ...
    mv_x_pose_mean, mv_y_pose_mean, mv_z_pose_mean, ...
    'VariableNames', {'pose','runs_found','freq_mean_hz','seq_jumps_total', ...
    'raw_x_pose_mean','raw_y_pose_mean','raw_z_pose_mean', ...
    'mv_x_pose_mean','mv_y_pose_mean','mv_z_pose_mean'});

%% Coeficientes por eje (metodo midpoint/delta)
[offset_x_raw, sens_x_raw] = midpoint_sensitivity(pose_tbl, "x", "raw");
[offset_y_raw, sens_y_raw] = midpoint_sensitivity(pose_tbl, "y", "raw");
[offset_z_raw, sens_z_raw] = midpoint_sensitivity(pose_tbl, "z", "raw");
[offset_x_mv, sens_x_mv] = midpoint_sensitivity(pose_tbl, "x", "mv");
[offset_y_mv, sens_y_mv] = midpoint_sensitivity(pose_tbl, "y", "mv");
[offset_z_mv, sens_z_mv] = midpoint_sensitivity(pose_tbl, "z", "mv");

axis_name = ["x";"y";"z"];
offset_raw = [offset_x_raw; offset_y_raw; offset_z_raw];
sens_raw_per_g = [sens_x_raw; sens_y_raw; sens_z_raw];
offset_mv = [offset_x_mv; offset_y_mv; offset_z_mv];
sens_mv_per_g = [sens_x_mv; sens_y_mv; sens_z_mv];

coeff_tbl = table(axis_name, offset_raw, sens_raw_per_g, offset_mv, sens_mv_per_g, ...
    'VariableNames', {'axis','offset_raw','sens_raw_per_g','offset_mv','sens_mv_per_g'});

if any(abs(coeff_tbl.sens_mv_per_g) < eps) || any(abs(coeff_tbl.sens_raw_per_g) < eps)
    error("Sensibilidad nula detectada en al menos un eje; calibracion invalida.");
end

%% Guardado de artefactos
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
base = sensor_id + "_static_calibration_" + stamp;
coeff_csv_out = fullfile(processed_dir, char(base + ".csv"));
mat_out = fullfile(processed_dir, char(base + ".mat"));
run_csv_out = fullfile(analysis_out_dir, char(base + "_runs.csv"));
pose_csv_out = fullfile(analysis_out_dir, char(base + "_poses.csv"));
dataset_csv_out = fullfile(analysis_out_dir, char(base + "_dataset.csv"));
txt_out = fullfile(analysis_out_dir, char(base + ".txt"));

writetable(coeff_tbl, coeff_csv_out);
writetable(run_tbl, run_csv_out);
writetable(pose_tbl, pose_csv_out);
dataset_tbl = build_dataset_table(pose_order, selected_by_pose);
writetable(dataset_tbl, dataset_csv_out);

calibration = struct();
calibration.sensor_id = sensor_id;
calibration.created_at = string(datetime("now", "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss Z"));
calibration.dataset_mode = dataset_mode;
calibration.pose_order = pose_order;
calibration.runs_target_by_pose = runs_target_by_pose;
calibration.selected_by_pose = selected_by_pose;
calibration.coefficients = coeff_tbl;
calibration.formula_mv = "g_axis = (mv_axis - offset_axis_mv) / sens_axis_mv_per_g";
calibration.formula_raw = "g_axis = (raw_axis - offset_axis_raw) / sens_axis_raw_per_g";
calibration.generated_files = struct( ...
    "coeff_csv", make_relpath(coeff_csv_out, repo_dir), ...
    "run_csv", make_relpath(run_csv_out, repo_dir), ...
    "pose_csv", make_relpath(pose_csv_out, repo_dir), ...
    "dataset_csv", make_relpath(dataset_csv_out, repo_dir), ...
    "summary_txt", make_relpath(txt_out, repo_dir));

save(mat_out, "calibration", "coeff_tbl", "run_tbl", "pose_tbl");

fid = fopen(txt_out, "w");
if fid < 0
    error("No fue posible crear salida de calibracion: %s", txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/calibration/calibrate_sensorC_static_6pose.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "dataset_mode: %s\n", dataset_mode);
fprintf(fid, "coeff_csv: %s\n", make_relpath(coeff_csv_out, repo_dir));
fprintf(fid, "coeff_mat: %s\n", make_relpath(mat_out, repo_dir));
fprintf(fid, "run_csv: %s\n", make_relpath(run_csv_out, repo_dir));
fprintf(fid, "pose_csv: %s\n", make_relpath(pose_csv_out, repo_dir));
fprintf(fid, "dataset_csv: %s\n", make_relpath(dataset_csv_out, repo_dir));
fprintf(fid, "offset_x_mv: %.9f\n", offset_x_mv);
fprintf(fid, "offset_y_mv: %.9f\n", offset_y_mv);
fprintf(fid, "offset_z_mv: %.9f\n", offset_z_mv);
fprintf(fid, "sens_x_mv_per_g: %.9f\n", sens_x_mv);
fprintf(fid, "sens_y_mv_per_g: %.9f\n", sens_y_mv);
fprintf(fid, "sens_z_mv_per_g: %.9f\n", sens_z_mv);
fprintf(fid, "offset_x_raw: %.9f\n", offset_x_raw);
fprintf(fid, "offset_y_raw: %.9f\n", offset_y_raw);
fprintf(fid, "offset_z_raw: %.9f\n", offset_z_raw);
fprintf(fid, "sens_x_raw_per_g: %.9f\n", sens_x_raw);
fprintf(fid, "sens_y_raw_per_g: %.9f\n", sens_y_raw);
fprintf(fid, "sens_z_raw_per_g: %.9f\n", sens_z_raw);

%% Salida de consola
fprintf("\nCALIBRATION_OK\n");
fprintf("SENSOR_ID: %s\n", sensor_id);
fprintf("DATASET_MODE: %s\n", dataset_mode);
fprintf("COEFF_CSV: %s\n", make_relpath(coeff_csv_out, repo_dir));
fprintf("COEFF_MAT: %s\n", make_relpath(mat_out, repo_dir));
fprintf("RUN_CSV: %s\n", make_relpath(run_csv_out, repo_dir));
fprintf("POSE_CSV: %s\n", make_relpath(pose_csv_out, repo_dir));
fprintf("DATASET_CSV: %s\n", make_relpath(dataset_csv_out, repo_dir));
fprintf("OFFSET_MV: [%.6f %.6f %.6f]\n", offset_x_mv, offset_y_mv, offset_z_mv);
fprintf("SENS_MV_PER_G: [%.6f %.6f %.6f]\n", sens_x_mv, sens_y_mv, sens_z_mv);
fprintf("OFFSET_RAW: [%.6f %.6f %.6f]\n", offset_x_raw, offset_y_raw, offset_z_raw);
fprintf("SENS_RAW_PER_G: [%.6f %.6f %.6f]\n", sens_x_raw, sens_y_raw, sens_z_raw);

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

function [offset_val, sens_val] = midpoint_sensitivity(pose_tbl, axis_name, domain_name)
pos_pose = "pos_" + axis_name;
neg_pose = "neg_" + axis_name;
col_name = domain_name + "_" + axis_name + "_pose_mean";

pid = pose_tbl.pose == pos_pose;
nid = pose_tbl.pose == neg_pose;
if ~any(pid) || ~any(nid)
    error("No se encontraron poses %s/%s en pose_tbl.", pos_pose, neg_pose);
end

pos_val = pose_tbl.(col_name)(pid);
neg_val = pose_tbl.(col_name)(nid);
offset_val = (pos_val + neg_val) / 2;
sens_val = (pos_val - neg_val) / 2;
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
