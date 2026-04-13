% run_sensorB_operational_feature_block.m
% Bloque funcional operativo (post-ingesta) para sensor_B.
%
% Entrada:
% - data/processed/sensor_B_operational_ingest_*.csv
%
% Salida:
% - features por ventana para siguiente modulo funcional
% - segmentos de movimiento detectados (regla simple)

%% Configuracion
if ~exist("sensor_id", "var") || strlength(string(sensor_id)) == 0
    sensor_id = "sensor_B";
else
    sensor_id = string(sensor_id);
end

if ~exist("input_processed_csv", "var")
    input_processed_csv = "";
else
    input_processed_csv = string(input_processed_csv);
end

if ~exist("window_s", "var") || isempty(window_s)
    window_s = 1.00;
end

if ~exist("hop_s", "var") || isempty(hop_s)
    hop_s = 0.25;
end

if ~exist("motion_k_mad", "var") || isempty(motion_k_mad)
    motion_k_mad = 3.0;
end

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
processed_dir = fullfile(repo_dir, "data", "processed");
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
if ~isfolder(analysis_out_dir)
    mkdir(analysis_out_dir);
end

input_abs = resolve_processed_input(repo_dir, processed_dir, sensor_id, input_processed_csv);
input_rel = make_relpath(input_abs, repo_dir);

%% Carga de datos
tbl = readtable(input_abs, "Delimiter", ",", "TextType", "string");
required_cols = { ...
    'seq','t_us','time_s', ...
    'mv_x_centered','mv_y_centered','mv_z_centered', ...
    'mv_norm_centered'};
missing_cols = setdiff(required_cols, tbl.Properties.VariableNames);
if ~isempty(missing_cols)
    error("Processed CSV incompleto (%s): %s", input_abs, strjoin(missing_cols, ", "));
end
tbl = tbl(:, required_cols);

time_s = double(tbl.time_s);
xc = double(tbl.mv_x_centered);
yc = double(tbl.mv_y_centered);
zc = double(tbl.mv_z_centered);
normc = double(tbl.mv_norm_centered);

n = height(tbl);
if n < 100
    error("Muestras insuficientes para bloque funcional: %d", n);
end

dt = diff(time_s);
dt = dt(dt > 0);
if isempty(dt)
    error("No se pudo estimar dt con time_s.");
end
fs = 1 / median(dt);

win_n = max(16, round(window_s * fs));
hop_n = max(1, round(hop_s * fs));

if win_n > n
    error("Window mayor que la corrida: win_n=%d n=%d", win_n, n);
end

starts = 1:hop_n:(n - win_n + 1);
n_win = numel(starts);
if n_win == 0
    error("No se generaron ventanas.");
end

% Prealloc
win_idx = zeros(n_win, 1);
t0 = zeros(n_win, 1);
t1 = zeros(n_win, 1);
samples = zeros(n_win, 1);

rms_x = zeros(n_win, 1);
rms_y = zeros(n_win, 1);
rms_z = zeros(n_win, 1);
std_x = zeros(n_win, 1);
std_y = zeros(n_win, 1);
std_z = zeros(n_win, 1);
ptp_x = zeros(n_win, 1);
ptp_y = zeros(n_win, 1);
ptp_z = zeros(n_win, 1);

norm_rms = zeros(n_win, 1);
norm_mean_abs = zeros(n_win, 1);
jerk_rms = zeros(n_win, 1);

