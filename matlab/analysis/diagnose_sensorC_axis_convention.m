% diagnose_sensorC_axis_convention.m
% Diagnostico de convencion de ejes/signos para sensor_C sin recalibrar.
%
% Convencion fisica declarada para esta fase:
% - "pos_axis": eje positivo del modulo apunta contra g.
% - "neg_axis": eje positivo del modulo apunta a favor de g.
%
% Bajo la convencion de salida esperada del acelerometro:
% - pos_axis -> signo esperado +1 en el canal esperado
% - neg_axis -> signo esperado -1 en el canal esperado

%% Configuracion
default_sensor_id = "sensor_C";
default_poses = ["pos_x","neg_x","pos_y","neg_y","pos_z","neg_z"];
default_use_latest_n_runs = 2;
default_dataset_manifest_relpath = ""; % opcional: CSV con columnas pose,run_file
default_dominance_ratio_min = 1.20;

if exist("sensor_id", "var") && strlength(string(sensor_id)) > 0
    sensor_id = string(sensor_id);
else
    sensor_id = default_sensor_id;
end

if exist("poses", "var") && ~isempty(poses)
    poses = string(poses(:))';
else
    poses = default_poses;
end

if exist("use_latest_n_runs", "var") && ~isempty(use_latest_n_runs)
    use_latest_n_runs = double(use_latest_n_runs);
else
    use_latest_n_runs = default_use_latest_n_runs;
end

if exist("dataset_manifest_relpath", "var") && strlength(string(dataset_manifest_relpath)) > 0
    dataset_manifest_relpath = string(dataset_manifest_relpath);
else
    dataset_manifest_relpath = default_dataset_manifest_relpath;
end

if exist("dominance_ratio_min", "var") && ~isempty(dominance_ratio_min)
    dominance_ratio_min = double(dominance_ratio_min);
else
    dominance_ratio_min = default_dominance_ratio_min;
end

if use_latest_n_runs < 1 && strlength(dataset_manifest_relpath) == 0
    error("use_latest_n_runs debe ser >= 1 cuando no se usa manifest explicito.");
end

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
raw_dir = fullfile(repo_dir, "data", "raw", char(sensor_id));
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
if ~isfolder(analysis_out_dir)
    mkdir(analysis_out_dir);
end

%% Seleccion de dataset por pose
selected_by_pose = struct();

if strlength(dataset_manifest_relpath) > 0
    manifest_abs = fullfile(repo_dir, char(dataset_manifest_relpath));
    if ~isfile(manifest_abs)
        error("Manifest no encontrado: %s", manifest_abs);
    end
    manifest_tbl = readtable(manifest_abs, "Delimiter", ",", "TextType", "string");
    required_manifest_cols = {'pose','run_file'};
    missing_manifest_cols = setdiff(required_manifest_cols, manifest_tbl.Properties.VariableNames);
    if ~isempty(missing_manifest_cols)
        error("Manifest sin columnas esperadas: %s", strjoin(missing_manifest_cols, ", "));
    end

    for i = 1:numel(poses)
        p = poses(i);
        pid = manifest_tbl.pose == p;
        files = string(manifest_tbl.run_file(pid));
        files = files(strlength(files) > 0);
        if isempty(files)
            error("Manifest sin corridas para pose %s.", p);
        end
        selected_by_pose.(char(p)) = files;
    end
    dataset_source = "manifest";
    dataset_source_detail = make_relpath(manifest_abs, repo_dir);
else
    for i = 1:numel(poses)
        p = poses(i);
        pattern = char(sensor_id + "_" + p + "_*.csv");
        found = dir(fullfile(raw_dir, pattern));
        if numel(found) < use_latest_n_runs
            error("Pose %s tiene %d corridas; se requieren %d.", p, numel(found), use_latest_n_runs);
        end
        [~, idx] = sort([found.datenum], "ascend");
        found = found(idx);
        found = found((end-use_latest_n_runs+1):end);
        selected_by_pose.(char(p)) = string({found.name})';
    end
    dataset_source = "latest_n_per_pose";
    dataset_source_detail = sprintf("use_latest_n_runs=%d", use_latest_n_runs);
end

%% Metricas por corrida
expected_cols = {'seq','t_us','raw_x','raw_y','raw_z','mv_x','mv_y','mv_z'};

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

dominant_channel_observed = strings(0,1);
dominant_sign_observed = zeros(0,1);
dominance_ratio = zeros(0,1);
expected_channel = strings(0,1);
expected_sign = zeros(0,1);
status = strings(0,1);

