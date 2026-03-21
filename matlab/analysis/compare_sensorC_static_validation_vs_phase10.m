% compare_sensorC_static_validation_vs_phase10.m
% Comparacion de validacion recalibrada vs validacion base de Fase 10.

%% Configuracion
sensor_id = "sensor_C";
baseline_pose_csv_relpath = "data/processed/sensor_C_static_validation_20260321_140524_poses.csv";
candidate_pose_csv_relpath = ""; % vacio => usa el mas reciente (excluyendo baseline)

axis_expected_abs_min = 0.75;
cross_axis_abs_max = 0.45;

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
processed_dir = fullfile(repo_dir, "data", "processed");
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
if ~isfolder(analysis_out_dir)
    mkdir(analysis_out_dir);
end

baseline_pose_csv_path = fullfile(repo_dir, char(baseline_pose_csv_relpath));
if ~isfile(baseline_pose_csv_path)
    error("No existe baseline de Fase 10: %s", baseline_pose_csv_path);
end

if strlength(string(candidate_pose_csv_relpath)) > 0
    candidate_pose_csv_path = fullfile(repo_dir, char(candidate_pose_csv_relpath));
    if ~isfile(candidate_pose_csv_path)
        error("No existe candidate_pose_csv: %s", candidate_pose_csv_path);
    end
else
    files = dir(fullfile(processed_dir, char(sensor_id + "_static_validation_*_poses.csv")));
    if isempty(files)
        error("No hay pose_csv de validacion en %s", processed_dir);
    end
    [~, order] = sort([files.datenum], "ascend");
    files = files(order);
    candidate_pose_csv_path = "";
    for i = numel(files):-1:1
        p = fullfile(files(i).folder, files(i).name);
        if ~strcmpi(p, baseline_pose_csv_path)
            candidate_pose_csv_path = p;
            break;
        end
    end
    if strlength(candidate_pose_csv_path) == 0
        error("No se encontro candidate diferente al baseline.");
    end
end

%% Cargar tablas
base_tbl = readtable(baseline_pose_csv_path, "Delimiter", ",", "TextType", "string");
cand_tbl = readtable(candidate_pose_csv_path, "Delimiter", ",", "TextType", "string");

required_cols = {'pose','seq_jumps_total','mean_gnorm','mean_abs_gnorm_err','max_abs_gnorm_err','mean_expected_axis','mean_cross_axis_abs'};
for i = 1:numel(required_cols)
    col = required_cols{i};
    if ~ismember(col, base_tbl.Properties.VariableNames)
        error("Baseline sin columna %s", col);
    end
    if ~ismember(col, cand_tbl.Properties.VariableNames)
        error("Candidate sin columna %s", col);
    end
end

pose_order = ["pos_x","neg_x","pos_y","neg_y","pos_z","neg_z"]';

simple_mean_gnorm = zeros(numel(pose_order),1);
retest_mean_gnorm = zeros(numel(pose_order),1);
delta_mean_gnorm = zeros(numel(pose_order),1);
simple_mean_abs_err = zeros(numel(pose_order),1);
retest_mean_abs_err = zeros(numel(pose_order),1);
delta_mean_abs_err = zeros(numel(pose_order),1);
simple_max_abs_err = zeros(numel(pose_order),1);
retest_max_abs_err = zeros(numel(pose_order),1);
delta_max_abs_err = zeros(numel(pose_order),1);
simple_mean_expected_axis = zeros(numel(pose_order),1);
retest_mean_expected_axis = zeros(numel(pose_order),1);
delta_mean_expected_axis = zeros(numel(pose_order),1);
simple_mean_cross_axis = zeros(numel(pose_order),1);
retest_mean_cross_axis = zeros(numel(pose_order),1);
delta_mean_cross_axis = zeros(numel(pose_order),1);
retest_seq_jumps_total = zeros(numel(pose_order),1);

for i = 1:numel(pose_order)
    p = pose_order(i);
    b = base_tbl(base_tbl.pose == p, :);
    c = cand_tbl(cand_tbl.pose == p, :);
    if isempty(b) || isempty(c)
        error("Pose faltante en comparacion: %s", p);
    end

    simple_mean_gnorm(i) = double(b.mean_gnorm);
    retest_mean_gnorm(i) = double(c.mean_gnorm);
    delta_mean_gnorm(i) = retest_mean_gnorm(i) - simple_mean_gnorm(i);

    simple_mean_abs_err(i) = double(b.mean_abs_gnorm_err);
    retest_mean_abs_err(i) = double(c.mean_abs_gnorm_err);
    delta_mean_abs_err(i) = retest_mean_abs_err(i) - simple_mean_abs_err(i);

    simple_max_abs_err(i) = double(b.max_abs_gnorm_err);
    retest_max_abs_err(i) = double(c.max_abs_gnorm_err);
    delta_max_abs_err(i) = retest_max_abs_err(i) - simple_max_abs_err(i);

    simple_mean_expected_axis(i) = double(b.mean_expected_axis);
    retest_mean_expected_axis(i) = double(c.mean_expected_axis);
    delta_mean_expected_axis(i) = retest_mean_expected_axis(i) - simple_mean_expected_axis(i);

    simple_mean_cross_axis(i) = double(b.mean_cross_axis_abs);
    retest_mean_cross_axis(i) = double(c.mean_cross_axis_abs);
    delta_mean_cross_axis(i) = retest_mean_cross_axis(i) - simple_mean_cross_axis(i);

    retest_seq_jumps_total(i) = double(c.seq_jumps_total);
