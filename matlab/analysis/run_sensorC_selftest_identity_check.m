% run_sensorC_selftest_identity_check.m
% Fase 11: verificacion corta de identidad de canales usando firma ST del ADXL335.
%
% Firma esperada (datasheet ADXL335):
% - XOUT disminuye con ST_ON  -> delta(X) < 0
% - YOUT aumenta con ST_ON    -> delta(Y) > 0
% - ZOUT aumenta con ST_ON    -> delta(Z) > 0 y tipicamente mayor que Y

%% Configuracion
if ~exist("sensor_id", "var") || strlength(string(sensor_id)) == 0
    sensor_id = "sensor_C";
else
    sensor_id = string(sensor_id);
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

if ~exist("delta_mv_floor", "var") || isempty(delta_mv_floor)
    delta_mv_floor = 8.0;
end

if ~exist("zscore_min", "var") || isempty(zscore_min)
    zscore_min = 8.0;
end

if ~exist("yz_ratio_min", "var") || isempty(yz_ratio_min)
    yz_ratio_min = 1.10;
end

if ~exist("baseline_calibration_mat_relpath", "var") || strlength(string(baseline_calibration_mat_relpath)) == 0
    baseline_calibration_mat_relpath = "data/processed/sensor_C_static_calibration_20260321_140044.mat";
else
    baseline_calibration_mat_relpath = string(baseline_calibration_mat_relpath);
end

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
raw_dir = fullfile(repo_dir, "data", "raw", char(sensor_id));
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
config_dir = fullfile(repo_dir, "config");
if ~isfolder(analysis_out_dir)
    mkdir(analysis_out_dir);
end
if ~isfolder(config_dir)
    mkdir(config_dir);
end

stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
out_base = sensor_id + "_selftest_identity_" + stamp;
summary_txt_out = fullfile(analysis_out_dir, char(out_base + ".txt"));
channel_csv_out = fullfile(analysis_out_dir, char(out_base + "_channels.csv"));
manifest_csv_out = fullfile(analysis_out_dir, char(out_base + "_manifest.csv"));
identity_json_out = fullfile(config_dir, char(sensor_id + "_axis_identity_from_st_latest.json"));

selftest_result = struct();
selftest_result.sensor_id = sensor_id;
selftest_result.timestamp = string(datetime("now", "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss Z"));
selftest_result.final_decision = "selftest_data_missing";
selftest_result.identity_status = "identity_not_closed";
selftest_result.confidence = 0;
selftest_result.st_off_run_file = "";
selftest_result.st_on_run_file = "";
selftest_result.summary_txt = make_relpath(summary_txt_out, repo_dir);
selftest_result.channel_csv = make_relpath(channel_csv_out, repo_dir);
selftest_result.manifest_csv = make_relpath(manifest_csv_out, repo_dir);
selftest_result.identity_json = make_relpath(identity_json_out, repo_dir);

% Resolve ST_OFF/ST_ON files
st_off_run_file = resolve_st_file(raw_dir, sensor_id, st_off_run_file, "off");
st_on_run_file = resolve_st_file(raw_dir, sensor_id, st_on_run_file, "on");

if strlength(st_off_run_file) == 0 || strlength(st_on_run_file) == 0
    selftest_result.final_decision = "selftest_data_missing";
    selftest_result.reason = "No se encontraron corridas ST_OFF/ST_ON.";

    write_missing_summary(summary_txt_out, selftest_result, delta_mv_floor, zscore_min, yz_ratio_min);

    fprintf("\nSELFTEST_IDENTITY_SKIPPED\n");
    fprintf("REASON: %s\n", selftest_result.reason);
    fprintf("SUMMARY_TXT: %s\n", selftest_result.summary_txt);
    return;
end

selftest_result.st_off_run_file = st_off_run_file;
selftest_result.st_on_run_file = st_on_run_file;