for i = 1:n_win
    s = starts(i);
    e = s + win_n - 1;

    xx = xc(s:e);
    yy = yc(s:e);
    zz = zc(s:e);
    nn = normc(s:e);
    tt = time_s(s:e);

    win_idx(i) = i;
    t0(i) = tt(1);
    t1(i) = tt(end);
    samples(i) = numel(xx);

    rms_x(i) = sqrt(mean(xx.^2));
    rms_y(i) = sqrt(mean(yy.^2));
    rms_z(i) = sqrt(mean(zz.^2));
    std_x(i) = std(xx);
    std_y(i) = std(yy);
    std_z(i) = std(zz);
    ptp_x(i) = max(xx) - min(xx);
    ptp_y(i) = max(yy) - min(yy);
    ptp_z(i) = max(zz) - min(zz);

    norm_rms(i) = sqrt(mean(nn.^2));
    norm_mean_abs(i) = mean(abs(nn));

    dtt = diff(tt);
    dtt(dtt <= 0) = median(dt);
    jx = diff(xx) ./ dtt;
    jy = diff(yy) ./ dtt;
    jz = diff(zz) ./ dtt;
    jerk_mag = sqrt(jx.^2 + jy.^2 + jz.^2);
    jerk_rms(i) = sqrt(mean(jerk_mag.^2));
end

% Regla operativa simple para estado motion/quiet
base = median(norm_rms);
madv = median(abs(norm_rms - base));
if madv <= 0
    madv = std(norm_rms);
end
if madv <= 0
    madv = 1.0;
end
motion_thr = base + motion_k_mad * madv;
is_motion = norm_rms > motion_thr;

features_tbl = table( ...
    win_idx, t0, t1, samples, ...
    rms_x, rms_y, rms_z, ...
    std_x, std_y, std_z, ...
    ptp_x, ptp_y, ptp_z, ...
    norm_rms, norm_mean_abs, jerk_rms, ...
    repmat(motion_thr, n_win, 1), is_motion, ...
    'VariableNames', { ...
    'window_id','t_start_s','t_end_s','n_samples', ...
    'rms_x','rms_y','rms_z', ...
    'std_x','std_y','std_z', ...
    'ptp_x','ptp_y','ptp_z', ...
    'norm_rms','norm_mean_abs','jerk_rms', ...
    'motion_threshold','is_motion'});

segments_tbl = build_motion_segments(features_tbl);

%% Guardado
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
features_csv_abs = fullfile(processed_dir, char(sensor_id + "_operational_features_" + stamp + ".csv"));
segments_csv_abs = fullfile(processed_dir, char(sensor_id + "_operational_motion_segments_" + stamp + ".csv"));
out_mat_abs = fullfile(processed_dir, char(sensor_id + "_operational_feature_block_" + stamp + ".mat"));
summary_txt_abs = fullfile(analysis_out_dir, char(sensor_id + "_operational_feature_block_" + stamp + ".txt"));

writetable(features_tbl, features_csv_abs);
writetable(segments_tbl, segments_csv_abs);

feature_block = struct();
feature_block.sensor_id = sensor_id;
feature_block.input_processed_csv_relpath = input_rel;
feature_block.fs_hz = fs;
feature_block.window_s = window_s;
feature_block.hop_s = hop_s;
feature_block.motion_k_mad = motion_k_mad;
feature_block.motion_threshold = motion_thr;
feature_block.num_windows = n_win;
feature_block.num_motion_windows = sum(is_motion);
feature_block.generated_at = string(datetime("now", "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss Z"));

save(out_mat_abs, "feature_block", "features_tbl", "segments_tbl");

fid = fopen(summary_txt_abs, "w");
if fid < 0
    error("No se pudo crear resumen de bloque funcional: %s", summary_txt_abs);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/analysis/run_sensorB_operational_feature_block.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "input_processed_csv_relpath: %s\n", input_rel);
fprintf(fid, "fs_hz: %.6f\n", fs);
fprintf(fid, "window_s: %.3f\n", window_s);
fprintf(fid, "hop_s: %.3f\n", hop_s);
fprintf(fid, "num_windows: %d\n", n_win);
fprintf(fid, "num_motion_windows: %d\n", sum(is_motion));
fprintf(fid, "motion_threshold: %.6f\n", motion_thr);
fprintf(fid, "features_csv_relpath: %s\n", make_relpath(features_csv_abs, repo_dir));
fprintf(fid, "segments_csv_relpath: %s\n", make_relpath(segments_csv_abs, repo_dir));
fprintf(fid, "feature_mat_relpath: %s\n", make_relpath(out_mat_abs, repo_dir));
fprintf(fid, "next_module_input_relpath: %s\n", make_relpath(features_csv_abs, repo_dir));

