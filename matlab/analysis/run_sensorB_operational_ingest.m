% run_sensorB_operational_ingest.m
% Fase 13: ingesta operativa minima para sensor_B.
%
% Convierte un CSV operativo real en un artefacto procesado util para
% el siguiente bloque funcional (sin calibracion heredada de sensor_C).

%% Configuracion
if ~exist("sensor_id", "var") || strlength(string(sensor_id)) == 0
    sensor_id = "sensor_B";
else
    sensor_id = string(sensor_id);
end

if ~exist("input_csv_abs", "var")
    input_csv_abs = "";
else
    input_csv_abs = string(input_csv_abs);
end

if ~exist("min_samples", "var") || isempty(min_samples)
    min_samples = 1000;
end

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
raw_dir = fullfile(repo_dir, "data", "raw", char(sensor_id));
processed_dir = fullfile(repo_dir, "data", "processed");
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
if ~isfolder(processed_dir)
    mkdir(processed_dir);
end
if ~isfolder(analysis_out_dir)
    mkdir(analysis_out_dir);
end

input_csv_abs = resolve_input_csv(repo_dir, raw_dir, sensor_id, input_csv_abs);
input_csv_rel = make_relpath(input_csv_abs, repo_dir);

%% Carga y validacion
required_cols = {'seq','t_us','raw_x','raw_y','raw_z','mv_x','mv_y','mv_z'};
tbl = readtable(input_csv_abs, "Delimiter", ",", "TextType", "string");
missing_cols = setdiff(required_cols, tbl.Properties.VariableNames);
if ~isempty(missing_cols)
    error("CSV sin columnas esperadas (%s): %s", input_csv_abs, strjoin(missing_cols, ", "));
end
tbl = tbl(:, required_cols);

n_samples = height(tbl);
if n_samples < min_samples
    error("Muestras insuficientes para ingest operacional: %d < %d", n_samples, min_samples);
end

seq = double(tbl.seq);
t_us = double(tbl.t_us);
raw_x = double(tbl.raw_x);
raw_y = double(tbl.raw_y);
raw_z = double(tbl.raw_z);
mv_x = double(tbl.mv_x);
mv_y = double(tbl.mv_y);
mv_z = double(tbl.mv_z);

seq_jumps = nnz(diff(seq) ~= 1);
t_s = (t_us - t_us(1)) / 1e6;
stream_duration_s = max(0, t_s(end));
if stream_duration_s > 0
    freq_hz = (n_samples - 1) / stream_duration_s;
else
    freq_hz = NaN;
end

% Centro operativo por corrida (no es calibracion fisica por sensor).
mv_x_centered = mv_x - mean(mv_x);
mv_y_centered = mv_y - mean(mv_y);
mv_z_centered = mv_z - mean(mv_z);

mv_norm = sqrt(mv_x.^2 + mv_y.^2 + mv_z.^2);
mv_norm_centered = sqrt(mv_x_centered.^2 + mv_y_centered.^2 + mv_z_centered.^2);

ingest_tbl = table( ...
    seq, t_us, t_s, ...
    raw_x, raw_y, raw_z, ...
    mv_x, mv_y, mv_z, ...
    mv_x_centered, mv_y_centered, mv_z_centered, ...
    mv_norm, mv_norm_centered, ...
    'VariableNames', { ...
    'seq','t_us','time_s', ...
    'raw_x','raw_y','raw_z', ...
    'mv_x','mv_y','mv_z', ...
    'mv_x_centered','mv_y_centered','mv_z_centered', ...
    'mv_norm','mv_norm_centered'});

%% Persistencia de salida
stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
base_name = sensor_id + "_operational_ingest_" + stamp;
processed_csv_out = fullfile(processed_dir, char(base_name + ".csv"));
processed_mat_out = fullfile(processed_dir, char(base_name + ".mat"));
summary_txt_out = fullfile(analysis_out_dir, char(base_name + ".txt"));

writetable(ingest_tbl, processed_csv_out);

operational_packet = struct();
operational_packet.sensor_id = sensor_id;
operational_packet.source_csv_relpath = input_csv_rel;
operational_packet.samples = n_samples;
operational_packet.stream_duration_s = stream_duration_s;
operational_packet.freq_hz = freq_hz;
operational_packet.seq_jumps = seq_jumps;
operational_packet.generated_at = string(datetime("now", "TimeZone", "local", "Format", "yyyy-MM-dd HH:mm:ss Z"));
operational_packet.columns = string(ingest_tbl.Properties.VariableNames);

save(processed_mat_out, "operational_packet", "ingest_tbl");

fid = fopen(summary_txt_out, "w");
if fid < 0
    error("No fue posible crear resumen de ingesta: %s", summary_txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/analysis/run_sensorB_operational_ingest.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "source_csv_relpath: %s\n", input_csv_rel);
fprintf(fid, "samples: %d\n", n_samples);
fprintf(fid, "stream_duration_s: %.6f\n", stream_duration_s);
fprintf(fid, "freq_hz: %.6f\n", freq_hz);
fprintf(fid, "seq_jumps: %d\n", seq_jumps);
fprintf(fid, "processed_csv_relpath: %s\n", make_relpath(processed_csv_out, repo_dir));
fprintf(fid, "processed_mat_relpath: %s\n", make_relpath(processed_mat_out, repo_dir));
fprintf(fid, "next_module_input_relpath: %s\n", make_relpath(processed_csv_out, repo_dir));

processed_csv_rel = make_relpath(processed_csv_out, repo_dir);
processed_mat_rel = make_relpath(processed_mat_out, repo_dir);
summary_txt_rel = make_relpath(summary_txt_out, repo_dir);

fprintf("\nSENSOR_B_OPERATIONAL_INGEST_OK\n");
fprintf("SOURCE_CSV: %s\n", input_csv_rel);
fprintf("SAMPLES: %d\n", n_samples);
fprintf("FREQ_HZ: %.3f\n", freq_hz);
fprintf("SEQ_JUMPS: %d\n", seq_jumps);
fprintf("PROCESSED_CSV: %s\n", processed_csv_rel);
fprintf("PROCESSED_MAT: %s\n", processed_mat_rel);
fprintf("SUMMARY_TXT: %s\n", summary_txt_rel);
fprintf("NEXT_MODULE_INPUT: %s\n", processed_csv_rel);

%% Local functions
function csv_abs = resolve_input_csv(repo_dir, raw_dir, sensor_id, input_csv_abs)
if strlength(input_csv_abs) > 0
    candidate = char(input_csv_abs);
    if isfile(candidate)
        csv_abs = string(candidate);
        return;
    end

    in_repo = fullfile(repo_dir, candidate);
    if isfile(in_repo)
        csv_abs = string(in_repo);
        return;
    end
    error("input_csv_abs no existe: %s", input_csv_abs);
end

pattern = sensor_id + "_operational_run_*.csv";
listing = dir(fullfile(raw_dir, char(pattern)));
if isempty(listing)
    error("No se encontro CSV operacional para %s en %s", sensor_id, raw_dir);
end
[~, idx] = sort([listing.datenum], "ascend");
listing = listing(idx);
csv_abs = string(fullfile(listing(end).folder, listing(end).name));
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
