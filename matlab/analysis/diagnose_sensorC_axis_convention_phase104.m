% diagnose_sensorC_axis_convention_phase104.m
% Diagnostico reforzado de convencion, signos y mapeo global para sensor_C.
%
% Convencion fisica del operador:
% - axis+ : el eje positivo del modulo apunta contra g
% - axis- : el eje positivo del modulo apunta a favor de g
%
% Resultado esperado por pose (para este analisis):
% - pos_x -> canal x con signo +1
% - neg_x -> canal x con signo -1
% - pos_y -> canal y con signo +1
% - neg_y -> canal y con signo -1
% - pos_z -> canal z con signo +1
% - neg_z -> canal z con signo -1

%% Configuracion
default_sensor_id = "sensor_C";
default_poses = ["pos_x","neg_x","pos_y","neg_y","pos_z","neg_z"];
default_use_latest_n_runs = 3;
default_dataset_manifest_relpath = ""; % opcional

default_dominance_ratio_pose_min = 1.30;
default_dominance_ratio_pair_min = 1.20;
default_pair_delta_floor_mv = 30; % evita decidir con deltas muy pequenos

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

if exist("dominance_ratio_pose_min", "var") && ~isempty(dominance_ratio_pose_min)
    dominance_ratio_pose_min = double(dominance_ratio_pose_min);
else
    dominance_ratio_pose_min = default_dominance_ratio_pose_min;
end

if exist("dominance_ratio_pair_min", "var") && ~isempty(dominance_ratio_pair_min)
    dominance_ratio_pair_min = double(dominance_ratio_pair_min);
else
    dominance_ratio_pair_min = default_dominance_ratio_pair_min;
end

if exist("pair_delta_floor_mv", "var") && ~isempty(pair_delta_floor_mv)
    pair_delta_floor_mv = double(pair_delta_floor_mv);
else
    pair_delta_floor_mv = default_pair_delta_floor_mv;
end

if use_latest_n_runs < 1 && strlength(dataset_manifest_relpath) == 0
    error("use_latest_n_runs debe ser >= 1 cuando no se usa manifest.");
end

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
raw_dir = fullfile(repo_dir, "data", "raw", char(sensor_id));
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
if ~isfolder(analysis_out_dir)
    mkdir(analysis_out_dir);
end

%% Seleccion de dataset
selected_by_pose = struct();
if strlength(dataset_manifest_relpath) > 0
    manifest_abs = fullfile(repo_dir, char(dataset_manifest_relpath));
    if ~isfile(manifest_abs)
        error("Manifest no encontrado: %s", manifest_abs);
    end
    manifest_tbl = readtable(manifest_abs, "Delimiter", ",", "TextType", "string");
    req_manifest = {'pose','run_file'};
    missing_manifest = setdiff(req_manifest, manifest_tbl.Properties.VariableNames);
    if ~isempty(missing_manifest)
        error("Manifest sin columnas requeridas: %s", strjoin(missing_manifest, ", "));
    end

    for i = 1:numel(poses)
        p = poses(i);
        files = string(manifest_tbl.run_file(manifest_tbl.pose == p));
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
        listing = dir(fullfile(raw_dir, pattern));
        if numel(listing) < use_latest_n_runs
            error("Pose %s con corridas insuficientes (%d < %d).", p, numel(listing), use_latest_n_runs);
        end
        [~, order] = sort([listing.datenum], "ascend");
        listing = listing(order);
        listing = listing((end-use_latest_n_runs+1):end);
        selected_by_pose.(char(p)) = string({listing.name})';
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
second_channel_observed = strings(0,1);
second_abs_value_mv = zeros(0,1);
dominant_abs_value_mv = zeros(0,1);
ambiguous_low_ratio = false(0,1);

expected_channel = strings(0,1);
expected_sign = zeros(0,1);
status = strings(0,1);

