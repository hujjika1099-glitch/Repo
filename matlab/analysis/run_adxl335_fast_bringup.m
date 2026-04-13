% run_adxl335_fast_bringup.m
% Fase 12: flujo minimo para incorporar nuevos modulos ADXL335 sin campanas largas.
%
% Flujo:
% 1) captura corta (opcional, por defecto ON)
% 2) evaluacion quickcheck automatica
% 3) registro liviano del modulo

%% Configuracion
if exist("module_id", "var") && strlength(string(module_id)) > 0
    module_id = string(module_id);
elseif exist("sensor_id", "var") && strlength(string(sensor_id)) > 0
    module_id = string(sensor_id);
else
    module_id = "adxl335_module_new";
end

if ~exist("port", "var") || strlength(string(port)) == 0
    env_port = string(getenv("ADXL_PORT"));
    if strlength(env_port) > 0
        port = env_port;
    else
        port = "";
    end
else
    port = string(port);
end

if ~exist("baud", "var") || isempty(baud)
    baud = 115200;
end

if ~exist("module_template_json_relpath", "var") || strlength(string(module_template_json_relpath)) == 0
    module_template_json_relpath = "config/adxl335_module_template.json";
else
    module_template_json_relpath = string(module_template_json_relpath);
end

if ~exist("run_capture", "var") || isempty(run_capture)
    run_capture = true;
else
    run_capture = logical(run_capture);
end

if ~exist("quickcheck_run_file", "var")
    quickcheck_run_file = "";
else
    quickcheck_run_file = string(quickcheck_run_file);
end

if ~exist("notes", "var")
    notes = "";
else
    notes = string(notes);
end

%% Rutas y template
% Usar nombres unicos evita colisiones de workspace cuando se encadenan scripts con run(...)
bringup_script_dir = fileparts(mfilename("fullpath"));
bringup_repo_dir = fileparts(fileparts(bringup_script_dir));
bringup_analysis_out_dir = fullfile(bringup_repo_dir, "reports", "analysis_outputs");
if ~isfolder(bringup_analysis_out_dir)
    mkdir(bringup_analysis_out_dir);
end

template_abs = fullfile(bringup_repo_dir, char(module_template_json_relpath));
if ~isfile(template_abs)
    error("No existe template JSON: %s", template_abs);
end
template_cfg = jsondecode(fileread(template_abs));

if ~isfield(template_cfg, "registry_relpath") || strlength(string(template_cfg.registry_relpath)) == 0
    registry_relpath = "hardware/module_registry_fast_bringup.csv";
else
    registry_relpath = string(template_cfg.registry_relpath);
end

if ~exist("duration_s", "var") || isempty(duration_s)
    duration_s = double(template_cfg.quickcheck.duration_s);
end

if ~exist("quickcheck_pose_label", "var") || strlength(string(quickcheck_pose_label)) == 0
    quickcheck_pose_label = string(template_cfg.quickcheck.pose_label);
else
    quickcheck_pose_label = string(quickcheck_pose_label);
end

if ~exist("write_outputs", "var") || isempty(write_outputs)
    write_outputs = true;
else
    write_outputs = logical(write_outputs);
end

bringup_result = struct();
bringup_result.module_id = module_id;
bringup_result.port = port;
bringup_result.baud = baud;
bringup_result.duration_s = duration_s;
bringup_result.quickcheck_pose_label = quickcheck_pose_label;
bringup_result.run_capture = run_capture;
bringup_result.quickcheck_run_file = "";
bringup_result.final_state = "not_run";
bringup_result.next_action = "not_available";
bringup_result.registry_relpath = registry_relpath;

% 1) Captura corta (opcional)
if run_capture
    sensor_id = module_id;
    pose_label = quickcheck_pose_label;
    run(fullfile(bringup_repo_dir, "matlab", "calibration", "capture_single_sensor_baseline.m"));

    if ~exist("csv_path", "var") || strlength(string(csv_path)) == 0
        error("No se encontro csv_path tras captura quickcheck.");
    end
    bringup_result.port = string(port);
    quickcheck_run_file = string(get_filename(string(csv_path)));
end

% 2) Evaluacion quickcheck
sensor_id = module_id;
run(fullfile(bringup_script_dir, "evaluate_adxl335_module_quickcheck.m"));

if ~exist("quickcheck_result", "var") || ~isstruct(quickcheck_result)
    error("No se obtuvo quickcheck_result desde evaluate_adxl335_module_quickcheck.");
end

bringup_result.quickcheck_run_file = string(quickcheck_result.run_file);
bringup_result.final_state = string(quickcheck_result.final_state);
bringup_result.next_action = string(quickcheck_result.next_action);
bringup_result.quickcheck_summary_txt = string(quickcheck_result.summary_txt);
bringup_result.quickcheck_axis_csv = string(quickcheck_result.axis_csv);
bringup_result.st_diagnostic_recommended = logical(quickcheck_result.st_diagnostic_recommended);

