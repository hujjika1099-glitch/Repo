% run_sensorB_live_session.m
% Fase 14A - Sesion live MATLAB (serial directo actual).
%
% Funciones:
% - captura en vivo desde serial
% - visualizacion live de |g| estimado para sensor 1 y sensor 2
% - guardado raw y procesado al finalizar
%
% Nota:
% - Conversion a g usa ruta minima util (nominal_quick_g por defecto).
% - No usa calibracion especifica por sensor.

%% Configuracion de sesion
if ~exist("sensor_id", "var") || strlength(string(sensor_id)) == 0
    sensor_id = "sensor_B";
else
    sensor_id = string(sensor_id);
end

if ~exist("plot_sensor_numeric_id", "var") || isempty(plot_sensor_numeric_id)
    plot_sensor_numeric_id = sensor_numeric_id_from_label(sensor_id);
else
    plot_sensor_numeric_id = double(plot_sensor_numeric_id);
end

if ~exist("second_sensor_numeric_id", "var") || isempty(second_sensor_numeric_id)
    second_sensor_numeric_id = 2;
else
    second_sensor_numeric_id = double(second_sensor_numeric_id);
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
    live_plot_mode = "dual_g_norm";
else
    live_plot_mode = lower(string(live_plot_mode));
end

if ~exist("print_interval_s", "var") || isempty(print_interval_s)
    print_interval_s = 1.0;
end

if ~exist("plot_update_s", "var") || isempty(plot_update_s)
    plot_update_s = 0.20;
end

if ~exist("port_probe_timeout_s", "var") || isempty(port_probe_timeout_s)
    port_probe_timeout_s = 1.6;
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

if ~exist("dual_precheck_enabled", "var") || isempty(dual_precheck_enabled)
    dual_precheck_enabled = true;
else
    dual_precheck_enabled = logical(dual_precheck_enabled);
end

if ~exist("dual_precheck_duration_s", "var") || isempty(dual_precheck_duration_s)
    dual_precheck_duration_s = 10.0;
end

if ~exist("dual_precheck_min_samples_per_sensor", "var") || isempty(dual_precheck_min_samples_per_sensor)
    dual_precheck_min_samples_per_sensor = 250;
end

if ~exist("dual_precheck_max_seq_jump_ratio", "var") || isempty(dual_precheck_max_seq_jump_ratio)
    dual_precheck_max_seq_jump_ratio = 0.10;
end

if ~exist("dual_precheck_max_saturation_pct", "var") || isempty(dual_precheck_max_saturation_pct)
    dual_precheck_max_saturation_pct = 20.0;
end

if ~exist("dual_precheck_min_mv_axis_span", "var") || isempty(dual_precheck_min_mv_axis_span)
    dual_precheck_min_mv_axis_span = 0.5;
end

if ~exist("prompt_user", "var") || isempty(prompt_user)
    prompt_user = true;
else
    prompt_user = logical(prompt_user);
end

if prompt_user
    fprintf("\nCONFIG_LIVE_PROMPT\n");
    duration_s = prompt_numeric("Duracion en segundos", duration_s);

    in_prefix = strtrim(string(input(sprintf("Nombre base de archivo [%s]: ", file_prefix), "s")));
    if strlength(in_prefix) > 0
        file_prefix = in_prefix;
    end
end

%% Rutas de salida
script_dir = fileparts(mfilename("fullpath"));
addpath(script_dir);
repo_dir = fileparts(fileparts(script_dir));
common_dir = fullfile(repo_dir, "matlab", "common");
addpath(common_dir);
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
precheck_txt_abs = fullfile(analysis_out_dir, char(base_name + "_precheck.txt"));

requested_port = string(port);
[port, port_resolution] = resolve_adxl_serial_port( ...
    "preferred_port", requested_port, ...
    "baud", baud, ...
    "probe_timeout_s", port_probe_timeout_s, ...
    "verbose", true);