fprintf("\nSENSOR_B_OPERATIONAL_FEATURE_BLOCK_OK\n");
fprintf("INPUT: %s\n", input_rel);
fprintf("FS_HZ: %.3f\n", fs);
fprintf("WINDOWS: %d\n", n_win);
fprintf("MOTION_WINDOWS: %d\n", sum(is_motion));
fprintf("FEATURES_CSV: %s\n", make_relpath(features_csv_abs, repo_dir));
fprintf("SEGMENTS_CSV: %s\n", make_relpath(segments_csv_abs, repo_dir));
fprintf("FEATURE_BLOCK_MAT: %s\n", make_relpath(out_mat_abs, repo_dir));
fprintf("SUMMARY_TXT: %s\n", make_relpath(summary_txt_abs, repo_dir));
fprintf("NEXT_MODULE_INPUT: %s\n", make_relpath(features_csv_abs, repo_dir));

%% Local functions
function segments_tbl = build_motion_segments(features_tbl)
if height(features_tbl) == 0
    segments_tbl = table([], [], [], [], [], ...
        'VariableNames', {'segment_id','t_start_s','t_end_s','duration_s','num_windows'});
    return;
end

is_motion = logical(features_tbl.is_motion);

start_idx = find(diff([false; is_motion]) == 1);
end_idx = find(diff([is_motion; false]) == -1);

seg_count = numel(start_idx);
segment_id = (1:seg_count).';
t_start_s = zeros(seg_count, 1);
t_end_s = zeros(seg_count, 1);
duration_s = zeros(seg_count, 1);
num_windows = zeros(seg_count, 1);

for k = 1:seg_count
    s = start_idx(k);
    e = end_idx(k);
    t_start_s(k) = features_tbl.t_start_s(s);
    t_end_s(k) = features_tbl.t_end_s(e);
    duration_s(k) = max(0, t_end_s(k) - t_start_s(k));
    num_windows(k) = e - s + 1;
end

segments_tbl = table(segment_id, t_start_s, t_end_s, duration_s, num_windows);
end

function input_abs = resolve_processed_input(repo_dir, processed_dir, sensor_id, input_processed_csv)
if strlength(input_processed_csv) > 0
    candidate = char(input_processed_csv);
    if isfile(candidate)
        input_abs = string(candidate);
        return;
    end

    in_repo = fullfile(repo_dir, candidate);
    if isfile(in_repo)
        input_abs = string(in_repo);
        return;
    end
    error("input_processed_csv no existe: %s", input_processed_csv);
end

pattern = sensor_id + "_operational_ingest_*.csv";
listing = dir(fullfile(processed_dir, char(pattern)));
if isempty(listing)
    error("No se encontro input processed para %s con patron %s", sensor_id, pattern);
end
[~, idx] = sort([listing.datenum], "ascend");
listing = listing(idx);
input_abs = string(fullfile(listing(end).folder, listing(end).name));
end

function rel = make_relpath(abs_path, repo_dir)
abs_s = string(abs_path);
if numel(abs_s) > 1
    abs_s = abs_s(1);
end
repo_s = string(repo_dir);
if numel(repo_s) > 1
    repo_s = repo_s(1);
end

abs_s = replace(abs_s, "\", "/");
repo_s = replace(repo_s, "\", "/");
prefix = repo_s + "/";

if startsWith(abs_s, prefix)
    rel_s = extractAfter(abs_s, strlength(prefix));
else
    rel_s = abs_s;
end
rel = char(rel_s);
end
