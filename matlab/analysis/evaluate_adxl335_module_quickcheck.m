% evaluate_adxl335_module_quickcheck.m
% Fase 12: evaluacion rapida (5-15 min) para clasificar un nuevo modulo ADXL335.
%
% Estados de salida:
% - ready_for_operational_use
% - ready_for_operational_use_provisional
% - hardware_review_needed
% - rejected_module

%% Configuracion de entrada
if exist("module_id", "var") && strlength(string(module_id)) > 0
    module_id = string(module_id);
elseif exist("sensor_id", "var") && strlength(string(sensor_id)) > 0
    module_id = string(sensor_id);
else
    module_id = "adxl335_module_new";
end

if ~exist("quickcheck_run_file", "var")
    quickcheck_run_file = "";
else
    quickcheck_run_file = string(quickcheck_run_file);
end

if ~exist("quickcheck_pose_label", "var") || strlength(string(quickcheck_pose_label)) == 0
    quickcheck_pose_label = "quickcheck_static";
else
    quickcheck_pose_label = string(quickcheck_pose_label);
end

if ~exist("module_template_json_relpath", "var") || strlength(string(module_template_json_relpath)) == 0
    module_template_json_relpath = "config/adxl335_module_template.json";
else
    module_template_json_relpath = string(module_template_json_relpath);
end

if ~exist("write_outputs", "var") || isempty(write_outputs)
    write_outputs = true;
else
    write_outputs = logical(write_outputs);
end

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
raw_dir = fullfile(repo_dir, "data", "raw", char(module_id));
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
if ~isfolder(analysis_out_dir)
    mkdir(analysis_out_dir);
end

template_abs = fullfile(repo_dir, char(module_template_json_relpath));
if ~isfile(template_abs)
    error("No existe template JSON: %s", template_abs);
end
template_cfg = jsondecode(fileread(template_abs));
thr = template_cfg.quickcheck.thresholds;

if ~isfield(thr, "min_raw_span_counts")
    thr.min_raw_span_counts = 4;
end
if ~isfield(thr, "stuck_rail_span_max")
    thr.stuck_rail_span_max = 2;
end

run_csv_abs = resolve_run_csv(repo_dir, raw_dir, module_id, quickcheck_pose_label, quickcheck_run_file);
run_file = string(get_filename(run_csv_abs));

% Carga de datos
required_cols = {'seq','t_us','raw_x','raw_y','raw_z','mv_x','mv_y','mv_z'};
tbl = readtable(run_csv_abs, "Delimiter", ",", "TextType", "string");
missing_cols = setdiff(required_cols, tbl.Properties.VariableNames);
if ~isempty(missing_cols)
    error("CSV incompleto (%s): %s", run_csv_abs, strjoin(missing_cols, ", "));
end
tbl = tbl(:, required_cols);

seq = double(tbl.seq);
t_us = double(tbl.t_us);
raw_x = double(tbl.raw_x);
raw_y = double(tbl.raw_y);
raw_z = double(tbl.raw_z);
raw_mat = [raw_x, raw_y, raw_z];
axes_names = ["x"; "y"; "z"];

n_samples = height(tbl);
if n_samples < 2
    error("Corrida insuficiente para quickcheck: %s", run_csv_abs);
end

seq_jumps = nnz(diff(seq) ~= 1);
stream_duration_s = max(0, (t_us(end) - t_us(1)) / 1e6);
if stream_duration_s > 0
    freq_hz = (n_samples - 1) / stream_duration_s;
else
    freq_hz = NaN;
end

raw_mean = mean(raw_mat, 1);
raw_std = std(raw_mat, 0, 1);
raw_min = min(raw_mat, [], 1);
raw_max = max(raw_mat, [], 1);
raw_span = raw_max - raw_min;

sat_hi_pct = 100 .* mean(raw_mat >= double(thr.sat_hi_raw), 1);
sat_lo_pct = 100 .* mean(raw_mat <= double(thr.sat_lo_raw), 1);
sat_any_pct = sat_hi_pct + sat_lo_pct;
max_sat_pct = max(sat_any_pct);

stuck_rail = (raw_span <= double(thr.stuck_rail_span_max)) & ...
    ((raw_mean >= (double(thr.sat_hi_raw) - 1)) | (raw_mean <= (double(thr.sat_lo_raw) + 1)));

