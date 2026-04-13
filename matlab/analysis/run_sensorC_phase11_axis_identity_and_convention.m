% run_sensorC_phase11_axis_identity_and_convention.m
% Orquestador Fase 11:
% 1) ST identity check (opcional, corto).
% 2) Construccion de config de convencion (si ST cierra identidad).
% 3) Interpretacion operativa desacoplada sobre baseline Fase 10.

%% Configuracion
if ~exist("sensor_id", "var") || strlength(string(sensor_id)) == 0
    sensor_id = "sensor_C";
else
    sensor_id = string(sensor_id);
end

if ~exist("run_selftest_identity", "var") || isempty(run_selftest_identity)
    run_selftest_identity = true;
end

if ~exist("st_off_run_file", "var")
    st_off_run_file = "";
else
    st_off_run_file = string(st_off_run_file);
end

if ~exist("st_on_run_file", "var")
    st_on_run_file = "";
else
    st_on_run_file = string(st_on_run_file);
end

if ~exist("base_convention_json_relpath", "var") || strlength(string(base_convention_json_relpath)) == 0
    base_convention_json_relpath = "config/sensor_C_axis_convention_phase11.json";
else
    base_convention_json_relpath = string(base_convention_json_relpath);
end

if ~exist("baseline_calibration_mat_relpath", "var") || strlength(string(baseline_calibration_mat_relpath)) == 0
    baseline_calibration_mat_relpath = "data/processed/sensor_C_static_calibration_20260321_140044.mat";
else
    baseline_calibration_mat_relpath = string(baseline_calibration_mat_relpath);
end

if ~exist("dataset_manifest_relpath", "var") || strlength(string(dataset_manifest_relpath)) == 0
    dataset_manifest_relpath = "reports/analysis_outputs/sensor_C_static_calibration_20260321_140044_dataset.csv";
else
    dataset_manifest_relpath = string(dataset_manifest_relpath);
end

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
config_dir = fullfile(repo_dir, "config");
if ~isfolder(analysis_out_dir)
    mkdir(analysis_out_dir);
end
if ~isfolder(config_dir)
    mkdir(config_dir);
end

phase11_result = struct();
phase11_result.sensor_id = sensor_id;
phase11_result.started_at = string(datetime("now", "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss Z"));
phase11_result.run_selftest_identity = run_selftest_identity;
phase11_result.selftest = struct("final_decision", "skipped", "identity_status", "unknown");
phase11_result.selected_convention_json_relpath = base_convention_json_relpath;
phase11_result.operational = struct("final_decision", "not_run");

% 1) Self-test identity (opcional)
if run_selftest_identity
    run(fullfile(script_dir, "run_sensorC_selftest_identity_check.m"));
    if exist("selftest_result", "var")
        phase11_result.selftest = selftest_result;

        if isfield(selftest_result, "identity_status") && string(selftest_result.identity_status) == "identity_closed"
            resolved_relpath = build_resolved_convention_json( ...
                repo_dir, base_convention_json_relpath, selftest_result, baseline_calibration_mat_relpath);
            phase11_result.selected_convention_json_relpath = resolved_relpath;
        end
    end
end

% 2) Interpretacion operativa desacoplada
convention_json_relpath = string(phase11_result.selected_convention_json_relpath);
calibration_mat_relpath = baseline_calibration_mat_relpath;
run(fullfile(script_dir, "run_sensorC_phase11_operational_interpretation.m"));
if exist("phase11_operational_result", "var")
    phase11_result.operational = phase11_operational_result;
end

% 3) Resumen del orquestador
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
summary_txt_out = fullfile(analysis_out_dir, char(sensor_id + "_phase11_axis_identity_and_convention_" + stamp + ".txt"));

fid = fopen(summary_txt_out, "w");
if fid < 0
    error("No fue posible crear resumen Fase11 orchestrator: %s", summary_txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/analysis/run_sensorC_phase11_axis_identity_and_convention.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "run_selftest_identity: %s\n", string(run_selftest_identity));
fprintf(fid, "baseline_calibration_mat_relpath: %s\n", baseline_calibration_mat_relpath);
fprintf(fid, "dataset_manifest_relpath: %s\n", dataset_manifest_relpath);
fprintf(fid, "base_convention_json_relpath: %s\n", base_convention_json_relpath);

if isstruct(phase11_result.selftest)
    if isfield(phase11_result.selftest, "final_decision")
        fprintf(fid, "selftest_final_decision: %s\n", string(phase11_result.selftest.final_decision));
    end
    if isfield(phase11_result.selftest, "identity_status")
        fprintf(fid, "selftest_identity_status: %s\n", string(phase11_result.selftest.identity_status));
    end
    if isfield(phase11_result.selftest, "confidence")
        fprintf(fid, "selftest_confidence: %.6f\n", double(phase11_result.selftest.confidence));
    end
end