% Load runs
off = read_run_metrics(fullfile(raw_dir, char(st_off_run_file)));
on = read_run_metrics(fullfile(raw_dir, char(st_on_run_file)));

channels = ["x"; "y"; "z"];
mean_off = off.mean_mv(:);
mean_on = on.mean_mv(:);
delta_mv = mean_on - mean_off;
sem_delta = sqrt((off.std_mv(:).^2 ./ max(off.n,1)) + (on.std_mv(:).^2 ./ max(on.n,1)));
zscore_delta = delta_mv ./ max(sem_delta, eps);

% Inference rules
strong_neg = find((delta_mv < -delta_mv_floor) & (abs(zscore_delta) >= zscore_min));
strong_pos = find((delta_mv > delta_mv_floor) & (abs(zscore_delta) >= zscore_min));

inferred_chip_axis = strings(3,1);
inferred_chip_axis(:) = "unknown";
reason = "";

if numel(strong_neg) ~= 1 || numel(strong_pos) ~= 2
    final_decision = "identity_not_closed";
    reason = sprintf("sign_pattern_failed neg=%d pos=%d", numel(strong_neg), numel(strong_pos));
    yz_ratio = NaN;
    confidence = compute_confidence(0, delta_mv, zscore_delta, NaN);
else
    x_idx = strong_neg(1);
    inferred_chip_axis(x_idx) = "x";

    [~, order_pos] = sort(delta_mv(strong_pos), "descend");
    z_idx = strong_pos(order_pos(1));
    y_idx = strong_pos(order_pos(2));

    inferred_chip_axis(z_idx) = "z";
    inferred_chip_axis(y_idx) = "y";

    yz_ratio = delta_mv(z_idx) / max(delta_mv(y_idx), eps);
    confidence = compute_confidence(1, delta_mv, zscore_delta, yz_ratio);

    if yz_ratio >= yz_ratio_min
        final_decision = "identity_closed";
        reason = "st_signature_supported";
    else
        final_decision = "identity_not_closed";
        reason = sprintf("yz_separation_low ratio=%.4f", yz_ratio);
    end
end

identity_status = final_decision;
if final_decision == "identity_closed"
    identity_status = "identity_closed";
else
    identity_status = "identity_not_closed";
end

expected_st_sign = strings(3,1);
for i = 1:3
    if inferred_chip_axis(i) == "x"
        expected_st_sign(i) = "negative";
    elseif inferred_chip_axis(i) == "y" || inferred_chip_axis(i) == "z"
        expected_st_sign(i) = "positive";
    else
        expected_st_sign(i) = "unknown";
    end
end

channel_tbl = table( ...
    channels, mean_off, mean_on, delta_mv, sem_delta, zscore_delta, inferred_chip_axis, expected_st_sign, ...
    'VariableNames', {'channel','mean_mv_st_off','mean_mv_st_on','delta_mv_on_minus_off','sem_delta_mv','delta_zscore','inferred_chip_axis','expected_st_sign'});

manifest_tbl = table( ...
    ["st_off"; "st_on"], [st_off_run_file; st_on_run_file], ...
    'VariableNames', {'label','run_file'});

writetable(channel_tbl, channel_csv_out);
writetable(manifest_tbl, manifest_csv_out);

selftest_result.final_decision = final_decision;
selftest_result.identity_status = identity_status;
selftest_result.reason = reason;
selftest_result.yz_ratio = yz_ratio;
selftest_result.confidence = confidence;
selftest_result.delta_mv_floor = delta_mv_floor;
selftest_result.zscore_min = zscore_min;
selftest_result.yz_ratio_min = yz_ratio_min;
selftest_result.channel_to_chip_axis = struct( ...
    "x", char(inferred_chip_axis(channels == "x")), ...
    "y", char(inferred_chip_axis(channels == "y")), ...
    "z", char(inferred_chip_axis(channels == "z")));

