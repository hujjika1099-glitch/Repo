% validate_sensorC_static_affine_3x3.m
% Validacion cruzada del modelo affine 3x3 de sensor_C y comparacion
% explicita contra modelo simple por eje (Fase 10).

%% Configuracion
default_sensor_id = "sensor_C";
default_affine_mat_relpath = "";
default_simple_pose_csv_relpath = "";

% Criterios operativos
norm_mean_abs_err_max = 0.15;
norm_max_abs_err_max = 0.50;
expected_axis_abs_min = 0.85;
cross_axis_abs_max = 0.40;

if exist("sensor_id", "var") && strlength(string(sensor_id)) > 0
    sensor_id = string(sensor_id);
else
    sensor_id = default_sensor_id;
end

if exist("affine_mat_relpath", "var") && strlength(string(affine_mat_relpath)) > 0
    affine_mat_relpath = string(affine_mat_relpath);
else
    affine_mat_relpath = default_affine_mat_relpath;
end

if exist("simple_pose_csv_relpath", "var") && strlength(string(simple_pose_csv_relpath)) > 0
    simple_pose_csv_relpath = string(simple_pose_csv_relpath);
else
    simple_pose_csv_relpath = default_simple_pose_csv_relpath;
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

%% Carga de modelo affine
if strlength(affine_mat_relpath) > 0
    affine_mat_path = fullfile(repo_dir, char(affine_mat_relpath));
else
    mats = dir(fullfile(processed_dir, char(sensor_id + "_static_affine_3x3_*.mat")));
    if isempty(mats)
        error("No se encontro .mat affine en %s", processed_dir);
    end
    [~, idx] = sort([mats.datenum], "ascend");
    mats = mats(idx);
    affine_mat_path = fullfile(mats(end).folder, mats(end).name);
end

loaded = load(affine_mat_path);
if ~isfield(loaded, "affine_model")
    error("Archivo affine sin variable affine_model.");
end
affine_model = loaded.affine_model;

if ~isfield(affine_model, "mv") || ~isfield(affine_model.mv, "M") || ~isfield(affine_model.mv, "b")
    error("Modelo affine incompleto (mv.M o mv.b faltante).");
end

M_mv = affine_model.mv.M;
b_mv = affine_model.mv.b(:);
if any(size(M_mv) ~= [3,3]) || numel(b_mv) ~= 3
    error("Dimensiones invalidas en M_mv o b_mv.");
end

pose_order = string(affine_model.pose_order(:))';
selected_by_pose = affine_model.selected_by_pose;
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

mean_gx = zeros(0,1);
mean_gy = zeros(0,1);
mean_gz = zeros(0,1);
mean_gnorm = zeros(0,1);
mean_abs_gnorm_err = zeros(0,1);
max_abs_gnorm_err = zeros(0,1);
expected_axis_mean = zeros(0,1);
cross_axis_abs_mean = zeros(0,1);