fprintf(fid, "selected_convention_json_relpath: %s\n", string(phase11_result.selected_convention_json_relpath));

if isstruct(phase11_result.operational) && isfield(phase11_result.operational, "final_decision")
    fprintf(fid, "operational_final_decision: %s\n", string(phase11_result.operational.final_decision));
end
if isstruct(phase11_result.operational) && isfield(phase11_result.operational, "promotion_decision")
    fprintf(fid, "operational_promotion_decision: %s\n", string(phase11_result.operational.promotion_decision));
end
if isstruct(phase11_result.operational) && isfield(phase11_result.operational, "run_csv")
    fprintf(fid, "operational_run_csv: %s\n", string(phase11_result.operational.run_csv));
end
if isstruct(phase11_result.operational) && isfield(phase11_result.operational, "pose_csv")
    fprintf(fid, "operational_pose_csv: %s\n", string(phase11_result.operational.pose_csv));
end
if isstruct(phase11_result.operational) && isfield(phase11_result.operational, "pair_csv")
    fprintf(fid, "operational_pair_csv: %s\n", string(phase11_result.operational.pair_csv));
end

phase11_result.summary_txt = make_relpath(summary_txt_out, repo_dir);

fprintf("\nPHASE11_AXIS_IDENTITY_AND_CONVENTION_OK\n");
fprintf("SELECTED_CONVENTION_JSON: %s\n", string(phase11_result.selected_convention_json_relpath));
if isstruct(phase11_result.operational) && isfield(phase11_result.operational, "final_decision")
    fprintf("FINAL_DECISION: %s\n", string(phase11_result.operational.final_decision));
end
fprintf("SUMMARY_TXT: %s\n", phase11_result.summary_txt);

%% Local functions
function relpath = build_resolved_convention_json(repo_dir, base_convention_json_relpath, selftest_result, baseline_calibration_mat_relpath)
base_abs = fullfile(repo_dir, char(base_convention_json_relpath));
if ~isfile(base_abs)
    error("No existe base_convention_json: %s", base_abs);
end

base_cfg = jsondecode(fileread(base_abs));
if ~isfield(base_cfg, "identity")
    base_cfg.identity = struct();
end
if ~isfield(base_cfg.identity, "channel_to_chip_axis")
    base_cfg.identity.channel_to_chip_axis = struct("x", "x", "y", "y", "z", "z");
end

base_cfg.identity.status = "identity_closed";
base_cfg.identity.method = "adxl335_selftest_signature";
if isfield(selftest_result, "confidence")
    base_cfg.identity.confidence = double(selftest_result.confidence);
else
    base_cfg.identity.confidence = 0.0;
end
if isfield(selftest_result, "reason")
    base_cfg.identity.evidence = char(selftest_result.reason);
else
    base_cfg.identity.evidence = "st_signature_supported";
end
if isfield(selftest_result, "st_off_run_file")
    base_cfg.identity.st_off_run_file = char(selftest_result.st_off_run_file);
end
if isfield(selftest_result, "st_on_run_file")
    base_cfg.identity.st_on_run_file = char(selftest_result.st_on_run_file);
end
if isfield(selftest_result, "channel_to_chip_axis")
    base_cfg.identity.channel_to_chip_axis = selftest_result.channel_to_chip_axis;
end

if ~isfield(base_cfg, "convention")
    base_cfg.convention = struct();
end
if ~isfield(base_cfg.convention, "definition")
    base_cfg.convention.definition = "axis_plus_points_against_gravity";
end
if ~isfield(base_cfg.convention, "chip_axis_to_operational_axis")
    base_cfg.convention.chip_axis_to_operational_axis = struct("x", "x", "y", "y", "z", "z");
end
if ~isfield(base_cfg.convention, "chip_axis_sign_to_operational")
    base_cfg.convention.chip_axis_sign_to_operational = struct("x", 1, "y", 1, "z", 1);
end

base_cfg.baseline_calibration_mat_relpath = char(baseline_calibration_mat_relpath);
base_cfg.updated_at = char(string(datetime("now", "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss Z")));
base_cfg.phase = "phase11_axis_identity_and_convention";

out_name = "sensor_C_axis_convention_phase11_resolved_" + string(datetime("now", "Format", "yyyyMMdd_HHmmss")) + ".json";
out_abs = fullfile(repo_dir, "config", char(out_name));

try
    json_txt = jsonencode(base_cfg, PrettyPrint=true);
catch
    json_txt = jsonencode(base_cfg);
end

fid = fopen(out_abs, "w");
if fid < 0
    error("No fue posible escribir config resuelto: %s", out_abs);
end
cleanup_fid = onCleanup(@() fclose(fid));
fprintf(fid, "%s", json_txt);

relpath = make_relpath(out_abs, repo_dir);
end

function rel = make_relpath(abs_path, repo_dir)
rel = strrep(abs_path, [repo_dir filesep], "");
end
