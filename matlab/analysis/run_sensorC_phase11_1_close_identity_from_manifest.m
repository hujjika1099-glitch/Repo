% run_sensorC_phase11_1_close_identity_from_manifest.m
% Fase 11.1 helper:
% - toma el manifest ST mas reciente
% - ejecuta selftest identity check con ese par
% - reejecuta orquestador Fase 11 con los mismos archivos

%% Configuracion
if ~exist("sensor_id", "var") || strlength(string(sensor_id)) == 0
    sensor_id = "sensor_C";
else
    sensor_id = string(sensor_id);
end

if ~exist("manifest_relpath", "var")
    manifest_relpath = "";
else
    manifest_relpath = string(manifest_relpath);
end

script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");

if strlength(manifest_relpath) == 0
    manifest_abs = find_latest_manifest(analysis_out_dir, sensor_id + "_selftest_capture_protocol_*.csv");
    if strlength(manifest_abs) == 0
        fprintf("\nPHASE11_1_CLOSE_IDENTITY_SKIPPED\n");
        fprintf("REASON: no se encontro manifest ST capture protocol\n");
        return;
    end
else
    manifest_abs = fullfile(repo_dir, char(manifest_relpath));
    if ~isfile(manifest_abs)
        error("Manifest no encontrado: %s", manifest_abs);
    end
end

manifest_tbl = readtable(manifest_abs, "Delimiter", ",", "TextType", "string");
req_cols = {'label','run_file'};
missing_cols = setdiff(req_cols, manifest_tbl.Properties.VariableNames);
if ~isempty(missing_cols)
    error("Manifest incompleto: %s", strjoin(missing_cols, ", "));
end

st_off_idx = manifest_tbl.label == "st_off";
st_on_idx = manifest_tbl.label == "st_on";
if ~any(st_off_idx) || ~any(st_on_idx)
    error("Manifest debe contener filas st_off y st_on.");
end

st_off_run_file = string(manifest_tbl.run_file(find(st_off_idx,1,"first")));
st_on_run_file = string(manifest_tbl.run_file(find(st_on_idx,1,"first")));

% Ejecutar self-test check con archivos explicitos
run(fullfile(script_dir, "run_sensorC_selftest_identity_check.m"));

% Ejecutar orquestador de fase 11 con esos mismos archivos
run_selftest_identity = true;
run(fullfile(script_dir, "run_sensorC_phase11_axis_identity_and_convention.m"));

fprintf("\nPHASE11_1_CLOSE_IDENTITY_DONE\n");
fprintf("MANIFEST: %s\n", make_relpath(manifest_abs, repo_dir));
fprintf("ST_OFF_RUN: %s\n", st_off_run_file);
fprintf("ST_ON_RUN: %s\n", st_on_run_file);
if exist("selftest_result", "var") && isfield(selftest_result, "final_decision")
    fprintf("SELFTEST_FINAL_DECISION: %s\n", string(selftest_result.final_decision));
end
if exist("phase11_result", "var") && isfield(phase11_result, "operational") && isfield(phase11_result.operational, "final_decision")
    fprintf("PHASE11_FINAL_DECISION: %s\n", string(phase11_result.operational.final_decision));
end

%% Local functions
function latest_abs = find_latest_manifest(base_dir, pattern)
latest_abs = "";
listing = dir(fullfile(base_dir, char(pattern)));
if isempty(listing)
    return;
end
[~, idx] = sort([listing.datenum], "ascend");
listing = listing(idx);
latest_abs = string(fullfile(listing(end).folder, listing(end).name));
end

function rel = make_relpath(abs_path, repo_dir)
rel = strrep(char(abs_path), [repo_dir filesep], "");
end