%% Live setup
fprintf("\nLIVE_SESSION_START\n");
fprintf("SENSOR_ID: %s\n", sensor_id);
fprintf("PLOT_SENSOR_NUMERIC_ID: %d\n", plot_sensor_numeric_id);
fprintf("SECOND_SENSOR_NUMERIC_ID: %d\n", second_sensor_numeric_id);
fprintf("PORT_REQUESTED: %s\n", empty_if_blank(requested_port));
fprintf("PORT: %s\n", port);
fprintf("PORT_RESOLUTION_MODE: %s\n", port_resolution.selection_mode);
fprintf("BAUD: %d\n", baud);
fprintf("DURATION_S: %.1f\n", duration_s);
fprintf("ACCEL_MODE: %s\n", accel_mode);
fprintf("LIVE_PLOT_MODE: dual_g_norm\n");
fprintf("SAVE_CSV: %s\n", string(save_csv));
fprintf("SAVE_MAT: %s\n", string(save_mat));
fprintf("OUTPUT_DIR: %s\n", make_relpath(output_dir, repo_dir));

s = serialport(port, baud, "Timeout", 1.0);
cleanup_serial = onCleanup(@() clear("s"));
configureTerminator(s, "LF");
flush(s);
pause(0.1);

required_sensor_ids = [plot_sensor_numeric_id second_sensor_numeric_id];

if dual_precheck_enabled
    fprintf("\nDUAL_INTEGRITY_PRECHECK_START\n");
    fprintf("PRECHECK_DURATION_S: %.1f\n", dual_precheck_duration_s);
    fprintf("PRECHECK_REQUIRED_SENSORS: %d,%d\n", required_sensor_ids(1), required_sensor_ids(2));
    fprintf("PRECHECK_NOTE: mantenga ambos sensores quietos y montados durante la ventana de integridad.\n");

    precheck_tic = tic;
    precheck_samples = zeros(0, 9);
    precheck_wall_s = zeros(0, 1);
    precheck_metadata_lines = strings(0, 1);
    precheck_header_seen = false;
    precheck_invalid_lines = 0;
    precheck_last_print_t = -inf;

    while toc(precheck_tic) < dual_precheck_duration_s
        while s.NumBytesAvailable > 0
            line = string(readline(s));
            parsed = parse_adxl335_stream_line(line);

            switch parsed.kind
                case "metadata"
                    precheck_metadata_lines(end+1, 1) = parsed.text; %#ok<SAGROW>
                case "header"
                    precheck_header_seen = true;
                case "data"
                    precheck_samples(end+1, :) = parsed.values; %#ok<SAGROW>
                    precheck_wall_s(end+1, 1) = toc(precheck_tic); %#ok<SAGROW>
                case "invalid"
                    precheck_invalid_lines = precheck_invalid_lines + 1;
            end
        end

        precheck_now_s = toc(precheck_tic);
        if precheck_now_s - precheck_last_print_t >= print_interval_s
            n_precheck = size(precheck_samples, 1);
            n_s1_pre = nnz(precheck_samples(:,1) == plot_sensor_numeric_id);
            n_s2_pre = nnz(precheck_samples(:,1) == second_sensor_numeric_id);
            fprintf("PRECHECK_PROGRESS t=%.1fs samples=%d sensor_%d=%d sensor_%d=%d\n", ...
                precheck_now_s, n_precheck, plot_sensor_numeric_id, n_s1_pre, ...
                second_sensor_numeric_id, n_s2_pre);
            precheck_last_print_t = precheck_now_s;
        end

        pause(0.002);
    end

    precheck_result = evaluate_dual_integrity_window( ...
        precheck_samples, precheck_wall_s, required_sensor_ids, accel_mode, ...
        nominal_sens_mv_per_g, sensorB_sens_mv_per_g, bias_init_s, ...
        dual_precheck_min_samples_per_sensor, dual_precheck_max_seq_jump_ratio, ...
        dual_precheck_max_saturation_pct, dual_precheck_min_mv_axis_span, ...
        precheck_invalid_lines, precheck_header_seen, true);
    write_dual_precheck_report(precheck_txt_abs, precheck_result, repo_dir, requested_port, port, port_resolution, baud, dual_precheck_duration_s);

    fprintf("PRECHECK_STATUS: %s\n", precheck_result.logic_status);
    fprintf("PRECHECK_REASON: %s\n", precheck_result.logic_reason);
    fprintf("PRECHECK_REPORT: %s\n", make_relpath(precheck_txt_abs, repo_dir));
    for idx = 1:numel(precheck_result.sensor_checks)
        check_k = precheck_result.sensor_checks(idx);
        fprintf("PRECHECK_SENSOR_%d: %s (%s)\n", check_k.sensor_id, check_k.logic_status, check_k.logic_reason);
    end

    if precheck_result.logic_status ~= "pass"
        error("Precheck dual no superado: %s. Revise %s", precheck_result.logic_reason, make_relpath(precheck_txt_abs, repo_dir));
    end

    flush(s);
    pause(0.1);