for i = 1:numel(poses)
    p = poses(i);
    [exp_channel, exp_sign] = expected_from_pose(p);
    files = selected_by_pose.(char(p));

    for k = 1:numel(files)
        csv_abs = fullfile(raw_dir, char(files(k)));
        if ~isfile(csv_abs)
            error("CSV no encontrado: %s", csv_abs);
        end

        tbl = readtable(csv_abs, "Delimiter", ",", "TextType", "string");
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
        raw_vec = [
            mean(double(tbl.raw_x))
            mean(double(tbl.raw_y))
            mean(double(tbl.raw_z))
        ];
        mv_vec = [
            mean(double(tbl.mv_x))
            mean(double(tbl.mv_y))
            mean(double(tbl.mv_z))
        ];

        [dom_ch, dom_sign, dom_ratio, dom_abs, snd_ch, snd_abs] = get_dominance_detail(mv_vec);
        st = classify_pose_status(dom_ch, dom_sign, dom_ratio, exp_channel, exp_sign, dominance_ratio_pose_min);
        low_ratio = dom_ratio < dominance_ratio_pose_min;

        run_pose(end+1,1) = p; %#ok<SAGROW>
        run_file(end+1,1) = string(files(k)); %#ok<SAGROW>
        samples(end+1,1) = n; %#ok<SAGROW>
        duration_s(end+1,1) = (t_us(end) - t_us(1)) / 1e6; %#ok<SAGROW>
        freq_hz(end+1,1) = (n - 1) / max(duration_s(end), eps); %#ok<SAGROW>
        seq_jumps(end+1,1) = nnz(diff(seq_col) ~= 1); %#ok<SAGROW>

        raw_x_mean(end+1,1) = raw_vec(1); %#ok<SAGROW>
        raw_y_mean(end+1,1) = raw_vec(2); %#ok<SAGROW>
        raw_z_mean(end+1,1) = raw_vec(3); %#ok<SAGROW>
        mv_x_mean(end+1,1) = mv_vec(1); %#ok<SAGROW>
        mv_y_mean(end+1,1) = mv_vec(2); %#ok<SAGROW>
        mv_z_mean(end+1,1) = mv_vec(3); %#ok<SAGROW>

        dominant_channel_observed(end+1,1) = dom_ch; %#ok<SAGROW>
        dominant_sign_observed(end+1,1) = dom_sign; %#ok<SAGROW>
        dominance_ratio(end+1,1) = dom_ratio; %#ok<SAGROW>
        second_channel_observed(end+1,1) = snd_ch; %#ok<SAGROW>
        second_abs_value_mv(end+1,1) = snd_abs; %#ok<SAGROW>
        dominant_abs_value_mv(end+1,1) = dom_abs; %#ok<SAGROW>
        ambiguous_low_ratio(end+1,1) = low_ratio; %#ok<SAGROW>

        expected_channel(end+1,1) = exp_channel; %#ok<SAGROW>
        expected_sign(end+1,1) = exp_sign; %#ok<SAGROW>
        status(end+1,1) = st; %#ok<SAGROW>
    end
end

run_tbl = table( ...
    run_pose, run_file, samples, duration_s, freq_hz, seq_jumps, ...
    raw_x_mean, raw_y_mean, raw_z_mean, ...
    mv_x_mean, mv_y_mean, mv_z_mean, ...
    dominant_channel_observed, dominant_sign_observed, dominance_ratio, ...
    dominant_abs_value_mv, second_channel_observed, second_abs_value_mv, ambiguous_low_ratio, ...
    expected_channel, expected_sign, status, ...
    'VariableNames', {'pose','run_file','samples','duration_s','freq_hz','seq_jumps', ...
    'raw_x_mean','raw_y_mean','raw_z_mean', ...
    'mv_x_mean','mv_y_mean','mv_z_mean', ...
    'dominant_channel_observed','dominant_sign_observed','dominance_ratio', ...
    'dominant_abs_value_mv','second_channel_observed','second_abs_value_mv','ambiguous_low_ratio', ...
    'expected_channel','expected_sign','status'});

%% Resumen por pose
pose_name = poses(:);
runs_found = zeros(numel(poses),1);
freq_mean_hz = zeros(numel(poses),1);
seq_jumps_total = zeros(numel(poses),1);

raw_x_mean_pose = zeros(numel(poses),1);
raw_y_mean_pose = zeros(numel(poses),1);
raw_z_mean_pose = zeros(numel(poses),1);
raw_x_std_pose = zeros(numel(poses),1);
raw_y_std_pose = zeros(numel(poses),1);
raw_z_std_pose = zeros(numel(poses),1);

