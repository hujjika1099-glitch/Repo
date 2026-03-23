% run_sensorB_live_session.m
% Fase 14A - Sesion live MATLAB (serial directo actual).
%
% Funciones:
% - captura en vivo desde serial
% - visualizacion live (raw o mV + g estimada)
% - guardado raw y procesado al finalizar
%
% Nota:
% - Conversion a g usa ruta minima util (nominal_quick_g por defecto).
% - No usa calibracion especifica de sensor_C.

%% Configuracion de sesion
if ~exist("sensor_id", "var") || strlength(string(sensor_id)) == 0
    sensor_id = "sensor_B";
else
    sensor_id = string(sensor_id);
end

if ~exist("port", "var") || strlength(string(port)) == 0
    port = "COM5";
else
    port = string(port);
end

if ~exist("baud", "var") || isempty(baud)
    baud = 115200;
end

if ~exist("duration_s", "var") || isempty(duration_s)
    duration_s = 20;
end

if ~exist("session_name", "var") || strlength(string(session_name)) == 0
    session_name = "live";
else
    session_name = string(session_name);
end

if ~exist("file_prefix", "var") || strlength(string(file_prefix)) == 0
    file_prefix = sensor_id + "_live";
else
    file_prefix = string(file_prefix);
end

if ~exist("output_dir_relpath", "var") || strlength(string(output_dir_relpath)) == 0
    output_dir_relpath = "data/raw/sensor_B_live";
else
    output_dir_relpath = string(output_dir_relpath);
end

if ~exist("processed_dir_relpath", "var") || strlength(string(processed_dir_relpath)) == 0
    processed_dir_relpath = "data/processed";
else
    processed_dir_relpath = string(processed_dir_relpath);
end

if ~exist("save_csv", "var") || isempty(save_csv)
    save_csv = true;
else
    save_csv = logical(save_csv);
end

if ~exist("save_mat", "var") || isempty(save_mat)
    save_mat = true;
else
    save_mat = logical(save_mat);
end

if ~exist("show_live_plot", "var") || isempty(show_live_plot)
    show_live_plot = true;
else
    show_live_plot = logical(show_live_plot);
end

if ~exist("live_plot_mode", "var") || strlength(string(live_plot_mode)) == 0
    live_plot_mode = "mv";  % raw | mv
else
    live_plot_mode = lower(string(live_plot_mode));
end

if ~ismember(live_plot_mode, ["raw", "mv"])
    error("live_plot_mode no soportado: %s", live_plot_mode);
end

if ~exist("print_interval_s", "var") || isempty(print_interval_s)
    print_interval_s = 1.0;
end

if ~exist("plot_update_s", "var") || isempty(plot_update_s)
    plot_update_s = 0.20;
end

if ~exist("accel_mode", "var") || strlength(string(accel_mode)) == 0
    accel_mode = "nominal_quick_g";
else
    accel_mode = string(accel_mode);
end

if ~exist("bias_init_s", "var") || isempty(bias_init_s)
    bias_init_s = 2.0;
end

if ~exist("nominal_sens_mv_per_g", "var") || isempty(nominal_sens_mv_per_g)
    nominal_sens_mv_per_g = 300;
end

if ~exist("sensorB_sens_mv_per_g", "var") || isempty(sensorB_sens_mv_per_g)
    sensorB_sens_mv_per_g = [300 300 300];
end

if ~exist("prompt_user", "var") || isempty(prompt_user)
    prompt_user = true;
else
    prompt_user = logical(prompt_user);
end

if prompt_user
    fprintf("\nCONFIG_LIVE_PROMPT\n");
    duration_s = prompt_numeric("Duracion en segundos", duration_s);

    in_name = strtrim(string(input(sprintf("Nombre de sesion [%s]: ", session_name), "s")));
    if strlength(in_name) > 0
        session_name = in_name;
    end

    in_prefix = strtrim(string(input(sprintf("Prefijo de archivo [%s]: ", file_prefix), "s")));
    if strlength(in_prefix) > 0
        file_prefix = in_prefix;
    end

    in_out = strtrim(string(input(sprintf("Carpeta de salida raw [%s]: ", output_dir_relpath), "s")));
    if strlength(in_out) > 0
        output_dir_relpath = in_out;
    end

    in_proc = strtrim(string(input(sprintf("Carpeta de salida processed [%s]: ", processed_dir_relpath), "s")));
    if strlength(in_proc) > 0
        processed_dir_relpath = in_proc;
    end

    save_csv = ask_yes_no("Guardar CSV raw+processed", save_csv);
    save_mat = ask_yes_no("Guardar MAT de sesion", save_mat);
    show_live_plot = ask_yes_no("Mostrar grafica live", show_live_plot);

    in_mode = lower(strtrim(string(input(sprintf("Modo grafica (raw/mv) [%s]: ", live_plot_mode), "s"))));
    if strlength(in_mode) > 0
        if ismember(in_mode, ["raw", "mv"])
            live_plot_mode = in_mode;
        else
            fprintf("Modo no valido, se conserva: %s\n", live_plot_mode);
        end
    end