end

% Buffers
samples = zeros(0, 9);      % sensor_id,seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z
wall_s = zeros(0, 1);
metadata_lines = strings(0, 1);
header_seen = false;
invalid_lines = 0;

% Figure
if show_live_plot
    fig = figure("Name", "dual sensor live session", "NumberTitle", "off");
    ax_g = axes(fig);
    lg1 = plot(ax_g, nan, nan, "LineWidth", 1.4); hold(ax_g, "on");
    lg2 = plot(ax_g, nan, nan, "LineWidth", 1.4);
    yline(ax_g, 1.0, "--k", "1 g");
    hold(ax_g, "off");
    grid(ax_g, "on");
    legend(ax_g, "sensor 1 |g|", "sensor 2 |g|", "Location", "best");
    ylabel(ax_g, "|g| estimado");
    xlabel(ax_g, "Tiempo [s]");
    title(ax_g, "Live |g| sensor 1 vs sensor 2 (" + accel_mode + ")");
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
        n_plot_sensor = nnz(samples(:,1) == plot_sensor_numeric_id);
        n_second_sensor = nnz(samples(:,1) == second_sensor_numeric_id);
        est_hz_total = n / max(now_s, eps);
        est_hz_s1 = n_plot_sensor / max(now_s, eps);
        est_hz_s2 = n_second_sensor / max(now_s, eps);
        fprintf("LIVE_PROGRESS t=%.1fs rem=%.1fs samples=%d est_hz_total=%.2f sensor_%d=%d hz=%.2f sensor_%d=%d hz=%.2f\n", ...
            now_s, rem_s, n, est_hz_total, plot_sensor_numeric_id, n_plot_sensor, est_hz_s1, ...
            second_sensor_numeric_id, n_second_sensor, est_hz_s2);
        last_print_t = now_s;
    end

    if show_live_plot && now_s - last_plot_t >= plot_update_s && ~isempty(samples) && isvalid(fig)
        [t_plot_1, g_norm_live_1] = build_live_gnorm_trace(samples, wall_s, plot_sensor_numeric_id, ...
            accel_mode, nominal_sens_mv_per_g, sensorB_sens_mv_per_g, bias_init_s, now_s);
        [t_plot_2, g_norm_live_2] = build_live_gnorm_trace(samples, wall_s, second_sensor_numeric_id, ...
            accel_mode, nominal_sens_mv_per_g, sensorB_sens_mv_per_g, bias_init_s, now_s);

        set(lg1, "XData", t_plot_1, "YData", g_norm_live_1);
        set(lg2, "XData", t_plot_2, "YData", g_norm_live_2);
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

sensor_id_num = samples(:,1);
seq = samples(:,2);
t_us = samples(:,3);
raw_x = samples(:,4); raw_y = samples(:,5); raw_z = samples(:,6);
mv_x = samples(:,7);  mv_y = samples(:,8);  mv_z = samples(:,9);

seq_jumps = nnz(diff(seq(sensor_id_num == plot_sensor_numeric_id)) ~= 1);
if n_samples >= 2
    stream_duration_s = max(0, wall_s(end) - wall_s(1));
    freq_hz = (n_samples - 1) / max(stream_duration_s, eps);
else
    stream_duration_s = 0;
    freq_hz = n_samples / max(duration_s, eps);
end