mv_x_mean_pose = zeros(numel(poses),1);
mv_y_mean_pose = zeros(numel(poses),1);
mv_z_mean_pose = zeros(numel(poses),1);
mv_x_std_pose = zeros(numel(poses),1);
mv_y_std_pose = zeros(numel(poses),1);
mv_z_std_pose = zeros(numel(poses),1);

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
        error("Sin corridas para pose %s.", p);
    end

    runs_found(i) = height(s);
    freq_mean_hz(i) = mean(s.freq_hz);
    seq_jumps_total(i) = sum(s.seq_jumps);

    raw_x_mean_pose(i) = mean(s.raw_x_mean);
    raw_y_mean_pose(i) = mean(s.raw_y_mean);
    raw_z_mean_pose(i) = mean(s.raw_z_mean);
    raw_x_std_pose(i) = std(s.raw_x_mean);
    raw_y_std_pose(i) = std(s.raw_y_mean);
    raw_z_std_pose(i) = std(s.raw_z_mean);

    mv_x_mean_pose(i) = mean(s.mv_x_mean);
    mv_y_mean_pose(i) = mean(s.mv_y_mean);
    mv_z_mean_pose(i) = mean(s.mv_z_mean);
    mv_x_std_pose(i) = std(s.mv_x_mean);
    mv_y_std_pose(i) = std(s.mv_y_mean);
    mv_z_std_pose(i) = std(s.mv_z_mean);

    [dom_ch, dom_sign, dom_ratio] = get_dominance(mv_x_mean_pose(i), mv_y_mean_pose(i), mv_z_mean_pose(i));
    [exp_ch, exp_sign] = expected_from_pose(p);
    pose_st = classify_pose_status(dom_ch, dom_sign, dom_ratio, exp_ch, exp_sign, dominance_ratio_pose_min);

    pose_dominant_channel(i) = dom_ch;
    pose_dominant_sign(i) = dom_sign;
    pose_dominance_ratio(i) = dom_ratio;
    pose_expected_channel(i) = exp_ch;
    pose_expected_sign(i) = exp_sign;
    pose_status(i) = pose_st;
end

pose_tbl = table( ...
    pose_name, runs_found, freq_mean_hz, seq_jumps_total, ...
    raw_x_mean_pose, raw_y_mean_pose, raw_z_mean_pose, ...
    raw_x_std_pose, raw_y_std_pose, raw_z_std_pose, ...
    mv_x_mean_pose, mv_y_mean_pose, mv_z_mean_pose, ...
    mv_x_std_pose, mv_y_std_pose, mv_z_std_pose, ...
    pose_dominant_channel, pose_dominant_sign, pose_dominance_ratio, ...
    pose_expected_channel, pose_expected_sign, pose_status, ...
    'VariableNames', {'pose','runs_found','freq_mean_hz','seq_jumps_total', ...
    'raw_x_mean','raw_y_mean','raw_z_mean','raw_x_std','raw_y_std','raw_z_std', ...
    'mv_x_mean','mv_y_mean','mv_z_mean','mv_x_std','mv_y_std','mv_z_std', ...
    'dominant_channel_observed','dominant_sign_observed','dominance_ratio', ...
    'expected_channel','expected_sign','status'});

%% Analisis por pares (pos-neg)
axis_pair = ["x";"y";"z"];
delta_mv_x = zeros(3,1);
delta_mv_y = zeros(3,1);
delta_mv_z = zeros(3,1);

dominant_channel_pair = strings(3,1);
dominant_sign_pair = zeros(3,1);
dominance_ratio_pair = zeros(3,1);
dominant_abs_pair = zeros(3,1);
second_abs_pair = zeros(3,1);
expected_channel_pair = axis_pair;
expected_sign_pair = ones(3,1); % delta(pos-neg) esperado positivo
pair_status = strings(3,1);
pair_ambiguous_low_ratio = false(3,1);
pair_ambiguous_low_delta = false(3,1);

for i = 1:3
    ax = axis_pair(i);
    pos_id = pose_tbl.pose == ("pos_" + ax);
    neg_id = pose_tbl.pose == ("neg_" + ax);
    if ~any(pos_id) || ~any(neg_id)
        error("Falta par pos/neg para eje %s.", ax);
    end

    delta_vec = [
        pose_tbl.mv_x_mean(pos_id) - pose_tbl.mv_x_mean(neg_id)
        pose_tbl.mv_y_mean(pos_id) - pose_tbl.mv_y_mean(neg_id)
        pose_tbl.mv_z_mean(pos_id) - pose_tbl.mv_z_mean(neg_id)
    ];

    delta_mv_x(i) = delta_vec(1);
    delta_mv_y(i) = delta_vec(2);
    delta_mv_z(i) = delta_vec(3);

    [dom_ch, dom_sign, dom_ratio, dom_abs, ~, snd_abs] = get_dominance_detail(delta_vec);
    low_ratio = dom_ratio < dominance_ratio_pair_min;
    low_delta = dom_abs < pair_delta_floor_mv;

    if low_ratio || low_delta || dom_sign == 0
        p_status = "ambiguous";
    elseif dom_ch ~= ax
        p_status = "axis_permuted";
    elseif dom_sign ~= 1
        p_status = "sign_inverted";
    else
        p_status = "ok";
    end

    dominant_channel_pair(i) = dom_ch;
    dominant_sign_pair(i) = dom_sign;
    dominance_ratio_pair(i) = dom_ratio;
    dominant_abs_pair(i) = dom_abs;
    second_abs_pair(i) = snd_abs;
    pair_status(i) = p_status;
    pair_ambiguous_low_ratio(i) = low_ratio;
    pair_ambiguous_low_delta(i) = low_delta;