for i = 1:numel(poses)
    p = poses(i);
    files = selected_by_pose.(char(p));
    [exp_ch, exp_sign] = expected_from_pose(p);

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

        seq_col = double(tbl.seq);
        t_us = double(tbl.t_us);

        mv_mean_vec = [
            mean(double(tbl.mv_x))
            mean(double(tbl.mv_y))
            mean(double(tbl.mv_z))
        ];
        raw_mean_vec = [
            mean(double(tbl.raw_x))
            mean(double(tbl.raw_y))
            mean(double(tbl.raw_z))
        ];

        [dom_ch, dom_sign, dom_ratio] = get_dominance(mv_mean_vec);
        st = classify_status(dom_ch, dom_sign, dom_ratio, exp_ch, exp_sign, dominance_ratio_min);

        run_pose(end+1,1) = p; %#ok<SAGROW>
        run_file(end+1,1) = string(files(k)); %#ok<SAGROW>
        samples(end+1,1) = n; %#ok<SAGROW>
        duration_s(end+1,1) = (t_us(end) - t_us(1)) / 1e6; %#ok<SAGROW>
        freq_hz(end+1,1) = (n - 1) / max(duration_s(end), eps); %#ok<SAGROW>
        seq_jumps(end+1,1) = nnz(diff(seq_col) ~= 1); %#ok<SAGROW>

        raw_x_mean(end+1,1) = raw_mean_vec(1); %#ok<SAGROW>
        raw_y_mean(end+1,1) = raw_mean_vec(2); %#ok<SAGROW>
        raw_z_mean(end+1,1) = raw_mean_vec(3); %#ok<SAGROW>
        mv_x_mean(end+1,1) = mv_mean_vec(1); %#ok<SAGROW>
        mv_y_mean(end+1,1) = mv_mean_vec(2); %#ok<SAGROW>
        mv_z_mean(end+1,1) = mv_mean_vec(3); %#ok<SAGROW>

        dominant_channel_observed(end+1,1) = dom_ch; %#ok<SAGROW>
        dominant_sign_observed(end+1,1) = dom_sign; %#ok<SAGROW>
        dominance_ratio(end+1,1) = dom_ratio; %#ok<SAGROW>
        expected_channel(end+1,1) = exp_ch; %#ok<SAGROW>
        expected_sign(end+1,1) = exp_sign; %#ok<SAGROW>
        status(end+1,1) = st; %#ok<SAGROW>
    end
end

run_tbl = table( ...
    run_pose, run_file, samples, duration_s, freq_hz, seq_jumps, ...
    raw_x_mean, raw_y_mean, raw_z_mean, mv_x_mean, mv_y_mean, mv_z_mean, ...
    dominant_channel_observed, dominant_sign_observed, dominance_ratio, expected_channel, expected_sign, status, ...
    'VariableNames', {'pose','run_file','samples','duration_s','freq_hz','seq_jumps', ...
    'raw_x_mean','raw_y_mean','raw_z_mean','mv_x_mean','mv_y_mean','mv_z_mean', ...
    'dominant_channel_observed','dominant_sign_observed','dominance_ratio','expected_channel','expected_sign','status'});

%% Resumen por pose
pose_name = poses(:);
runs_found = zeros(numel(poses),1);
freq_mean_hz = zeros(numel(poses),1);
seq_jumps_total = zeros(numel(poses),1);

raw_x_pose_mean = zeros(numel(poses),1);
raw_y_pose_mean = zeros(numel(poses),1);
raw_z_pose_mean = zeros(numel(poses),1);
mv_x_pose_mean = zeros(numel(poses),1);
mv_y_pose_mean = zeros(numel(poses),1);
mv_z_pose_mean = zeros(numel(poses),1);

pose_dominant_channel = strings(numel(poses),1);
pose_dominant_sign = zeros(numel(poses),1);
pose_dominance_ratio = zeros(numel(poses),1);
pose_expected_channel = strings(numel(poses),1);
pose_expected_sign = zeros(numel(poses),1);
pose_status = strings(numel(poses),1);