end

comparison_tbl = table( ...
    pose_order, ...
    simple_mean_gnorm, retest_mean_gnorm, delta_mean_gnorm, ...
    simple_mean_abs_err, retest_mean_abs_err, delta_mean_abs_err, ...
    simple_max_abs_err, retest_max_abs_err, delta_max_abs_err, ...
    simple_mean_expected_axis, retest_mean_expected_axis, delta_mean_expected_axis, ...
    simple_mean_cross_axis, retest_mean_cross_axis, delta_mean_cross_axis, ...
    retest_seq_jumps_total, ...
    'VariableNames', {'pose', ...
    'simple_mean_gnorm','retest_mean_gnorm','delta_mean_gnorm', ...
    'simple_mean_abs_gnorm_err','retest_mean_abs_gnorm_err','delta_mean_abs_gnorm_err', ...
    'simple_max_abs_gnorm_err','retest_max_abs_gnorm_err','delta_max_abs_gnorm_err', ...
    'simple_mean_expected_axis','retest_mean_expected_axis','delta_mean_expected_axis', ...
    'simple_mean_cross_axis_abs','retest_mean_cross_axis_abs','delta_mean_cross_axis_abs', ...
    'retest_seq_jumps_total'});

%% Decision
seq_ok = all(retest_seq_jumps_total == 0);
axis_ok = all(abs(retest_mean_expected_axis) >= axis_expected_abs_min) && ...
          all(retest_mean_cross_axis <= cross_axis_abs_max);
neg_y_id = pose_order == "neg_y";
pos_z_id = pose_order == "pos_z";
neg_y_improved = retest_mean_abs_err(neg_y_id) < simple_mean_abs_err(neg_y_id);
pos_z_improved = retest_mean_abs_err(pos_z_id) < simple_mean_abs_err(pos_z_id);
global_simple_mean_err = mean(simple_mean_abs_err);
global_retest_mean_err = mean(retest_mean_abs_err);
global_improved = global_retest_mean_err < global_simple_mean_err;

if seq_ok && axis_ok && neg_y_improved && pos_z_improved && global_improved
    final_decision = "calibrated_and_validated";
elseif seq_ok
    final_decision = "calibrated_but_review_needed";
else
    final_decision = "blocked";
end

ready_for_next_stage = final_decision == "calibrated_and_validated";

%% Guardar
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
base = sensor_id + "_static_validation_retest_negY_posZ_" + stamp;
cmp_csv_out = fullfile(analysis_out_dir, char(base + "_comparison_vs_phase10.csv"));
txt_out = fullfile(analysis_out_dir, char(base + ".txt"));
writetable(comparison_tbl, cmp_csv_out);

fid = fopen(txt_out, "w");
if fid < 0
    error("No fue posible crear resumen comparativo: %s", txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/analysis/compare_sensorC_static_validation_vs_phase10.m\n");
fprintf(fid, "baseline_pose_csv: %s\n", make_relpath(baseline_pose_csv_path, repo_dir));
fprintf(fid, "candidate_pose_csv: %s\n", make_relpath(candidate_pose_csv_path, repo_dir));
fprintf(fid, "comparison_csv: %s\n", make_relpath(cmp_csv_out, repo_dir));
fprintf(fid, "seq_ok: %s\n", string(seq_ok));
fprintf(fid, "axis_ok: %s\n", string(axis_ok));
fprintf(fid, "neg_y_improved: %s\n", string(neg_y_improved));
fprintf(fid, "pos_z_improved: %s\n", string(pos_z_improved));
fprintf(fid, "global_simple_mean_abs_gnorm_err: %.9f\n", global_simple_mean_err);
fprintf(fid, "global_retest_mean_abs_gnorm_err: %.9f\n", global_retest_mean_err);
fprintf(fid, "global_improved: %s\n", string(global_improved));
fprintf(fid, "final_decision: %s\n", final_decision);
fprintf(fid, "ready_for_next_stage: %s\n", string(ready_for_next_stage));

%% Consola
fprintf("\nRETEST_COMPARISON_OK\n");
fprintf("BASELINE_POSE_CSV: %s\n", make_relpath(baseline_pose_csv_path, repo_dir));
fprintf("CANDIDATE_POSE_CSV: %s\n", make_relpath(candidate_pose_csv_path, repo_dir));
fprintf("COMPARISON_CSV: %s\n", make_relpath(cmp_csv_out, repo_dir));
fprintf("SEQ_OK: %s\n", string(seq_ok));
fprintf("AXIS_OK: %s\n", string(axis_ok));
fprintf("NEG_Y_IMPROVED: %s\n", string(neg_y_improved));
fprintf("POS_Z_IMPROVED: %s\n", string(pos_z_improved));
fprintf("GLOBAL_SIMPLE_MEAN_ABS_ERR: %.9f\n", global_simple_mean_err);
fprintf("GLOBAL_RETEST_MEAN_ABS_ERR: %.9f\n", global_retest_mean_err);
fprintf("FINAL_DECISION: %s\n", final_decision);
fprintf("READY_FOR_NEXT_STAGE: %s\n", string(ready_for_next_stage));

function rel = make_relpath(abs_path, repo_dir)
rel = strrep(abs_path, [repo_dir filesep], "");
end