end

pair_tbl = table( ...
    axis_pair, delta_mv_x, delta_mv_y, delta_mv_z, ...
    dominant_channel_pair, dominant_sign_pair, dominance_ratio_pair, dominant_abs_pair, second_abs_pair, ...
    expected_channel_pair, expected_sign_pair, pair_status, pair_ambiguous_low_ratio, pair_ambiguous_low_delta, ...
    'VariableNames', {'axis_pair','delta_mv_x','delta_mv_y','delta_mv_z', ...
    'dominant_channel_observed','dominant_sign_observed','dominance_ratio','dominant_abs_mv','second_abs_mv', ...
    'expected_channel','expected_sign','status','ambiguous_low_ratio','ambiguous_low_delta'});

%% Inferencia global de mapeo (real_axis -> channel, sign)
real_axis = axis_pair;
inferred_channel = dominant_channel_pair;
inferred_sign = strings(3,1);
inferred_sign_code = dominant_sign_pair;
pair_ratio = dominance_ratio_pair;
pair_abs_mv = dominant_abs_pair;
mapping_status = strings(3,1);
mapping_notes = strings(3,1);

for i = 1:3
    if inferred_sign_code(i) > 0
        inferred_sign(i) = "sign_normal";
    elseif inferred_sign_code(i) < 0
        inferred_sign(i) = "sign_inverted";
    else
        inferred_sign(i) = "sign_ambiguous";
    end

    if pair_status(i) == "ambiguous"
        mapping_status(i) = "ambiguous";
        if pair_ambiguous_low_delta(i)
            mapping_notes(i) = "delta_too_small";
        elseif pair_ambiguous_low_ratio(i)
            mapping_notes(i) = "dominance_ratio_low";
        else
            mapping_notes(i) = "ambiguous_sign";
        end
    else
        mapping_status(i) = "candidate";
        mapping_notes(i) = "from_pair_delta";
    end
end

% Control de conflicto de canales repetidos
duplicate_conflict = false(3,1);
for i = 1:3
    if mapping_status(i) == "candidate"
        duplicate_conflict(i) = sum((inferred_channel == inferred_channel(i)) & (mapping_status == "candidate")) > 1;
        if duplicate_conflict(i)
            mapping_status(i) = "conflict";
            mapping_notes(i) = "channel_reused_by_multiple_axes";
        end
    end
end

mapping_tbl = table( ...
    real_axis, inferred_channel, inferred_sign, inferred_sign_code, ...
    pair_ratio, pair_abs_mv, mapping_status, mapping_notes, ...
    'VariableNames', {'real_axis','inferred_channel','inferred_sign','inferred_sign_code', ...
    'dominance_ratio','dominant_abs_mv','status','notes'});

%% Decision final global
any_seq_jumps = any(pose_tbl.seq_jumps_total > 0);
any_ambiguous = any(mapping_tbl.status == "ambiguous");
any_conflict = any(mapping_tbl.status == "conflict");

candidate_ok = mapping_tbl.status == "candidate";
all_candidate = all(candidate_ok);

if any_seq_jumps
    high_level_conclusion = "inconclusive";
    final_decision = "mapping_inconclusive";
elseif any_ambiguous
    high_level_conclusion = "inconclusive";
    final_decision = "mapping_inconclusive";
elseif any_conflict
    high_level_conclusion = "axis_permutation_detected";
    final_decision = "axis_remap_needed";
elseif all_candidate
    channels_match = all(mapping_tbl.real_axis == mapping_tbl.inferred_channel);
    any_sign_inverted = any(mapping_tbl.inferred_sign == "sign_inverted");

    if channels_match && ~any_sign_inverted
        high_level_conclusion = "mapping_ok";
        final_decision = "mapping_confirmed";
    elseif channels_match && any_sign_inverted
        high_level_conclusion = "sign_issue_detected";
        final_decision = "sign_correction_needed";
    else
        high_level_conclusion = "axis_permutation_detected";
        final_decision = "axis_remap_needed";
    end