% 3) Registro liviano
registry_abs = fullfile(bringup_repo_dir, char(registry_relpath));
ensure_parent_dir(registry_abs);
append_registry_row(registry_abs, bringup_result, quickcheck_result, notes);

% 4) Resumen Fase 12
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
summary_txt_out = fullfile(bringup_analysis_out_dir, char(module_id + "_phase12_fast_bringup_" + stamp + ".txt"));
write_bringup_summary(summary_txt_out, bringup_result, quickcheck_result, registry_abs, notes, bringup_repo_dir);
bringup_result.summary_txt = make_relpath(summary_txt_out, bringup_repo_dir);
bringup_result.registry_relpath = make_relpath(registry_abs, bringup_repo_dir);

fprintf("\nPHASE12_FAST_BRINGUP_OK\n");
fprintf("MODULE_ID: %s\n", module_id);
fprintf("RUN_FILE: %s\n", bringup_result.quickcheck_run_file);
fprintf("FINAL_STATE: %s\n", bringup_result.final_state);
fprintf("NEXT_ACTION: %s\n", bringup_result.next_action);
fprintf("QUICKCHECK_SUMMARY: %s\n", bringup_result.quickcheck_summary_txt);
fprintf("REGISTRY: %s\n", bringup_result.registry_relpath);
fprintf("SUMMARY_TXT: %s\n", bringup_result.summary_txt);

%% Local functions
function write_bringup_summary(summary_txt_out, bringup_result, quickcheck_result, registry_abs, notes, repo_dir)
fid = fopen(summary_txt_out, "w");
if fid < 0
    error("No fue posible crear resumen Fase12: %s", summary_txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/analysis/run_adxl335_fast_bringup.m\n");
fprintf(fid, "module_id: %s\n", bringup_result.module_id);
fprintf(fid, "port: %s\n", bringup_result.port);
fprintf(fid, "baud: %d\n", bringup_result.baud);
fprintf(fid, "duration_s: %.3f\n", bringup_result.duration_s);
fprintf(fid, "quickcheck_pose_label: %s\n", bringup_result.quickcheck_pose_label);
fprintf(fid, "run_capture: %s\n", string(bringup_result.run_capture));
fprintf(fid, "quickcheck_run_file: %s\n", bringup_result.quickcheck_run_file);
fprintf(fid, "final_state: %s\n", bringup_result.final_state);
fprintf(fid, "next_action: %s\n", bringup_result.next_action);
fprintf(fid, "st_diagnostic_recommended: %s\n", string(bringup_result.st_diagnostic_recommended));
fprintf(fid, "quickcheck_summary_txt: %s\n", bringup_result.quickcheck_summary_txt);
fprintf(fid, "quickcheck_axis_csv: %s\n", bringup_result.quickcheck_axis_csv);
fprintf(fid, "registry_relpath: %s\n", make_relpath(registry_abs, repo_dir));
if strlength(notes) > 0
    fprintf(fid, "notes: %s\n", notes);
end

if isfield(quickcheck_result, "reasons")
    if numel(quickcheck_result.reasons) == 0
        fprintf(fid, "quickcheck_reasons: none\n");
    else
        fprintf(fid, "quickcheck_reasons: %s\n", strjoin(quickcheck_result.reasons, "|"));
    end
end
end

function append_registry_row(registry_abs, bringup_result, quickcheck_result, notes)
row = table( ...
    string(bringup_result.module_id), ...
    string(datetime("now", "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss Z")), ...
    string(bringup_result.port), ...
    string(bringup_result.quickcheck_run_file), ...
    string(bringup_result.final_state), ...
    double(quickcheck_result.n_samples), ...
    double(quickcheck_result.freq_hz), ...
    double(quickcheck_result.seq_jumps), ...
    double(quickcheck_result.max_sat_pct), ...
    string(bringup_result.next_action), ...
    logical(bringup_result.st_diagnostic_recommended), ...
    string(notes), ...
    'VariableNames', {'module_id','run_timestamp','port','run_file','final_state','samples','freq_hz','seq_jumps','max_sat_pct','next_action','st_diagnostic_recommended','notes'});

if isfile(registry_abs)
    try
        writetable(row, registry_abs, "WriteMode", "Append");
    catch
        prev = readtable(registry_abs, "TextType", "string");
        out = [prev; row];
        writetable(out, registry_abs);
    end
else
    writetable(row, registry_abs);
end
end

function ensure_parent_dir(path_abs)
parent_dir = fileparts(path_abs);
if ~isfolder(parent_dir)
    mkdir(parent_dir);
end
end

function rel = make_relpath(abs_path, repo_dir)
rel = strrep(char(abs_path), [repo_dir filesep], "");
end

function name = get_filename(path_str)
[~, n, e] = fileparts(char(path_str));
name = string([n e]);
end