for i = 1:numel(pose_order)
    p = pose_order(i);
    key = char(p);
    if ~isfield(selected_by_pose, key)
        error("Pose %s no existe en selected_by_pose.", p);
    end
    files = string(selected_by_pose.(key));
    files = files(strlength(files) > 0);
    if isempty(files)
        error("Pose %s sin archivos.", p);
    end

    [exp_axis, exp_sign] = expected_from_pose(p);

    for k = 1:numel(files)
        csv_path = fullfile(raw_dir, char(files(k)));
        if ~isfile(csv_path)
            error("CSV no encontrado: %s", csv_path);
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

        mv = [double(tbl.mv_x), double(tbl.mv_y), double(tbl.mv_z)]'; % 3xN
        g = M_mv * (mv - b_mv);                                        % 3xN
        gx = g(1,:).';
        gy = g(2,:).';
        gz = g(3,:).';
        gnorm = sqrt(gx.^2 + gy.^2 + gz.^2);
        gerr = abs(gnorm - 1.0);

        t_us = double(tbl.t_us);

        pose(end+1,1) = p; %#ok<SAGROW>
        run_file(end+1,1) = string(files(k)); %#ok<SAGROW>
        samples(end+1,1) = n; %#ok<SAGROW>
        duration_s(end+1,1) = (t_us(end)-t_us(1)) / 1e6; %#ok<SAGROW>
        freq_hz(end+1,1) = (n-1) / max(duration_s(end), eps); %#ok<SAGROW>
        seq_jumps(end+1,1) = nnz(diff(double(tbl.seq)) ~= 1); %#ok<SAGROW>
        expected_axis(end+1,1) = exp_axis; %#ok<SAGROW>
        expected_sign(end+1,1) = exp_sign; %#ok<SAGROW>

        mean_gx(end+1,1) = mean(gx); %#ok<SAGROW>
        mean_gy(end+1,1) = mean(gy); %#ok<SAGROW>
        mean_gz(end+1,1) = mean(gz); %#ok<SAGROW>
        mean_gnorm(end+1,1) = mean(gnorm); %#ok<SAGROW>
        mean_abs_gnorm_err(end+1,1) = mean(gerr); %#ok<SAGROW>
        max_abs_gnorm_err(end+1,1) = max(gerr); %#ok<SAGROW>

        [exp_axis_mean, cross_abs] = axis_alignment_metrics(gx, gy, gz, exp_axis, exp_sign);
        expected_axis_mean(end+1,1) = exp_axis_mean; %#ok<SAGROW>
        cross_axis_abs_mean(end+1,1) = cross_abs; %#ok<SAGROW>
    end
end

run_validation_tbl = table( ...
    pose, run_file, samples, duration_s, freq_hz, seq_jumps, expected_axis, expected_sign, ...
    mean_gx, mean_gy, mean_gz, mean_gnorm, mean_abs_gnorm_err, max_abs_gnorm_err, expected_axis_mean, cross_axis_abs_mean, ...
    'VariableNames', {'pose','run_file','samples','duration_s','freq_hz','seq_jumps','expected_axis','expected_sign', ...
    'mean_gx','mean_gy','mean_gz','mean_gnorm','mean_abs_gnorm_err','max_abs_gnorm_err','expected_axis_mean','cross_axis_abs_mean'});

%% Resumen por pose
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
    mean_gx_pose(i) = mean(s.mean_gx);
    mean_gy_pose(i) = mean(s.mean_gy);
    mean_gz_pose(i) = mean(s.mean_gz);
    mean_gnorm_pose(i) = mean(s.mean_gnorm);
    mean_abs_gnorm_err_pose(i) = mean(s.mean_abs_gnorm_err);
    max_abs_gnorm_err_pose(i) = max(s.max_abs_gnorm_err);
    mean_expected_axis_pose(i) = mean(s.expected_axis_mean);
    mean_cross_axis_abs_pose(i) = mean(s.cross_axis_abs_mean);
end

pose_validation_tbl = table( ...
    pose_name, runs_found, freq_mean_hz, seq_jumps_total, ...
    mean_gx_pose, mean_gy_pose, mean_gz_pose, mean_gnorm_pose, ...
    mean_expected_axis_pose, mean_cross_axis_abs_pose, ...
    mean_abs_gnorm_err_pose, max_abs_gnorm_err_pose, ...
    'VariableNames', {'pose','runs_found','freq_mean_hz','seq_jumps_total', ...
    'mean_gx','mean_gy','mean_gz','mean_gnorm', ...
    'mean_expected_axis','mean_cross_axis_abs','mean_abs_gnorm_err','max_abs_gnorm_err'});

%% Carga de resumen simple (Fase 10) para comparar
if strlength(simple_pose_csv_relpath) > 0
    simple_pose_csv_path = fullfile(repo_dir, char(simple_pose_csv_relpath));
else
    simple_files = dir(fullfile(processed_dir, char(sensor_id + "_static_validation_*_poses.csv")));
    if isempty(simple_files)
        error("No se encontro resumen de validacion simple en %s", processed_dir);
    end
    [~, idx] = sort([simple_files.datenum], "ascend");
    simple_files = simple_files(idx);
    simple_pose_csv_path = fullfile(simple_files(end).folder, simple_files(end).name);
end