else
    high_level_conclusion = "inconclusive";
    final_decision = "mapping_inconclusive";
end

%% Guardado de artefactos
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
base = sensor_id + "_axis_convention_phase104_" + stamp;

run_csv_out = fullfile(analysis_out_dir, char(base + "_runs.csv"));
pose_csv_out = fullfile(analysis_out_dir, char(base + "_poses.csv"));
pair_csv_out = fullfile(analysis_out_dir, char(base + "_pairs.csv"));
mapping_csv_out = fullfile(analysis_out_dir, char(base + "_mapping.csv"));
summary_txt_out = fullfile(analysis_out_dir, char(base + ".txt"));

writetable(run_tbl, run_csv_out);
writetable(pose_tbl, pose_csv_out);
writetable(pair_tbl, pair_csv_out);
writetable(mapping_tbl, mapping_csv_out);

fid = fopen(summary_txt_out, "w");
if fid < 0
    error("No fue posible crear resumen: %s", summary_txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/analysis/diagnose_sensorC_axis_convention_phase104.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "dataset_source: %s\n", dataset_source);
fprintf(fid, "dataset_source_detail: %s\n", dataset_source_detail);
fprintf(fid, "dominance_ratio_pose_min: %.3f\n", dominance_ratio_pose_min);
fprintf(fid, "dominance_ratio_pair_min: %.3f\n", dominance_ratio_pair_min);
fprintf(fid, "pair_delta_floor_mv: %.3f\n", pair_delta_floor_mv);
fprintf(fid, "run_csv: %s\n", make_relpath(run_csv_out, repo_dir));
fprintf(fid, "pose_csv: %s\n", make_relpath(pose_csv_out, repo_dir));
fprintf(fid, "pair_csv: %s\n", make_relpath(pair_csv_out, repo_dir));
fprintf(fid, "mapping_csv: %s\n", make_relpath(mapping_csv_out, repo_dir));
fprintf(fid, "high_level_conclusion: %s\n", high_level_conclusion);
fprintf(fid, "final_decision: %s\n", final_decision);

fprintf("\nAXIS_PHASE104_OK\n");
fprintf("RUN_CSV: %s\n", make_relpath(run_csv_out, repo_dir));
fprintf("POSE_CSV: %s\n", make_relpath(pose_csv_out, repo_dir));
fprintf("PAIR_CSV: %s\n", make_relpath(pair_csv_out, repo_dir));
fprintf("MAPPING_CSV: %s\n", make_relpath(mapping_csv_out, repo_dir));
fprintf("HIGH_LEVEL_CONCLUSION: %s\n", high_level_conclusion);
fprintf("FINAL_DECISION: %s\n", final_decision);

%% Funciones locales
function [channel, sign_val] = expected_from_pose(pose_name)
if startsWith(pose_name, "pos_")
    sign_val = 1;
elseif startsWith(pose_name, "neg_")
    sign_val = -1;
else
    error("Pose no reconocida: %s", pose_name);
end

channel = extractAfter(pose_name, 4);
if ~ismember(channel, ["x","y","z"])
    error("Pose con eje invalido: %s", pose_name);
end
end

function [dom_ch, dom_sign, dom_ratio] = get_dominance(vx, vy, vz)
vec = [vx; vy; vz];
[dom_ch, dom_sign, dom_ratio] = get_dominance_detail(vec);
end

function [dom_ch, dom_sign, dom_ratio, dom_abs, snd_ch, snd_abs] = get_dominance_detail(vec3)
labels = ["x";"y";"z"];
abs_vals = abs(vec3(:));
[sorted_abs, idx] = sort(abs_vals, "descend");

dom_idx = idx(1);
snd_idx = idx(2);
dom_ch = labels(dom_idx);
snd_ch = labels(snd_idx);

dom_abs = sorted_abs(1);
snd_abs = sorted_abs(2);
dom_ratio = dom_abs / max(snd_abs, eps);
dom_sign = sign(vec3(dom_idx));
end

function out = classify_pose_status(dom_ch, dom_sign, dom_ratio, exp_ch, exp_sign, ratio_min)
if dom_ratio < ratio_min || dom_sign == 0
    out = "ambiguous";
elseif dom_ch ~= exp_ch
    out = "axis_permuted";
elseif dom_sign ~= exp_sign
    out = "sign_inverted";
else
    out = "ok";
end
end

function rel = make_relpath(abs_path, repo_dir)
rel = strrep(abs_path, [repo_dir filesep], "");
end