end

%% Rutas de salida
script_dir = fileparts(mfilename("fullpath"));
addpath(script_dir);
repo_dir = fileparts(fileparts(script_dir));
output_dir = fullfile(repo_dir, char(output_dir_relpath));
processed_dir = fullfile(repo_dir, char(processed_dir_relpath));
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");

if ~isfolder(output_dir)
    mkdir(output_dir);
end
if ~isfolder(processed_dir)
    mkdir(processed_dir);
end
if ~isfolder(analysis_out_dir)
    mkdir(analysis_out_dir);
end

stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
base_name = file_prefix + "_" + session_name + "_" + stamp;
raw_csv_abs = fullfile(output_dir, char(base_name + "_raw.csv"));
processed_csv_abs = fullfile(processed_dir, char(base_name + "_processed.csv"));
mat_abs = fullfile(processed_dir, char(base_name + "_session.mat"));
summary_txt_abs = fullfile(analysis_out_dir, char(base_name + "_summary.txt"));

%% Live setup
fprintf("\nLIVE_SESSION_START\n");
fprintf("SENSOR_ID: %s\n", sensor_id);
fprintf("PORT: %s\n", port);
fprintf("BAUD: %d\n", baud);
fprintf("DURATION_S: %.1f\n", duration_s);
fprintf("ACCEL_MODE: %s\n", accel_mode);
fprintf("LIVE_PLOT_MODE: %s\n", live_plot_mode);
fprintf("SAVE_CSV: %s\n", string(save_csv));
fprintf("SAVE_MAT: %s\n", string(save_mat));
fprintf("OUTPUT_DIR: %s\n", make_relpath(output_dir, repo_dir));

s = serialport(port, baud, "Timeout", 1.0);
cleanup_serial = onCleanup(@() clear("s"));
configureTerminator(s, "LF");
flush(s);
pause(0.1);

% Buffers
samples = zeros(0, 8);      % seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z
wall_s = zeros(0, 1);
metadata_lines = strings(0, 1);
header_seen = false;
invalid_lines = 0;

% Figure
if show_live_plot
    fig = figure("Name", "sensor_B live session", "NumberTitle", "off");
    tl = tiledlayout(fig, 2, 1, "Padding", "compact", "TileSpacing", "compact");
    ax_top = nexttile(tl, 1);
    ax_bottom = nexttile(tl, 2);

    l1 = plot(ax_top, nan, nan, "LineWidth", 1.0); hold(ax_top, "on");
    l2 = plot(ax_top, nan, nan, "LineWidth", 1.0);
    l3 = plot(ax_top, nan, nan, "LineWidth", 1.0); hold(ax_top, "off");
    grid(ax_top, "on");
    legend(ax_top, "x", "y", "z", "Location", "best");

    lgx = plot(ax_bottom, nan, nan, "LineWidth", 1.0); hold(ax_bottom, "on");
    lgy = plot(ax_bottom, nan, nan, "LineWidth", 1.0);
    lgz = plot(ax_bottom, nan, nan, "LineWidth", 1.0);
    lgn = plot(ax_bottom, nan, nan, "k", "LineWidth", 1.2); hold(ax_bottom, "off");
    grid(ax_bottom, "on");
    legend(ax_bottom, "gx", "gy", "gz", "|g|", "Location", "best");

    if live_plot_mode == "raw"
        ylabel(ax_top, "ADC raw");
        title(ax_top, "Live raw_x/raw_y/raw_z");
    else
        ylabel(ax_top, "mV");
        title(ax_top, "Live mv_x/mv_y/mv_z");
    end
    xlabel(ax_top, "Tiempo [s]");
    ylabel(ax_bottom, "g (estimado)");
    xlabel(ax_bottom, "Tiempo [s]");
    title(ax_bottom, "gx/gy/gz y |g| (" + accel_mode + ")");
end

start_tic = tic;
last_print_t = -inf;
last_plot_t = -inf;