gx = nan(n_samples, 1);
gy = nan(n_samples, 1);
gz = nan(n_samples, 1);
g_norm = nan(n_samples, 1);
g_info = struct();
sensor_summaries = empty_sensor_summaries();

unique_sensor_ids = unique(sensor_id_num(:)).';
for sensor_k = unique_sensor_ids
    mask_k = sensor_id_num == sensor_k;
    mv_mat_k = samples(mask_k, 7:9);
    n_bias_k = max(1, min(size(mv_mat_k, 1), round(bias_init_s * max(size(mv_mat_k, 1) / max(duration_s, eps), 1))));
    [g_xyz_k, g_norm_k, g_info_k] = estimate_sensorB_accel_g(mv_mat_k, ...
        "mode", accel_mode, ...
        "bias_init_samples", n_bias_k, ...
        "nominal_sens_mv_per_g", nominal_sens_mv_per_g, ...
        "sensorB_sens_mv_per_g", sensorB_sens_mv_per_g);

    gx(mask_k) = g_xyz_k(:,1);
    gy(mask_k) = g_xyz_k(:,2);
    gz(mask_k) = g_xyz_k(:,3);
    g_norm(mask_k) = g_norm_k;

    sensor_summaries(end+1, 1) = build_sensor_summary( ... %#ok<SAGROW>
        samples(mask_k, :), wall_s(mask_k), sensor_k, accel_mode, ...
        nominal_sens_mv_per_g, sensorB_sens_mv_per_g, bias_init_s);

    if sensor_k == plot_sensor_numeric_id || isempty(fieldnames(g_info))
        g_info = g_info_k;
    end
end

capture_integrity = evaluate_dual_integrity_window( ...
    samples, wall_s, required_sensor_ids, accel_mode, nominal_sens_mv_per_g, ...
    sensorB_sens_mv_per_g, bias_init_s, dual_precheck_min_samples_per_sensor, ...
    dual_precheck_max_seq_jump_ratio, dual_precheck_max_saturation_pct, dual_precheck_min_mv_axis_span, ...
    invalid_lines, header_seen, false);

raw_tbl = table( ...
    sensor_id_num, seq, t_us, wall_s, raw_x, raw_y, raw_z, mv_x, mv_y, mv_z, ...
    'VariableNames', {'sensor_id','seq','t_us','wall_s','raw_x','raw_y','raw_z','mv_x','mv_y','mv_z'});