write_summary(summary_txt_out, selftest_result, off, on, channel_tbl);
write_identity_json(identity_json_out, selftest_result, baseline_calibration_mat_relpath);

fprintf("\nSELFTEST_IDENTITY_CHECK_OK\n");
fprintf("ST_OFF_RUN: %s\n", st_off_run_file);
fprintf("ST_ON_RUN: %s\n", st_on_run_file);
fprintf("FINAL_DECISION: %s\n", selftest_result.final_decision);
fprintf("CONFIDENCE: %.4f\n", selftest_result.confidence);
fprintf("CHANNEL_CSV: %s\n", selftest_result.channel_csv);
fprintf("MANIFEST_CSV: %s\n", selftest_result.manifest_csv);
fprintf("IDENTITY_JSON: %s\n", selftest_result.identity_json);

%% Local functions
function run_file = resolve_st_file(raw_dir, sensor_id, explicit_file, off_or_on)
if strlength(explicit_file) > 0
    if isfile(fullfile(raw_dir, char(explicit_file)))
        run_file = explicit_file;
        return;
    end
    error("Archivo ST explicito no existe: %s", explicit_file);
end

if off_or_on == "off"
    patterns = [ ...
        sensor_id + "_st_off_*.csv", ...
        sensor_id + "_selftest_off_*.csv" ...
    ];
else
    patterns = [ ...
        sensor_id + "_st_on_*.csv", ...
        sensor_id + "_selftest_on_*.csv" ...
    ];
end

run_file = "";
best_time = -inf;
for p = 1:numel(patterns)
    listing = dir(fullfile(raw_dir, char(patterns(p))));
    for i = 1:numel(listing)
        if listing(i).datenum > best_time
            best_time = listing(i).datenum;
            run_file = string(listing(i).name);
        end
    end
end
end

function m = read_run_metrics(csv_abs)
expected_cols = {'seq','t_us','raw_x','raw_y','raw_z','mv_x','mv_y','mv_z'};
tbl = readtable(csv_abs, "Delimiter", ",", "TextType", "string");
missing_cols = setdiff(expected_cols, tbl.Properties.VariableNames);
if ~isempty(missing_cols)
    error("CSV sin columnas esperadas (%s): %s", csv_abs, strjoin(missing_cols, ", "));
end
tbl = tbl(:, expected_cols);

m = struct();
m.n = height(tbl);
if m.n < 3
    error("Corrida insuficiente para ST identity: %s", csv_abs);
end
m.mean_mv = [mean(double(tbl.mv_x)); mean(double(tbl.mv_y)); mean(double(tbl.mv_z))];
m.std_mv = [std(double(tbl.mv_x)); std(double(tbl.mv_y)); std(double(tbl.mv_z))];
end

function c = compute_confidence(sign_pattern_ok, delta_mv, zscore_delta, yz_ratio)
amp_score = min(1.0, min(abs(delta_mv)) / 40.0);
z_score = min(1.0, min(abs(zscore_delta)) / 20.0);
if isnan(yz_ratio)
    sep_score = 0;
else
    sep_score = min(1.0, max(0.0, (yz_ratio - 1.0) / 0.30));
end
c = 0.35 * sign_pattern_ok + 0.25 * amp_score + 0.20 * z_score + 0.20 * sep_score;
c = max(0.0, min(1.0, c));
end