stream_wide_ok = n_samples >= double(thr.min_samples) && ...
    seq_jumps <= double(thr.seq_jumps_max) && ...
    freq_hz >= double(thr.freq_hz_min) && freq_hz <= double(thr.freq_hz_max);

stream_strict_ok = stream_wide_ok && ...
    freq_hz >= double(thr.strict_freq_hz_min) && freq_hz <= double(thr.strict_freq_hz_max);

sat_ready_ok = max_sat_pct <= double(thr.sat_pct_ready_max);
sat_provisional_ok = max_sat_pct <= double(thr.sat_pct_review_max);
hard_saturation = any(sat_any_pct >= double(thr.sat_pct_reject_min));
min_span_ok = all(raw_span >= double(thr.min_raw_span_counts));

reasons = strings(0, 1);
if ~stream_wide_ok
    reasons(end+1, 1) = "stream_out_of_bounds";
end
if ~stream_strict_ok
    reasons(end+1, 1) = "freq_not_strict";
end
if ~sat_ready_ok
    reasons(end+1, 1) = "saturation_above_ready_limit";
end
if ~sat_provisional_ok
    reasons(end+1, 1) = "saturation_above_provisional_limit";
end
if hard_saturation
    reasons(end+1, 1) = "hard_saturation_detected";
end
if any(stuck_rail)
    reasons(end+1, 1) = "stuck_rail_detected";
end
if ~min_span_ok
    reasons(end+1, 1) = "low_raw_span_detected";
end

if hard_saturation || any(stuck_rail)
    final_state = "rejected_module";
    next_action = "replace_or_rewire_module_then_repeat_quickcheck_only";
elseif stream_wide_ok && stream_strict_ok && sat_ready_ok && min_span_ok
    final_state = "ready_for_operational_use";
    next_action = "register_module_and_continue";
elseif stream_wide_ok && sat_provisional_ok
    final_state = "ready_for_operational_use_provisional";
    next_action = "register_as_provisional_and_continue";
else
    final_state = "hardware_review_needed";
    next_action = "review_wiring_and_retake_single_quickcheck";
end

st_diagnostic_recommended = ismember(final_state, ["hardware_review_needed", "rejected_module"]);

quickcheck_result = struct();
quickcheck_result.module_id = module_id;
quickcheck_result.run_file = run_file;
quickcheck_result.n_samples = n_samples;
quickcheck_result.seq_jumps = seq_jumps;
quickcheck_result.stream_duration_s = stream_duration_s;
quickcheck_result.freq_hz = freq_hz;
quickcheck_result.max_sat_pct = max_sat_pct;
quickcheck_result.final_state = final_state;
quickcheck_result.next_action = next_action;
quickcheck_result.st_diagnostic_recommended = st_diagnostic_recommended;
quickcheck_result.reasons = reasons;
quickcheck_result.template_json = module_template_json_relpath;

axis_tbl = table( ...
    axes_names, raw_mean(:), raw_std(:), raw_min(:), raw_max(:), raw_span(:), ...
    sat_hi_pct(:), sat_lo_pct(:), sat_any_pct(:), stuck_rail(:), ...
    'VariableNames', {'axis','raw_mean','raw_std','raw_min','raw_max','raw_span','sat_hi_pct','sat_lo_pct','sat_any_pct','stuck_rail'});

if write_outputs
    stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
    base_name = module_id + "_phase12_quickcheck_" + stamp;
    summary_txt_out = fullfile(analysis_out_dir, char(base_name + ".txt"));
    axis_csv_out = fullfile(analysis_out_dir, char(base_name + "_axes.csv"));

    writetable(axis_tbl, axis_csv_out);
    write_summary(summary_txt_out, quickcheck_result, axis_tbl, repo_dir, run_csv_abs);

    quickcheck_result.summary_txt = make_relpath(summary_txt_out, repo_dir);
    quickcheck_result.axis_csv = make_relpath(axis_csv_out, repo_dir);
else
    quickcheck_result.summary_txt = "not_generated";
    quickcheck_result.axis_csv = "not_generated";
end