processed_tbl = table( ...
    sensor_id_num, seq, t_us, wall_s, raw_x, raw_y, raw_z, mv_x, mv_y, mv_z, gx, gy, gz, g_norm, ...
    'VariableNames', { ...
    'sensor_id','seq','t_us','wall_s','raw_x','raw_y','raw_z','mv_x','mv_y','mv_z', ...
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
    live_config.plot_sensor_numeric_id = plot_sensor_numeric_id;
    live_config.second_sensor_numeric_id = second_sensor_numeric_id;
    live_config.requested_port = requested_port;
    live_config.port = port;
    live_config.port_resolution = port_resolution;
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
    live_summary.sensor_summaries = sensor_summaries;
    live_summary.capture_integrity = capture_integrity;
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
fprintf(fid, "plot_sensor_numeric_id: %d\n", plot_sensor_numeric_id);
fprintf(fid, "second_sensor_numeric_id: %d\n", second_sensor_numeric_id);
fprintf(fid, "requested_port: %s\n", empty_if_blank(requested_port));
fprintf(fid, "port: %s\n", port);
fprintf(fid, "port_resolution_mode: %s\n", port_resolution.selection_mode);
fprintf(fid, "port_resolution_detail: %s\n", port_resolution.selection_detail);
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
fprintf(fid, "capture_integrity_status: %s\n", capture_integrity.logic_status);
fprintf(fid, "capture_integrity_reason: %s\n", capture_integrity.logic_reason);
fprintf(fid, "bias_mv: %.6f,%.6f,%.6f\n", g_info.bias_mv(1), g_info.bias_mv(2), g_info.bias_mv(3));
fprintf(fid, "sens_mv_per_g: %.6f,%.6f,%.6f\n", g_info.sens_mv_per_g(1), g_info.sens_mv_per_g(2), g_info.sens_mv_per_g(3));
for idx = 1:numel(sensor_summaries)
    summary_k = sensor_summaries(idx);
    fprintf(fid, "sensor_%d_label: %s\n", summary_k.sensor_id, summary_k.sensor_label);
    fprintf(fid, "sensor_%d_samples: %d\n", summary_k.sensor_id, summary_k.samples);
    fprintf(fid, "sensor_%d_freq_hz: %.6f\n", summary_k.sensor_id, summary_k.freq_hz);
    fprintf(fid, "sensor_%d_seq_jumps: %d\n", summary_k.sensor_id, summary_k.seq_jumps);
    fprintf(fid, "sensor_%d_g_norm_median: %.6f\n", summary_k.sensor_id, summary_k.g_norm_median);
    fprintf(fid, "sensor_%d_max_saturation_pct: %.6f\n", summary_k.sensor_id, summary_k.max_saturation_pct);
    fprintf(fid, "sensor_%d_logic_status: %s\n", summary_k.sensor_id, summary_k.logic_status);
    fprintf(fid, "sensor_%d_logic_reason: %s\n", summary_k.sensor_id, summary_k.logic_reason);
end
fprintf(fid, "raw_csv_relpath: %s\n", saved_raw_csv);
fprintf(fid, "processed_csv_relpath: %s\n", saved_processed_csv);
fprintf(fid, "mat_relpath: %s\n", saved_mat);
fprintf(fid, "precheck_txt_relpath: %s\n", make_relpath(precheck_txt_abs, repo_dir));
fprintf(fid, "summary_txt_relpath: %s\n", make_relpath(summary_txt_abs, repo_dir));
fprintf(fid, "next_block_input_relpath: %s\n", saved_processed_csv);

fprintf("\nLIVE_SESSION_DONE\n");
fprintf("SAMPLES: %d\n", n_samples);
fprintf("FREQ_HZ: %.3f\n", freq_hz);
fprintf("SEQ_JUMPS: %d\n", seq_jumps);
fprintf("CAPTURE_INTEGRITY: %s (%s)\n", capture_integrity.logic_status, capture_integrity.logic_reason);
for idx = 1:numel(sensor_summaries)
    summary_k = sensor_summaries(idx);
    fprintf("SENSOR_%d_STATUS: %s (%s)\n", summary_k.sensor_id, summary_k.logic_status, summary_k.logic_reason);
end
fprintf("RAW_CSV: %s\n", saved_raw_csv);
fprintf("PROCESSED_CSV: %s\n", saved_processed_csv);
fprintf("MAT_FILE: %s\n", saved_mat);
fprintf("PRECHECK_TXT: %s\n", make_relpath(precheck_txt_abs, repo_dir));
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

function out = empty_if_blank(in)
in = string(in);
if strlength(in) == 0
    out = "(auto)";
else
    out = in;
end
end

function out = empty_integrity_sensor_checks()
out = struct( ...
    'sensor_id', {}, ...
    'sensor_label', {}, ...
    'samples', {}, ...
    'freq_hz', {}, ...
    'seq_jumps', {}, ...
    'seq_backtracks', {}, ...
    't_backtracks', {}, ...
    'max_saturation_pct', {}, ...
    'max_zero_axis_pct', {}, ...
    'max_flatline_142_pct', {}, ...
    'g_norm_median', {}, ...
    'logic_status', {}, ...
    'logic_reason', {});
end

function result = evaluate_dual_integrity_window(samples, wall_s, required_sensor_ids, accel_mode, nominal_sens_mv_per_g, sensorB_sens_mv_per_g, bias_init_s, min_samples_per_sensor, max_seq_jump_ratio, max_saturation_pct, min_mv_axis_span, invalid_lines, header_seen, require_static_gnorm)
result = struct();
result.logic_status = "pass";
result.logic_reason = "dual_integrity_ok";
result.samples = size(samples, 1);
result.invalid_lines = double(invalid_lines);
result.header_seen = logical(header_seen);
result.sensor_checks = empty_integrity_sensor_checks();

reasons = strings(0, 1);

if ~result.header_seen
    result.logic_status = "fail";
    result.logic_reason = "missing_header";
    return;
end

for sensor_id_k = reshape(double(required_sensor_ids), 1, [])
    mask_k = samples(:,1) == sensor_id_k;
    check_k = build_integrity_sensor_check( ...
        samples(mask_k, :), wall_s(mask_k), sensor_id_k, accel_mode, ...
        nominal_sens_mv_per_g, sensorB_sens_mv_per_g, bias_init_s, ...
        min_samples_per_sensor, max_seq_jump_ratio, max_saturation_pct, min_mv_axis_span, require_static_gnorm);
    result.sensor_checks(end+1, 1) = check_k; %#ok<SAGROW>

    if check_k.logic_status ~= "pass"
        reasons(end+1, 1) = "sensor_" + string(check_k.sensor_id) + ":" + check_k.logic_reason; %#ok<SAGROW>
    end
end

if result.invalid_lines > 25
    reasons(end+1, 1) = "invalid_lines_excessive"; %#ok<SAGROW>
end

if ~isempty(reasons)
    result.logic_status = "fail";
    result.logic_reason = strjoin(reasons, ";");
end
end

function check = build_integrity_sensor_check(sensor_samples, sensor_wall_s, sensor_id_num, accel_mode, nominal_sens_mv_per_g, sensorB_sens_mv_per_g, bias_init_s, min_samples_per_sensor, max_seq_jump_ratio, max_saturation_pct, min_mv_axis_span, require_static_gnorm)
check = struct( ...
    'sensor_id', double(sensor_id_num), ...
    'sensor_label', sensor_label_from_numeric_id(sensor_id_num), ...
    'samples', size(sensor_samples, 1), ...
    'freq_hz', 0, ...
    'seq_jumps', 0, ...
    'seq_backtracks', 0, ...
    't_backtracks', 0, ...
    'max_saturation_pct', NaN, ...
    'max_zero_axis_pct', NaN, ...
    'max_flatline_142_pct', NaN, ...
    'g_norm_median', NaN, ...
    'logic_status', "suspect", ...
    'logic_reason', "not_evaluated");

if isempty(sensor_samples)
    check.logic_status = "fail";
    check.logic_reason = "sensor_missing";
    return;
end

summary = build_sensor_summary(sensor_samples, sensor_wall_s, sensor_id_num, accel_mode, nominal_sens_mv_per_g, sensorB_sens_mv_per_g, bias_init_s);
seq = sensor_samples(:, 2);
t_us = sensor_samples(:, 3);
raw = sensor_samples(:, 4:6);
mv = sensor_samples(:, 7:9);

check.freq_hz = summary.freq_hz;
check.seq_jumps = summary.seq_jumps;
check.max_saturation_pct = summary.max_saturation_pct;
check.g_norm_median = summary.g_norm_median;
check.seq_backtracks = nnz(diff(seq) < 0);
check.t_backtracks = nnz(diff(t_us) < 0);
check.max_zero_axis_pct = max(mean(raw == 0, 1) * 100);
check.max_flatline_142_pct = max(mean(mv == 142, 1) * 100);

seq_jump_ratio = check.seq_jumps / max(check.samples - 1, 1);

if check.samples < min_samples_per_sensor
    check.logic_status = "fail";
    check.logic_reason = "few_samples";
elseif check.seq_backtracks > 0 || check.t_backtracks > 0
    check.logic_status = "fail";
    check.logic_reason = "counter_reset_detected";
elseif check.max_saturation_pct > max_saturation_pct
    check.logic_status = "fail";
    check.logic_reason = "adc_saturation";
elseif check.max_zero_axis_pct > 95 || check.max_flatline_142_pct > 95
    check.logic_status = "fail";
    check.logic_reason = "dead_axis_or_disconnected";
elseif require_static_gnorm && summary.min_mv_span < min_mv_axis_span
    check.logic_status = "fail";
    check.logic_reason = "low_signal_span_static";
elseif seq_jump_ratio > max_seq_jump_ratio
    check.logic_status = "fail";
    check.logic_reason = "packet_loss_excessive";
else
    check.logic_status = "pass";
    check.logic_reason = "integrity_ok";
end
end

function write_dual_precheck_report(abs_path, precheck_result, repo_dir, requested_port, port, port_resolution, baud, precheck_duration_s)
fid = fopen(abs_path, "w");
if fid < 0
    error("No se pudo crear reporte de precheck: %s", abs_path);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/live/run_sensorB_live_session.m\n");
fprintf(fid, "phase: dual_integrity_precheck\n");
fprintf(fid, "requested_port: %s\n", empty_if_blank(requested_port));
fprintf(fid, "port: %s\n", port);
fprintf(fid, "port_resolution_mode: %s\n", port_resolution.selection_mode);
fprintf(fid, "port_resolution_detail: %s\n", port_resolution.selection_detail);
fprintf(fid, "baud: %d\n", baud);
fprintf(fid, "precheck_duration_s: %.3f\n", precheck_duration_s);
fprintf(fid, "samples: %d\n", precheck_result.samples);
fprintf(fid, "invalid_lines_ignored: %d\n", precheck_result.invalid_lines);
fprintf(fid, "header_seen: %s\n", string(precheck_result.header_seen));
fprintf(fid, "precheck_status: %s\n", precheck_result.logic_status);
fprintf(fid, "precheck_reason: %s\n", precheck_result.logic_reason);
for idx = 1:numel(precheck_result.sensor_checks)
    check_k = precheck_result.sensor_checks(idx);
    fprintf(fid, "sensor_%d_label: %s\n", check_k.sensor_id, check_k.sensor_label);
    fprintf(fid, "sensor_%d_samples: %d\n", check_k.sensor_id, check_k.samples);
    fprintf(fid, "sensor_%d_freq_hz: %.6f\n", check_k.sensor_id, check_k.freq_hz);
    fprintf(fid, "sensor_%d_seq_jumps: %d\n", check_k.sensor_id, check_k.seq_jumps);
    fprintf(fid, "sensor_%d_seq_backtracks: %d\n", check_k.sensor_id, check_k.seq_backtracks);
    fprintf(fid, "sensor_%d_t_backtracks: %d\n", check_k.sensor_id, check_k.t_backtracks);
    fprintf(fid, "sensor_%d_max_saturation_pct: %.6f\n", check_k.sensor_id, check_k.max_saturation_pct);
    fprintf(fid, "sensor_%d_max_zero_axis_pct: %.6f\n", check_k.sensor_id, check_k.max_zero_axis_pct);
    fprintf(fid, "sensor_%d_max_flatline_142_pct: %.6f\n", check_k.sensor_id, check_k.max_flatline_142_pct);
    fprintf(fid, "sensor_%d_g_norm_median: %.6f\n", check_k.sensor_id, check_k.g_norm_median);
    fprintf(fid, "sensor_%d_status: %s\n", check_k.sensor_id, check_k.logic_status);
    fprintf(fid, "sensor_%d_reason: %s\n", check_k.sensor_id, check_k.logic_reason);
end
fprintf(fid, "precheck_txt_relpath: %s\n", make_relpath(abs_path, repo_dir));
end

function out = empty_sensor_summaries()
out = struct( ...
    'sensor_id', {}, ...
    'sensor_label', {}, ...
    'samples', {}, ...
    'seq_jumps', {}, ...
    'stream_duration_s', {}, ...
    'freq_hz', {}, ...
    'g_norm_median', {}, ...
    'max_saturation_pct', {}, ...
    'min_mv_span', {}, ...
    'logic_status', {}, ...
    'logic_reason', {});
end

function out = sensor_numeric_id_from_label(sensor_label)
sensor_label = lower(string(sensor_label));
switch sensor_label
    case "sensor_b"
        out = 1;
    case "sensor_a"
        out = 2;
    otherwise
        out = 1;
end
end

function out = sensor_label_from_numeric_id(sensor_id_num)
switch double(sensor_id_num)
    case 1
        out = "sensor_B";
    case 2
        out = "sensor_A";
    otherwise
        out = "sensor_unknown";
end
end

function summary = build_sensor_summary(sensor_samples, sensor_wall_s, sensor_id_num, accel_mode, nominal_sens_mv_per_g, sensorB_sens_mv_per_g, bias_init_s)
summary = struct( ...
    'sensor_id', double(sensor_id_num), ...
    'sensor_label', sensor_label_from_numeric_id(sensor_id_num), ...
    'samples', size(sensor_samples, 1), ...
    'seq_jumps', 0, ...
    'stream_duration_s', 0, ...
    'freq_hz', 0, ...
    'g_norm_median', NaN, ...
    'max_saturation_pct', NaN, ...
    'min_mv_span', NaN, ...
    'logic_status', "suspect", ...
    'logic_reason', "not_evaluated");

seq = sensor_samples(:, 2);
t_us = sensor_samples(:, 3);
raw = sensor_samples(:, 4:6);
mv = sensor_samples(:, 7:9);

summary.seq_jumps = nnz(diff(seq) ~= 1);
if numel(t_us) >= 2
    stream_duration_s = max(0, (t_us(end) - t_us(1)) / 1e6);
else
    stream_duration_s = 0;
end
summary.stream_duration_s = stream_duration_s;

if stream_duration_s > 0
    summary.freq_hz = (size(sensor_samples, 1) - 1) / stream_duration_s;
elseif numel(sensor_wall_s) >= 2
    summary.freq_hz = size(sensor_samples, 1) / max(sensor_wall_s(end) - sensor_wall_s(1), eps);
else
    summary.freq_hz = size(sensor_samples, 1);
end

n_bias = max(1, min(size(mv, 1), round(bias_init_s * max(summary.freq_hz, 1))));
[~, g_norm, ~] = estimate_sensorB_accel_g(mv, ...
    "mode", accel_mode, ...
    "bias_init_samples", n_bias, ...
    "nominal_sens_mv_per_g", nominal_sens_mv_per_g, ...
    "sensorB_sens_mv_per_g", sensorB_sens_mv_per_g);
summary.g_norm_median = median(g_norm);

sat_pct = mean(raw <= 5 | raw >= 4090, 1) * 100;
summary.max_saturation_pct = max(sat_pct);
mv_span = max(mv, [], 1) - min(mv, [], 1);
summary.min_mv_span = min(mv_span);

if summary.samples < 30
    summary.logic_status = "suspect";
    summary.logic_reason = "few_samples";
elseif summary.max_saturation_pct > 20
    summary.logic_status = "fail";
    summary.logic_reason = "adc_saturation";
elseif summary.g_norm_median < 0.30 || summary.g_norm_median > 1.70
    summary.logic_status = "fail";
    summary.logic_reason = "g_norm_implausible";
elseif summary.g_norm_median < 0.60 || summary.g_norm_median > 1.40
    summary.logic_status = "suspect";
    summary.logic_reason = "g_norm_borderline";
elseif summary.min_mv_span < 0.5
    summary.logic_status = "suspect";
    summary.logic_reason = "low_signal_span";
else
    summary.logic_status = "pass";
    summary.logic_reason = "basic_live_sanity_ok";
end
end

function [t_plot, g_norm_live] = build_live_gnorm_trace(samples, wall_s, sensor_numeric_id, accel_mode, nominal_sens_mv_per_g, sensorB_sens_mv_per_g, bias_init_s, now_s)
mask = samples(:,1) == sensor_numeric_id;
if ~any(mask)
    t_plot = nan;
    g_norm_live = nan;
    return;
end

sensor_samples = samples(mask, :);
t_plot = wall_s(mask);
mv_plot = sensor_samples(:, 7:9);
n_bias_live = max(1, min(size(mv_plot,1), round(bias_init_s * max(size(mv_plot,1) / max(now_s, eps), 1))));
[~, g_norm_live] = estimate_sensorB_accel_g(mv_plot, ...
    "mode", accel_mode, ...
    "bias_init_samples", n_bias_live, ...
    "nominal_sens_mv_per_g", nominal_sens_mv_per_g, ...
    "sensorB_sens_mv_per_g", sensorB_sens_mv_per_g);
end