%% Bucle live
while toc(start_tic) < duration_s
    has_data = false;
    while s.NumBytesAvailable > 0
        line = string(readline(s));
        parsed = parse_adxl335_stream_line(line);

        switch parsed.kind
            case "metadata"
                metadata_lines(end+1, 1) = parsed.text; %#ok<SAGROW>
            case "header"
                header_seen = true;
            case "data"
                samples(end+1, :) = parsed.values; %#ok<SAGROW>
                wall_s(end+1, 1) = toc(start_tic); %#ok<SAGROW>
                has_data = true;
            case "invalid"
                invalid_lines = invalid_lines + 1;
        end
    end

    now_s = toc(start_tic);

    if now_s - last_print_t >= print_interval_s
        rem_s = max(0, duration_s - now_s);
        n = size(samples, 1);
        if n >= 2
            stream_dt = (samples(end,2) - samples(1,2)) / 1e6;
            if stream_dt > 0
                est_hz = (n - 1) / stream_dt;
            else
                est_hz = n / max(now_s, eps);
            end
        else
            est_hz = n / max(now_s, eps);
        end
        fprintf("LIVE_PROGRESS t=%.1fs rem=%.1fs samples=%d est_hz=%.2f\n", now_s, rem_s, n, est_hz);
        last_print_t = now_s;
    end

    if show_live_plot && now_s - last_plot_t >= plot_update_s && ~isempty(samples) && isvalid(fig)
        t_plot = wall_s;
        raw_plot = samples(:, 3:5);
        mv_plot = samples(:, 6:8);

        n_bias_live = max(1, min(size(mv_plot,1), round(bias_init_s * max(size(mv_plot,1) / max(now_s, eps), 1))));
        [g_xyz_live, g_norm_live] = estimate_sensorB_accel_g(mv_plot, ...
            "mode", accel_mode, ...
            "bias_init_samples", n_bias_live, ...
            "nominal_sens_mv_per_g", nominal_sens_mv_per_g, ...
            "sensorB_sens_mv_per_g", sensorB_sens_mv_per_g);

        if live_plot_mode == "raw"
            set(l1, "XData", t_plot, "YData", raw_plot(:,1));
            set(l2, "XData", t_plot, "YData", raw_plot(:,2));
            set(l3, "XData", t_plot, "YData", raw_plot(:,3));
        else
            set(l1, "XData", t_plot, "YData", mv_plot(:,1));
            set(l2, "XData", t_plot, "YData", mv_plot(:,2));
            set(l3, "XData", t_plot, "YData", mv_plot(:,3));
        end

        set(lgx, "XData", t_plot, "YData", g_xyz_live(:,1));
        set(lgy, "XData", t_plot, "YData", g_xyz_live(:,2));
        set(lgz, "XData", t_plot, "YData", g_xyz_live(:,3));
        set(lgn, "XData", t_plot, "YData", g_norm_live);
        drawnow limitrate;
        last_plot_t = now_s;
    end

    if ~has_data
        pause(0.002);
    end
end

%% Cierre y armado de salida
n_samples = size(samples, 1);
if n_samples == 0
    error("Sesion live sin muestras validas. Verifique puerto, firmware y stream serial.");
end

seq = samples(:,1);
t_us = samples(:,2);
raw_x = samples(:,3); raw_y = samples(:,4); raw_z = samples(:,5);
mv_x = samples(:,6);  mv_y = samples(:,7);  mv_z = samples(:,8);

seq_jumps = nnz(diff(seq) ~= 1);
if n_samples >= 2
    stream_duration_s = (t_us(end) - t_us(1)) / 1e6;
    freq_hz = (n_samples - 1) / max(stream_duration_s, eps);
else
    stream_duration_s = 0;
    freq_hz = n_samples / max(duration_s, eps);
end

n_bias = max(1, min(n_samples, round(bias_init_s * max(freq_hz, 1))));
mv_mat = [mv_x mv_y mv_z];
[g_xyz, g_norm, g_info] = estimate_sensorB_accel_g(mv_mat, ...
    "mode", accel_mode, ...
    "bias_init_samples", n_bias, ...
    "nominal_sens_mv_per_g", nominal_sens_mv_per_g, ...
    "sensorB_sens_mv_per_g", sensorB_sens_mv_per_g);

gx = g_xyz(:,1);
gy = g_xyz(:,2);
gz = g_xyz(:,3);

raw_tbl = table( ...
    seq, t_us, wall_s, raw_x, raw_y, raw_z, mv_x, mv_y, mv_z, ...
    'VariableNames', {'seq','t_us','wall_s','raw_x','raw_y','raw_z','mv_x','mv_y','mv_z'});

processed_tbl = table( ...
    seq, t_us, wall_s, raw_x, raw_y, raw_z, mv_x, mv_y, mv_z, gx, gy, gz, g_norm, ...
    'VariableNames', { ...
    'seq','t_us','wall_s','raw_x','raw_y','raw_z','mv_x','mv_y','mv_z', ...
    'gx_est','gy_est','gz_est','g_norm_est'});

saved_raw_csv = "not_saved";
saved_processed_csv = "not_saved";
saved_mat = "not_saved";