for i = 1:numel(poses)
    p = poses(i);
    s = run_tbl(run_tbl.pose == p, :);
    if isempty(s)
        error("Sin corridas para pose %s en run_tbl.", p);
    end

    runs_found(i) = height(s);
    freq_mean_hz(i) = mean(s.freq_hz);
    seq_jumps_total(i) = sum(s.seq_jumps);

    raw_vec = [mean(s.raw_x_mean) mean(s.raw_y_mean) mean(s.raw_z_mean)];
    mv_vec = [mean(s.mv_x_mean) mean(s.mv_y_mean) mean(s.mv_z_mean)];

    raw_x_pose_mean(i) = raw_vec(1);
    raw_y_pose_mean(i) = raw_vec(2);
    raw_z_pose_mean(i) = raw_vec(3);
    mv_x_pose_mean(i) = mv_vec(1);
    mv_y_pose_mean(i) = mv_vec(2);
    mv_z_pose_mean(i) = mv_vec(3);

    [dom_ch, dom_sign, dom_ratio] = get_dominance(mv_vec(:));
    [exp_ch, exp_sign] = expected_from_pose(p);
    st = classify_status(dom_ch, dom_sign, dom_ratio, exp_ch, exp_sign, dominance_ratio_min);

    pose_dominant_channel(i) = dom_ch;
    pose_dominant_sign(i) = dom_sign;
    pose_dominance_ratio(i) = dom_ratio;
    pose_expected_channel(i) = exp_ch;
    pose_expected_sign(i) = exp_sign;
    pose_status(i) = st;
end

pose_tbl = table( ...
    pose_name, runs_found, freq_mean_hz, seq_jumps_total, ...
    raw_x_pose_mean, raw_y_pose_mean, raw_z_pose_mean, ...
    mv_x_pose_mean, mv_y_pose_mean, mv_z_pose_mean, ...
    pose_dominant_channel, pose_dominant_sign, pose_dominance_ratio, ...
    pose_expected_channel, pose_expected_sign, pose_status, ...
    'VariableNames', {'pose','runs_found','freq_mean_hz','seq_jumps_total', ...
    'raw_x_mean','raw_y_mean','raw_z_mean','mv_x_mean','mv_y_mean','mv_z_mean', ...
    'dominant_channel_observed','dominant_sign_observed','dominance_ratio', ...
    'expected_channel','expected_sign','status'});

inference_tbl = pose_tbl(:, {'pose','dominant_channel_observed','dominant_sign_observed','expected_channel','expected_sign','status'});
inference_tbl.Properties.VariableNames = {'pose_fisica','canal_dominante_observado','signo_observado','canal_esperado','signo_esperado','estado'};

%% Diagnostico por par de ejes (delta entre pose positiva y negativa)
axis_name = ["x";"y";"z"];
delta_mv_x = zeros(3,1);
delta_mv_y = zeros(3,1);
delta_mv_z = zeros(3,1);
dominant_channel_pair = strings(3,1);
dominant_sign_pair = zeros(3,1);
dominance_ratio_pair = zeros(3,1);
expected_channel_pair = axis_name;
expected_delta_sign = ones(3,1);
pair_status = strings(3,1);

for i = 1:numel(axis_name)
    ax = axis_name(i);
    pid = pose_tbl.pose == ("pos_" + ax);
    nid = pose_tbl.pose == ("neg_" + ax);
    if ~any(pid) || ~any(nid)
        error("No hay pose positiva/negativa para eje %s.", ax);
    end

    delta_vec = [
        pose_tbl.mv_x_mean(pid) - pose_tbl.mv_x_mean(nid)
        pose_tbl.mv_y_mean(pid) - pose_tbl.mv_y_mean(nid)
        pose_tbl.mv_z_mean(pid) - pose_tbl.mv_z_mean(nid)
    ];

    delta_mv_x(i) = delta_vec(1);
    delta_mv_y(i) = delta_vec(2);
    delta_mv_z(i) = delta_vec(3);

    [dom_ch, dom_sign, dom_ratio] = get_dominance(delta_vec);
    pair_st = classify_status(dom_ch, dom_sign, dom_ratio, ax, 1, dominance_ratio_min);

    dominant_channel_pair(i) = dom_ch;
    dominant_sign_pair(i) = dom_sign;
    dominance_ratio_pair(i) = dom_ratio;
    pair_status(i) = pair_st;
end

pair_tbl = table( ...
    axis_name, delta_mv_x, delta_mv_y, delta_mv_z, ...
    dominant_channel_pair, dominant_sign_pair, dominance_ratio_pair, ...
    expected_channel_pair, expected_delta_sign, pair_status, ...
    'VariableNames', {'axis_pair','delta_mv_x','delta_mv_y','delta_mv_z', ...
    'dominant_channel_observed','dominant_sign_observed','dominance_ratio', ...
    'expected_channel','expected_sign','status'});

%% Conclusiones globales
has_ambiguous = any(pose_tbl.status == "ambiguous") || any(pair_tbl.status == "ambiguous");
has_perm = any(pose_tbl.status == "axis_permuted") || any(pair_tbl.status == "axis_permuted");
has_sign_issue = any(pose_tbl.status == "sign_inverted") || any(pair_tbl.status == "sign_inverted");

if ~has_ambiguous && ~has_perm && ~has_sign_issue
    high_level_conclusion = "mapping_ok";
    final_decision = "mapping_confirmed";