fprintf("\nPHASE12_QUICKCHECK_OK\n");
fprintf("MODULE_ID: %s\n", module_id);
fprintf("RUN_FILE: %s\n", run_file);
fprintf("FINAL_STATE: %s\n", final_state);
fprintf("N_SAMPLES: %d\n", n_samples);
fprintf("FREQ_HZ: %.3f\n", freq_hz);
fprintf("SEQ_JUMPS: %d\n", seq_jumps);
fprintf("MAX_SAT_PCT: %.3f\n", max_sat_pct);
fprintf("ST_DIAGNOSTIC_RECOMMENDED: %s\n", string(st_diagnostic_recommended));
fprintf("SUMMARY_TXT: %s\n", quickcheck_result.summary_txt);
fprintf("AXIS_CSV: %s\n", quickcheck_result.axis_csv);

%% Local functions
function run_csv_abs = resolve_run_csv(repo_dir, raw_dir, module_id, quickcheck_pose_label, quickcheck_run_file)
if strlength(quickcheck_run_file) > 0
    candidate = char(quickcheck_run_file);
    if isfile(candidate)
        run_csv_abs = string(candidate);
        return;
    end

    in_raw = fullfile(raw_dir, candidate);
    if isfile(in_raw)
        run_csv_abs = string(in_raw);
        return;
    end

    in_repo = fullfile(repo_dir, candidate);
    if isfile(in_repo)
        run_csv_abs = string(in_repo);
        return;
    end
    error("quickcheck_run_file no encontrado: %s", quickcheck_run_file);
end

if ~isfolder(raw_dir)
    error("No existe carpeta raw para modulo %s: %s", module_id, raw_dir);
end

pattern = module_id + "_" + quickcheck_pose_label + "_*.csv";
listing = dir(fullfile(raw_dir, char(pattern)));
if isempty(listing)
    error("No se encontro corrida quickcheck con patron: %s", pattern);
end
[~, idx] = sort([listing.datenum], "ascend");
listing = listing(idx);
run_csv_abs = string(fullfile(listing(end).folder, listing(end).name));
end

function write_summary(summary_txt_out, result, axis_tbl, repo_dir, run_csv_abs)
fid = fopen(summary_txt_out, "w");
if fid < 0
    error("No fue posible crear resumen quickcheck: %s", summary_txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/analysis/evaluate_adxl335_module_quickcheck.m\n");
fprintf(fid, "module_id: %s\n", result.module_id);
fprintf(fid, "run_file: %s\n", result.run_file);
fprintf(fid, "run_csv_relpath: %s\n", make_relpath(run_csv_abs, repo_dir));
fprintf(fid, "n_samples: %d\n", result.n_samples);
fprintf(fid, "seq_jumps: %d\n", result.seq_jumps);
fprintf(fid, "stream_duration_s: %.6f\n", result.stream_duration_s);
fprintf(fid, "freq_hz: %.6f\n", result.freq_hz);
fprintf(fid, "max_sat_pct: %.6f\n", result.max_sat_pct);
fprintf(fid, "final_state: %s\n", result.final_state);
fprintf(fid, "next_action: %s\n", result.next_action);
fprintf(fid, "st_diagnostic_recommended: %s\n", string(result.st_diagnostic_recommended));
if numel(result.reasons) == 0
    fprintf(fid, "reasons: none\n");
else
    fprintf(fid, "reasons: %s\n", strjoin(result.reasons, "|"));
end
fprintf(fid, "template_json: %s\n", result.template_json);

for i = 1:height(axis_tbl)
    axis_name = axis_tbl.axis(i);
    fprintf(fid, "axis_%s_raw_mean: %.6f\n", axis_name, axis_tbl.raw_mean(i));
    fprintf(fid, "axis_%s_raw_std: %.6f\n", axis_name, axis_tbl.raw_std(i));
    fprintf(fid, "axis_%s_raw_span: %.6f\n", axis_name, axis_tbl.raw_span(i));
    fprintf(fid, "axis_%s_sat_hi_pct: %.6f\n", axis_name, axis_tbl.sat_hi_pct(i));
    fprintf(fid, "axis_%s_sat_lo_pct: %.6f\n", axis_name, axis_tbl.sat_lo_pct(i));
    fprintf(fid, "axis_%s_sat_any_pct: %.6f\n", axis_name, axis_tbl.sat_any_pct(i));
    fprintf(fid, "axis_%s_stuck_rail: %s\n", axis_name, string(axis_tbl.stuck_rail(i)));
end
end

function rel = make_relpath(abs_path, repo_dir)
rel = strrep(char(abs_path), [repo_dir filesep], "");
end

function name = get_filename(path_str)
[~, n, e] = fileparts(char(path_str));
name = string([n e]);
end