if save_csv
    writetable(raw_tbl, raw_csv_abs);
    writetable(processed_tbl, processed_csv_abs);
    saved_raw_csv = make_relpath(raw_csv_abs, repo_dir);
    saved_processed_csv = make_relpath(processed_csv_abs, repo_dir);
end

if save_mat
    live_config = struct();
    live_config.sensor_id = sensor_id;
    live_config.port = port;
    live_config.baud = baud;
    live_config.duration_s = duration_s;
    live_config.session_name = session_name;
    live_config.file_prefix = file_prefix;
    live_config.output_dir_relpath = output_dir_relpath;
    live_config.processed_dir_relpath = processed_dir_relpath;
    live_config.accel_mode = accel_mode;
    live_config.bias_init_s = bias_init_s;
    live_config.nominal_sens_mv_per_g = nominal_sens_mv_per_g;
    live_config.sensorB_sens_mv_per_g = sensorB_sens_mv_per_g;

    live_summary = struct();
    live_summary.samples = n_samples;
    live_summary.seq_jumps = seq_jumps;
    live_summary.stream_duration_s = stream_duration_s;
    live_summary.freq_hz = freq_hz;
    live_summary.invalid_lines = invalid_lines;
    live_summary.header_seen = header_seen;
    live_summary.metadata_lines = metadata_lines;
    live_summary.g_info = g_info;

    save(mat_abs, "live_config", "live_summary", "raw_tbl", "processed_tbl");
    saved_mat = make_relpath(mat_abs, repo_dir);
end

% Resumen txt
fid = fopen(summary_txt_abs, "w");
if fid < 0
    error("No se pudo crear resumen live: %s", summary_txt_abs);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/live/run_sensorB_live_session.m\n");
fprintf(fid, "sensor_id: %s\n", sensor_id);
fprintf(fid, "port: %s\n", port);
fprintf(fid, "baud: %d\n", baud);
fprintf(fid, "duration_s: %.3f\n", duration_s);
fprintf(fid, "session_name: %s\n", session_name);
fprintf(fid, "file_prefix: %s\n", file_prefix);
fprintf(fid, "accel_mode: %s\n", accel_mode);
fprintf(fid, "samples: %d\n", n_samples);
fprintf(fid, "stream_duration_s: %.6f\n", stream_duration_s);
fprintf(fid, "freq_hz: %.6f\n", freq_hz);
fprintf(fid, "seq_jumps: %d\n", seq_jumps);
fprintf(fid, "invalid_lines_ignored: %d\n", invalid_lines);
fprintf(fid, "header_seen: %s\n", string(header_seen));
fprintf(fid, "bias_mv: %.6f,%.6f,%.6f\n", g_info.bias_mv(1), g_info.bias_mv(2), g_info.bias_mv(3));
fprintf(fid, "sens_mv_per_g: %.6f,%.6f,%.6f\n", g_info.sens_mv_per_g(1), g_info.sens_mv_per_g(2), g_info.sens_mv_per_g(3));
fprintf(fid, "raw_csv_relpath: %s\n", saved_raw_csv);
fprintf(fid, "processed_csv_relpath: %s\n", saved_processed_csv);
fprintf(fid, "mat_relpath: %s\n", saved_mat);
fprintf(fid, "summary_txt_relpath: %s\n", make_relpath(summary_txt_abs, repo_dir));
fprintf(fid, "next_block_input_relpath: %s\n", saved_processed_csv);

fprintf("\nLIVE_SESSION_DONE\n");
fprintf("SAMPLES: %d\n", n_samples);
fprintf("FREQ_HZ: %.3f\n", freq_hz);
fprintf("SEQ_JUMPS: %d\n", seq_jumps);
fprintf("RAW_CSV: %s\n", saved_raw_csv);
fprintf("PROCESSED_CSV: %s\n", saved_processed_csv);
fprintf("MAT_FILE: %s\n", saved_mat);
fprintf("SUMMARY_TXT: %s\n", make_relpath(summary_txt_abs, repo_dir));
fprintf("NEXT_BLOCK_INPUT: %s\n", saved_processed_csv);

%% Local functions
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

function out = ask_yes_no(label, default_val)
if default_val
    suffix = " [Y/n]: ";
else
    suffix = " [y/N]: ";
end
in = strtrim(lower(string(input(label + suffix, "s"))));
if strlength(in) == 0
    out = logical(default_val);
elseif ismember(in, ["y", "yes", "s", "si"])
    out = true;
elseif ismember(in, ["n", "no"])
    out = false;
else
    out = logical(default_val);
end
end

function out = prompt_numeric(label, default_val)
in = strtrim(string(input(sprintf("%s [%.2f]: ", label, double(default_val)), "s")));
if strlength(in) == 0
    out = double(default_val);
    return;
end
val = str2double(in);
if isnan(val) || val <= 0
    out = double(default_val);
else
    out = double(val);
end
end
