% analyze_single_capture_baseline.m
% Analisis basico de una captura individual baseline ADXL335.

%% Configuracion
sensor_id = "sensor_A";
pose_label = "z_plus_static";

% Si use_specific_file es true, usar specific_csv_relpath relativo al repo.
use_specific_file = false;
specific_csv_relpath = "data/raw/sensor_A/sensor_A_z_plus_static_20260320_132709.csv";

save_figures = true;

%% Resolucion de rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
raw_dir = fullfile(repo_dir, "data", "raw", char(sensor_id));
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
if ~isfolder(analysis_out_dir)
    mkdir(analysis_out_dir);
end

if use_specific_file
    csv_path = fullfile(repo_dir, char(specific_csv_relpath));
    if ~isfile(csv_path)
        error("CSV especificado no existe: %s", csv_path);
    end
else
    pattern = char(sensor_id + "_" + pose_label + "_*.csv");
    listing = dir(fullfile(raw_dir, pattern));
    if isempty(listing)
        error("No se encontro ningun CSV para %s/%s en %s", sensor_id, pose_label, raw_dir);
    end
    [~, idx] = max([listing.datenum]);
    csv_path = fullfile(listing(idx).folder, listing(idx).name);
end

[csv_dir, csv_name, ~] = fileparts(csv_path);
session_path = fullfile(csv_dir, csv_name + "_session.txt");
session_exists = isfile(session_path);

csv_rel = string(strrep(csv_path, [repo_dir filesep], ""));
if session_exists
    session_rel = string(strrep(session_path, [repo_dir filesep], ""));
else
    session_rel = "<NOT_FOUND>";
end

%% Carga y validacion de datos
tbl = readtable(csv_path, "Delimiter", ",", "TextType", "string");
expected_cols = {'seq','t_us','raw_x','raw_y','raw_z','mv_x','mv_y','mv_z'};

missing_cols = setdiff(expected_cols, tbl.Properties.VariableNames);
if ~isempty(missing_cols)
    error("CSV sin columnas esperadas. Faltantes: %s", strjoin(missing_cols, ", "));
end

tbl = tbl(:, expected_cols);

seq = double(tbl.seq);
t_us = double(tbl.t_us);
raw_x = double(tbl.raw_x);
raw_y = double(tbl.raw_y);
raw_z = double(tbl.raw_z);
mv_x = double(tbl.mv_x);
mv_y = double(tbl.mv_y);
mv_z = double(tbl.mv_z);

n_samples = height(tbl);
if n_samples < 2
    error("Se requieren al menos 2 muestras para analisis basico.");
end

t_s = (t_us - t_us(1)) / 1e6;
duration_s = t_s(end);
if duration_s > 0
    freq_hz = (n_samples - 1) / duration_s;
else
    freq_hz = NaN;
end

seq_jumps = nnz(diff(seq) ~= 1);

raw_mean = [mean(raw_x), mean(raw_y), mean(raw_z)];
raw_std = [std(raw_x), std(raw_y), std(raw_z)];
raw_min = [min(raw_x), min(raw_y), min(raw_z)];
raw_max = [max(raw_x), max(raw_y), max(raw_z)];

mv_mean = [mean(mv_x), mean(mv_y), mean(mv_z)];
mv_std = [std(mv_x), std(mv_y), std(mv_z)];
mv_min = [min(mv_x), min(mv_y), min(mv_z)];
mv_max = [max(mv_x), max(mv_y), max(mv_z)];

%% Figuras
raw_fig_rel = "<NOT_SAVED>";
mv_fig_rel = "<NOT_SAVED>";
if save_figures
    stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
    base = csv_name + "_analysis_" + stamp;

    fig1 = figure("Visible", "off");
    plot(t_s, raw_x, "LineWidth", 1.0); hold on;
    plot(t_s, raw_y, "LineWidth", 1.0);
    plot(t_s, raw_z, "LineWidth", 1.0);
    hold off; grid on;
    xlabel("Tiempo [s]");
    ylabel("ADC raw");
    title("ADXL335 Raw vs Tiempo");
    legend("raw_x", "raw_y", "raw_z", "Location", "best");
    raw_fig_path = fullfile(analysis_out_dir, char(base + "_raw.png"));
    exportgraphics(fig1, raw_fig_path, "Resolution", 150);
    close(fig1);

    fig2 = figure("Visible", "off");
    plot(t_s, mv_x, "LineWidth", 1.0); hold on;
    plot(t_s, mv_y, "LineWidth", 1.0);
    plot(t_s, mv_z, "LineWidth", 1.0);
    hold off; grid on;
    xlabel("Tiempo [s]");
    ylabel("mV");
    title("ADXL335 mV vs Tiempo");
    legend("mv_x", "mv_y", "mv_z", "Location", "best");
    mv_fig_path = fullfile(analysis_out_dir, char(base + "_mv.png"));
    exportgraphics(fig2, mv_fig_path, "Resolution", 150);
    close(fig2);

    raw_fig_rel = string(strrep(raw_fig_path, [repo_dir filesep], ""));
    mv_fig_rel = string(strrep(mv_fig_path, [repo_dir filesep], ""));
end

%% Resumen textual reproducible
summary_path = fullfile(analysis_out_dir, char(csv_name + "_analysis_summary.txt"));
fid = fopen(summary_path, "w");
if fid < 0
    error("No fue posible crear resumen de analisis: %s", summary_path);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "analysis_script: matlab/analysis/analyze_single_capture_baseline.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "pose_label: %s\n", pose_label);
fprintf(fid, "csv_relpath: %s\n", csv_rel);
fprintf(fid, "session_relpath: %s\n", session_rel);
fprintf(fid, "samples: %d\n", n_samples);
fprintf(fid, "duration_s: %.6f\n", duration_s);
fprintf(fid, "estimated_frequency_hz: %.6f\n", freq_hz);
fprintf(fid, "seq_jumps: %d\n", seq_jumps);
fprintf(fid, "raw_mean: %.6f,%.6f,%.6f\n", raw_mean);
fprintf(fid, "raw_std: %.6f,%.6f,%.6f\n", raw_std);
fprintf(fid, "raw_min: %.6f,%.6f,%.6f\n", raw_min);
fprintf(fid, "raw_max: %.6f,%.6f,%.6f\n", raw_max);
fprintf(fid, "mv_mean: %.6f,%.6f,%.6f\n", mv_mean);
fprintf(fid, "mv_std: %.6f,%.6f,%.6f\n", mv_std);
fprintf(fid, "mv_min: %.6f,%.6f,%.6f\n", mv_min);
fprintf(fid, "mv_max: %.6f,%.6f,%.6f\n", mv_max);
fprintf(fid, "raw_plot_relpath: %s\n", raw_fig_rel);
fprintf(fid, "mv_plot_relpath: %s\n", mv_fig_rel);

summary_rel = string(strrep(summary_path, [repo_dir filesep], ""));

%% Salida por consola
fprintf("\nANALYSIS_OK\n");
fprintf("CSV_RELPATH: %s\n", csv_rel);
fprintf("SESSION_RELPATH: %s\n", session_rel);
fprintf("SUMMARY_RELPATH: %s\n", summary_rel);
fprintf("RAW_PLOT_RELPATH: %s\n", raw_fig_rel);
fprintf("MV_PLOT_RELPATH: %s\n", mv_fig_rel);
fprintf("SAMPLES: %d\n", n_samples);
fprintf("DURATION_S: %.6f\n", duration_s);
fprintf("FREQ_HZ: %.6f\n", freq_hz);
fprintf("SEQ_JUMPS: %d\n", seq_jumps);