function write_summary(summary_txt_out, result, off, on, channel_tbl)
fid = fopen(summary_txt_out, "w");
if fid < 0
    error("No fue posible crear resumen ST: %s", summary_txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/analysis/run_sensorC_selftest_identity_check.m\n");
fprintf(fid, "sensor_id: %s\n", result.sensor_id);
fprintf(fid, "st_off_run_file: %s\n", result.st_off_run_file);
fprintf(fid, "st_on_run_file: %s\n", result.st_on_run_file);
fprintf(fid, "n_samples_st_off: %d\n", off.n);
fprintf(fid, "n_samples_st_on: %d\n", on.n);
fprintf(fid, "delta_mv_floor: %.4f\n", result.delta_mv_floor);
fprintf(fid, "zscore_min: %.4f\n", result.zscore_min);
fprintf(fid, "yz_ratio_min: %.4f\n", result.yz_ratio_min);
fprintf(fid, "final_decision: %s\n", result.final_decision);
fprintf(fid, "identity_status: %s\n", result.identity_status);
fprintf(fid, "reason: %s\n", result.reason);
fprintf(fid, "confidence: %.6f\n", result.confidence);
if isfield(result, "yz_ratio")
    fprintf(fid, "yz_ratio: %.6f\n", result.yz_ratio);
end
fprintf(fid, "channel_csv: %s\n", result.channel_csv);
fprintf(fid, "manifest_csv: %s\n", result.manifest_csv);

for i = 1:height(channel_tbl)
    fprintf(fid, "channel_%s_delta_mv: %.6f\n", channel_tbl.channel(i), channel_tbl.delta_mv_on_minus_off(i));
    fprintf(fid, "channel_%s_delta_zscore: %.6f\n", channel_tbl.channel(i), channel_tbl.delta_zscore(i));
    fprintf(fid, "channel_%s_inferred_chip_axis: %s\n", channel_tbl.channel(i), channel_tbl.inferred_chip_axis(i));
end
end

function write_missing_summary(summary_txt_out, result, delta_mv_floor, zscore_min, yz_ratio_min)
fid = fopen(summary_txt_out, "w");
if fid < 0
    error("No fue posible crear resumen ST missing: %s", summary_txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/analysis/run_sensorC_selftest_identity_check.m\n");
fprintf(fid, "sensor_id: %s\n", result.sensor_id);
fprintf(fid, "final_decision: %s\n", result.final_decision);
fprintf(fid, "identity_status: %s\n", result.identity_status);
fprintf(fid, "reason: %s\n", result.reason);
fprintf(fid, "delta_mv_floor: %.4f\n", delta_mv_floor);
fprintf(fid, "zscore_min: %.4f\n", zscore_min);
fprintf(fid, "yz_ratio_min: %.4f\n", yz_ratio_min);
end

function write_identity_json(json_abs_path, result, baseline_calibration_mat_relpath)
cfg = struct();
cfg.sensor_id = char(result.sensor_id);
cfg.generated_at = char(string(datetime("now", "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss Z")));
cfg.source = "run_sensorC_selftest_identity_check";
cfg.identity = struct();
cfg.identity.status = char(result.identity_status);
cfg.identity.method = "adxl335_selftest_signature";
cfg.identity.confidence = result.confidence;
cfg.identity.evidence = char(result.reason);
cfg.identity.st_off_run_file = char(result.st_off_run_file);
cfg.identity.st_on_run_file = char(result.st_on_run_file);
cfg.identity.channel_to_chip_axis = result.channel_to_chip_axis;

cfg.convention = struct();
cfg.convention.definition = "axis_plus_points_against_gravity";
cfg.convention.chip_axis_to_operational_axis = struct("x", "x", "y", "y", "z", "z");
cfg.convention.chip_axis_sign_to_operational = struct("x", 1, "y", 1, "z", 1);

cfg.baseline_calibration_mat_relpath = char(baseline_calibration_mat_relpath);

try
    json_txt = jsonencode(cfg, PrettyPrint=true);
catch
    json_txt = jsonencode(cfg);
end

fid = fopen(json_abs_path, "w");
if fid < 0
    error("No fue posible crear JSON de identidad: %s", json_abs_path);
end
cleanup_fid = onCleanup(@() fclose(fid));
fprintf(fid, "%s", json_txt);
end

function rel = make_relpath(abs_path, repo_dir)
rel = strrep(abs_path, [repo_dir filesep], "");
end