elseif ~has_ambiguous && ~has_perm && has_sign_issue
    high_level_conclusion = "sign_issue_detected";
    final_decision = "sign_correction_needed";
elseif ~has_ambiguous && has_perm && ~has_sign_issue
    high_level_conclusion = "axis_permutation_detected";
    final_decision = "axis_remap_needed";
elseif ~has_ambiguous && has_perm && has_sign_issue
    high_level_conclusion = "mixed_issue_detected";
    final_decision = "axis_remap_needed";
else
    high_level_conclusion = "inconclusive";
    final_decision = "mapping_inconclusive";
end

%% Guardado de artefactos
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
base = sensor_id + "_axis_convention_diagnosis_" + stamp;
run_csv_out = fullfile(analysis_out_dir, char(base + "_runs.csv"));
pose_csv_out = fullfile(analysis_out_dir, char(base + "_poses.csv"));
inference_csv_out = fullfile(analysis_out_dir, char(base + "_inference.csv"));
pair_csv_out = fullfile(analysis_out_dir, char(base + "_axis_pairs.csv"));
txt_out = fullfile(analysis_out_dir, char(base + ".txt"));

writetable(run_tbl, run_csv_out);
writetable(pose_tbl, pose_csv_out);
writetable(inference_tbl, inference_csv_out);
writetable(pair_tbl, pair_csv_out);

diag = struct();
diag.sensor_id = sensor_id;
diag.poses = poses;
diag.dataset_source = dataset_source;
diag.dataset_source_detail = dataset_source_detail;
diag.dominance_ratio_min = dominance_ratio_min;
diag.high_level_conclusion = high_level_conclusion;
diag.final_decision = final_decision;
diag.generated = struct( ...
    "run_csv", make_relpath(run_csv_out, repo_dir), ...
    "pose_csv", make_relpath(pose_csv_out, repo_dir), ...
    "inference_csv", make_relpath(inference_csv_out, repo_dir), ...
    "pair_csv", make_relpath(pair_csv_out, repo_dir), ...
    "summary_txt", make_relpath(txt_out, repo_dir));

fid = fopen(txt_out, "w");
if fid < 0
    error("No fue posible crear resumen de diagnostico: %s", txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/analysis/diagnose_sensorC_axis_convention.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "dataset_source: %s\n", dataset_source);
fprintf(fid, "dataset_source_detail: %s\n", dataset_source_detail);
fprintf(fid, "dominance_ratio_min: %.3f\n", dominance_ratio_min);
fprintf(fid, "run_csv: %s\n", make_relpath(run_csv_out, repo_dir));
fprintf(fid, "pose_csv: %s\n", make_relpath(pose_csv_out, repo_dir));
fprintf(fid, "inference_csv: %s\n", make_relpath(inference_csv_out, repo_dir));
fprintf(fid, "axis_pair_csv: %s\n", make_relpath(pair_csv_out, repo_dir));
fprintf(fid, "high_level_conclusion: %s\n", high_level_conclusion);
fprintf(fid, "final_decision: %s\n", final_decision);

fprintf("\nAXIS_DIAGNOSIS_OK\n");
fprintf("RUN_CSV: %s\n", make_relpath(run_csv_out, repo_dir));
fprintf("POSE_CSV: %s\n", make_relpath(pose_csv_out, repo_dir));
fprintf("INFERENCE_CSV: %s\n", make_relpath(inference_csv_out, repo_dir));
fprintf("AXIS_PAIR_CSV: %s\n", make_relpath(pair_csv_out, repo_dir));
fprintf("HIGH_LEVEL_CONCLUSION: %s\n", high_level_conclusion);
fprintf("FINAL_DECISION: %s\n", final_decision);

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

function [dom_channel, dom_sign, dom_ratio] = get_dominance(vec3)
labels = ["x";"y";"z"];
abs_vals = abs(vec3(:));
[dom_abs, id] = max(abs_vals);
dom_channel = labels(id);
dom_val = vec3(id);
dom_sign = sign(dom_val);

others = abs_vals;
others(id) = [];
cross_max = max(others);
dom_ratio = dom_abs / max(cross_max, eps);
end

function st = classify_status(dom_channel, dom_sign, dom_ratio, expected_channel, expected_sign, min_ratio)
if dom_ratio < min_ratio || dom_sign == 0
    st = "ambiguous";
elseif dom_channel ~= expected_channel
    st = "axis_permuted";
elseif dom_sign ~= expected_sign
    st = "sign_inverted";
else
    st = "ok";
end
end

function rel = make_relpath(abs_path, repo_dir)
rel = strrep(abs_path, [repo_dir filesep], "");
end
