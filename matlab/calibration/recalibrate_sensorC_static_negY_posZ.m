% recalibrate_sensorC_static_negY_posZ.m
% Recalibracion focalizada: reemplaza solo neg_y y pos_z con corridas nuevas.

%% Configuracion
sensor_id = "sensor_C";
pose_order = ["pos_x","neg_x","pos_y","neg_y","pos_z","neg_z"];
runs_target_by_pose = [3,3,3,5,5,5];
dataset_mode = "explicit_list";

% Manifest base de Fase 10 (corridas que se conservan)
base_phase10_manifest_relpath = "reports/analysis_outputs/sensor_C_static_calibration_20260321_140044_dataset.csv";
focus_latest_n = 5;

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
raw_dir = fullfile(repo_dir, "data", "raw", char(sensor_id));
base_manifest_path = fullfile(repo_dir, char(base_phase10_manifest_relpath));

if ~isfile(base_manifest_path)
    error("No existe manifest base de Fase 10: %s", base_manifest_path);
end

base_tbl = readtable(base_manifest_path, "Delimiter", ",", "TextType", "string");
if ~all(ismember(["pose","run_file"], string(base_tbl.Properties.VariableNames)))
    error("Manifest base incompleto: %s", base_manifest_path);
end

dataset_csv_by_pose = struct();

% Conservar poses estables desde Fase 10
dataset_csv_by_pose.pos_x = base_tbl.run_file(base_tbl.pose == "pos_x");
dataset_csv_by_pose.neg_x = base_tbl.run_file(base_tbl.pose == "neg_x");
dataset_csv_by_pose.pos_y = base_tbl.run_file(base_tbl.pose == "pos_y");
dataset_csv_by_pose.neg_z = base_tbl.run_file(base_tbl.pose == "neg_z");

% Reemplazar neg_y y pos_z con las ultimas N corridas nuevas
dataset_csv_by_pose.neg_y = latest_n_files(raw_dir, char(sensor_id + "_neg_y_*.csv"), focus_latest_n);
dataset_csv_by_pose.pos_z = latest_n_files(raw_dir, char(sensor_id + "_pos_z_*.csv"), focus_latest_n);

% Validaciones de tamano esperado
if numel(dataset_csv_by_pose.pos_x) ~= runs_target_by_pose(1)
    error("pos_x esperado=%d, encontrado=%d", runs_target_by_pose(1), numel(dataset_csv_by_pose.pos_x));
end
if numel(dataset_csv_by_pose.neg_x) ~= runs_target_by_pose(2)
    error("neg_x esperado=%d, encontrado=%d", runs_target_by_pose(2), numel(dataset_csv_by_pose.neg_x));
end
if numel(dataset_csv_by_pose.pos_y) ~= runs_target_by_pose(3)
    error("pos_y esperado=%d, encontrado=%d", runs_target_by_pose(3), numel(dataset_csv_by_pose.pos_y));
end
if numel(dataset_csv_by_pose.neg_y) ~= runs_target_by_pose(4)
    error("neg_y esperado=%d, encontrado=%d", runs_target_by_pose(4), numel(dataset_csv_by_pose.neg_y));
end
if numel(dataset_csv_by_pose.pos_z) ~= runs_target_by_pose(5)
    error("pos_z esperado=%d, encontrado=%d", runs_target_by_pose(5), numel(dataset_csv_by_pose.pos_z));
end
if numel(dataset_csv_by_pose.neg_z) ~= runs_target_by_pose(6)
    error("neg_z esperado=%d, encontrado=%d", runs_target_by_pose(6), numel(dataset_csv_by_pose.neg_z));
end

%% Ejecutar calibracion simple por eje con dataset focalizado
run(fullfile(script_dir, "calibrate_sensorC_static_6pose.m"));

%% Funcion local
function files = latest_n_files(raw_dir, pattern, n)
found = dir(fullfile(raw_dir, pattern));
if numel(found) < n
    error("No hay suficientes archivos para %s (%d < %d).", pattern, numel(found), n);
end
[~, order] = sort([found.datenum], "ascend");
found = found(order);
found = found((end-n+1):end);
files = string({found.name})';
end