simple_pose_tbl = readtable(simple_pose_csv_path, "Delimiter", ",", "TextType", "string");
req_cols = {'pose','mean_gnorm','mean_abs_gnorm_err','max_abs_gnorm_err','mean_expected_axis','mean_cross_axis_abs','seq_jumps_total'};
missing_simple = setdiff(req_cols, simple_pose_tbl.Properties.VariableNames);
if ~isempty(missing_simple)
    error("CSV simple sin columnas esperadas: %s", strjoin(missing_simple, ", "));
end

simple_mean_gnorm = zeros(numel(pose_order),1);
simple_mean_abs_err = zeros(numel(pose_order),1);
simple_max_abs_err = zeros(numel(pose_order),1);
simple_mean_expected_axis = zeros(numel(pose_order),1);
simple_mean_cross_axis = zeros(numel(pose_order),1);

for i = 1:numel(pose_order)
    p = pose_order(i);
    sid = simple_pose_tbl.pose == p;
    if ~any(sid)
        error("Pose %s no existe en resumen simple.", p);
    end
    simple_mean_gnorm(i) = double(simple_pose_tbl.mean_gnorm(sid));
    simple_mean_abs_err(i) = double(simple_pose_tbl.mean_abs_gnorm_err(sid));
    simple_max_abs_err(i) = double(simple_pose_tbl.max_abs_gnorm_err(sid));
    simple_mean_expected_axis(i) = double(simple_pose_tbl.mean_expected_axis(sid));
    simple_mean_cross_axis(i) = double(simple_pose_tbl.mean_cross_axis_abs(sid));
end

comparison_tbl = table( ...
    pose_order(:), ...
    simple_mean_gnorm, pose_validation_tbl.mean_gnorm, (pose_validation_tbl.mean_gnorm - simple_mean_gnorm), ...
    simple_mean_abs_err, pose_validation_tbl.mean_abs_gnorm_err, (pose_validation_tbl.mean_abs_gnorm_err - simple_mean_abs_err), ...
    simple_max_abs_err, pose_validation_tbl.max_abs_gnorm_err, (pose_validation_tbl.max_abs_gnorm_err - simple_max_abs_err), ...
    simple_mean_expected_axis, pose_validation_tbl.mean_expected_axis, (pose_validation_tbl.mean_expected_axis - simple_mean_expected_axis), ...
    simple_mean_cross_axis, pose_validation_tbl.mean_cross_axis_abs, (pose_validation_tbl.mean_cross_axis_abs - simple_mean_cross_axis), ...
    'VariableNames', {'pose', ...
    'simple_mean_gnorm','affine_mean_gnorm','delta_mean_gnorm', ...
    'simple_mean_abs_gnorm_err','affine_mean_abs_gnorm_err','delta_mean_abs_gnorm_err', ...
    'simple_max_abs_gnorm_err','affine_max_abs_gnorm_err','delta_max_abs_gnorm_err', ...
    'simple_mean_expected_axis','affine_mean_expected_axis','delta_mean_expected_axis', ...
    'simple_mean_cross_axis_abs','affine_mean_cross_axis_abs','delta_mean_cross_axis_abs'});

%% Decision operativa final
seq_ok = all(pose_validation_tbl.seq_jumps_total == 0);
axis_ok = all(abs(pose_validation_tbl.mean_expected_axis) >= expected_axis_abs_min) && ...
          all(pose_validation_tbl.mean_cross_axis_abs <= cross_axis_abs_max);
norm_ok = all(pose_validation_tbl.mean_abs_gnorm_err <= norm_mean_abs_err_max) && ...
          all(pose_validation_tbl.max_abs_gnorm_err <= norm_max_abs_err_max);

overall_simple_mean_err = mean(simple_mean_abs_err);
overall_affine_mean_err = mean(pose_validation_tbl.mean_abs_gnorm_err);
overall_improved = overall_affine_mean_err < overall_simple_mean_err;

neg_y_id = pose_validation_tbl.pose == "neg_y";
pos_z_id = pose_validation_tbl.pose == "pos_z";
focus_neg_y_improved = pose_validation_tbl.mean_abs_gnorm_err(neg_y_id) < simple_mean_abs_err(neg_y_id);
focus_pos_z_improved = pose_validation_tbl.mean_abs_gnorm_err(pos_z_id) < simple_mean_abs_err(pos_z_id);
focus_improved = focus_neg_y_improved && focus_pos_z_improved;

if ~seq_ok
    final_decision = "blocked";
elseif axis_ok && norm_ok && overall_improved && focus_improved
    final_decision = "calibrated_and_validated";
else
    final_decision = "calibrated_but_review_needed";
end

ready_for_next_stage = final_decision == "calibrated_and_validated";

%% Guardado de artefactos
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
base = sensor_id + "_static_affine_3x3_validation_" + stamp;
run_csv_out = fullfile(processed_dir, char(base + ".csv"));
pose_csv_out = fullfile(processed_dir, char(base + "_poses.csv"));
cmp_csv_out = fullfile(analysis_out_dir, char(base + "_comparison_vs_simple.csv"));
txt_out = fullfile(analysis_out_dir, char(base + ".txt"));

writetable(run_validation_tbl, run_csv_out);
writetable(pose_validation_tbl, pose_csv_out);
writetable(comparison_tbl, cmp_csv_out);

fid = fopen(txt_out, "w");
if fid < 0
    error("No fue posible crear resumen de validacion affine: %s", txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/analysis/validate_sensorC_static_affine_3x3.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "affine_mat: %s\n", make_relpath(affine_mat_path, repo_dir));
fprintf(fid, "simple_pose_csv: %s\n", make_relpath(simple_pose_csv_path, repo_dir));
fprintf(fid, "run_csv: %s\n", make_relpath(run_csv_out, repo_dir));
fprintf(fid, "pose_csv: %s\n", make_relpath(pose_csv_out, repo_dir));
fprintf(fid, "comparison_csv: %s\n", make_relpath(cmp_csv_out, repo_dir));
fprintf(fid, "seq_ok: %s\n", string(seq_ok));
fprintf(fid, "axis_ok: %s\n", string(axis_ok));
fprintf(fid, "norm_ok: %s\n", string(norm_ok));
fprintf(fid, "overall_simple_mean_abs_gnorm_err: %.9f\n", overall_simple_mean_err);
fprintf(fid, "overall_affine_mean_abs_gnorm_err: %.9f\n", overall_affine_mean_err);
fprintf(fid, "overall_improved: %s\n", string(overall_improved));
fprintf(fid, "focus_neg_y_improved: %s\n", string(focus_neg_y_improved));
fprintf(fid, "focus_pos_z_improved: %s\n", string(focus_pos_z_improved));
fprintf(fid, "final_decision: %s\n", final_decision);
fprintf(fid, "ready_for_next_stage: %s\n", string(ready_for_next_stage));

%% Consola
fprintf("\nAFFINE_VALIDATION_OK\n");
fprintf("AFFINE_MAT: %s\n", make_relpath(affine_mat_path, repo_dir));
fprintf("SIMPLE_POSE_CSV: %s\n", make_relpath(simple_pose_csv_path, repo_dir));
fprintf("RUN_CSV: %s\n", make_relpath(run_csv_out, repo_dir));
fprintf("POSE_CSV: %s\n", make_relpath(pose_csv_out, repo_dir));
fprintf("CMP_CSV: %s\n", make_relpath(cmp_csv_out, repo_dir));
fprintf("SEQ_OK: %s\n", string(seq_ok));
fprintf("AXIS_OK: %s\n", string(axis_ok));
fprintf("NORM_OK: %s\n", string(norm_ok));
fprintf("OVERALL_SIMPLE_MEAN_ABS_ERR: %.9f\n", overall_simple_mean_err);
fprintf("OVERALL_AFFINE_MEAN_ABS_ERR: %.9f\n", overall_affine_mean_err);
fprintf("FOCUS_NEG_Y_IMPROVED: %s\n", string(focus_neg_y_improved));
fprintf("FOCUS_POS_Z_IMPROVED: %s\n", string(focus_pos_z_improved));
fprintf("FINAL_DECISION: %s\n", final_decision);
fprintf("READY_FOR_NEXT_STAGE: %s\n", string(ready_for_next_stage));

%% Funciones locales
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
