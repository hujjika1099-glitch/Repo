% capture_sensorC_selftest_pair.m
% Fase 11.1: camino minimo para capturar par ST_OFF/ST_ON.
%
% Pinout operativo (sensor_C):
% - X-OUT -> GPIO32 (ADC1_CH4)
% - Y-OUT -> GPIO33 (ADC1_CH5)
% - Z-OUT -> GPIO34 (ADC1_CH6)
% - ST pad lateral -> GPIO23 (digital output)

%% Configuracion
if ~exist("sensor_id", "var") || strlength(string(sensor_id)) == 0
    sensor_id = "sensor_C";
else
    sensor_id = string(sensor_id);
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
    duration_s = 8;
end

if ~exist("st_activation_mode", "var") || strlength(string(st_activation_mode)) == 0
    st_activation_mode = "firmware_controlled";
else
    st_activation_mode = lower(string(st_activation_mode));
end

if ~ismember(st_activation_mode, ["firmware_controlled", "manual_assisted"])
    error("st_activation_mode no soportado: %s", st_activation_mode);
end

if ~exist("st_control_gpio", "var") || isempty(st_control_gpio)
    st_control_gpio = 23;
end

if ~exist("st_settle_pause_s", "var") || isempty(st_settle_pause_s)
    st_settle_pause_s = 2;
end

if ~exist("pre_capture_pause_s", "var") || isempty(pre_capture_pause_s)
    pre_capture_pause_s = 6;
end

if ~exist("st_transition_pause_s", "var") || isempty(st_transition_pause_s)
    st_transition_pause_s = 8;
end

if ~exist("dry_run", "var") || isempty(dry_run)
    dry_run = false;
else
    dry_run = logical(dry_run);
end

if ~exist("port_probe_timeout_s", "var") || isempty(port_probe_timeout_s)
    port_probe_timeout_s = 1.6;
end

%% Rutas
script_dir = fileparts(mfilename("fullpath"));
repo_dir = fileparts(fileparts(script_dir));
common_dir = fullfile(repo_dir, "matlab", "common");
addpath(common_dir);
raw_dir = fullfile(repo_dir, "data", "raw", char(sensor_id));
analysis_out_dir = fullfile(repo_dir, "reports", "analysis_outputs");
if ~isfolder(raw_dir)
    mkdir(raw_dir);
end
if ~isfolder(analysis_out_dir)
    mkdir(analysis_out_dir);
end

stamp = string(datetime("now", "Format", "yyyyMMdd_HHmmss"));
out_base = sensor_id + "_selftest_capture_protocol_" + stamp;
manifest_csv_out = fullfile(analysis_out_dir, char(out_base + ".csv"));
summary_txt_out = fullfile(analysis_out_dir, char(out_base + ".txt"));

requested_port = string(port);
[port, port_resolution] = resolve_adxl_serial_port( ...
    "preferred_port", requested_port, ...
    "baud", baud, ...
    "probe_timeout_s", port_probe_timeout_s, ...
    "verbose", true);

capture_result = struct();
capture_result.sensor_id = sensor_id;
capture_result.requested_port = requested_port;
capture_result.port = port;
capture_result.port_resolution_mode = port_resolution.selection_mode;
capture_result.port_resolution_detail = port_resolution.selection_detail;
capture_result.baud = baud;
capture_result.duration_s = duration_s;
capture_result.st_activation_mode = st_activation_mode;
capture_result.st_control_gpio = st_control_gpio;
capture_result.dry_run = dry_run;
capture_result.manifest_csv = make_relpath(manifest_csv_out, repo_dir);
capture_result.summary_txt = make_relpath(summary_txt_out, repo_dir);
capture_result.final_decision = "not_started";
capture_result.st_off_run_file = "";
capture_result.st_on_run_file = "";
capture_result.st_off_command_ok = false;
capture_result.st_on_command_ok = false;
capture_result.st_restore_off_ok = false;

if dry_run
    [st_off_latest, st_on_latest] = find_latest_st_pair(raw_dir, sensor_id);
    capture_result.st_off_run_file = st_off_latest;
    capture_result.st_on_run_file = st_on_latest;

    if strlength(st_off_latest) > 0 && strlength(st_on_latest) > 0
        manifest_tbl = table(["st_off";"st_on"], [st_off_latest; st_on_latest], ...
            'VariableNames', {'label','run_file'});
        writetable(manifest_tbl, manifest_csv_out);
        capture_result.final_decision = "dry_run_ready_with_existing_pair";
    else
        capture_result.manifest_csv = "not_generated";
        capture_result.final_decision = "dry_run_no_existing_pair";
    end

    write_summary(summary_txt_out, capture_result, repo_dir);

    fprintf("\nSELFTEST_CAPTURE_DRY_RUN_OK\n");
    fprintf("FINAL_DECISION: %s\n", capture_result.final_decision);
    fprintf("SUMMARY_TXT: %s\n", capture_result.summary_txt);
    fprintf("MANIFEST_CSV: %s\n", capture_result.manifest_csv);
    return;
end

if st_activation_mode == "firmware_controlled"
    fprintf("\n[FASE11.1] Ruta firmware-controlled ST en GPIO%d.\n", st_control_gpio);
    fprintf("[FASE11.1] Requiere cable ST pad lateral -> GPIO%d y firmware actualizado.\n", st_control_gpio);

    [ok_off, ack_off, status_off] = issue_st_command(port, baud, "ST_OFF", false);
    capture_result.st_off_command_ok = ok_off;
    capture_result.st_off_ack = ack_off;
    capture_result.st_off_status = status_off;
    if ~ok_off
        error("No se confirmo ST_OFF por firmware. Verifique cableado ST pad lateral y firmware con comandos ST.");
    end

    pause(max(0, st_settle_pause_s));
    st_off_run_file = capture_pose_run(script_dir, sensor_id, port, baud, duration_s, "st_off");

    [ok_on, ack_on, status_on] = issue_st_command(port, baud, "ST_ON", true);
    capture_result.st_on_command_ok = ok_on;
    capture_result.st_on_ack = ack_on;
    capture_result.st_on_status = status_on;
    if ~ok_on
        error("No se confirmo ST_ON por firmware. Verifique GPIO23 y comando ST_ON.");
    end

    pause(max(0, st_settle_pause_s));
    st_on_run_file = capture_pose_run(script_dir, sensor_id, port, baud, duration_s, "st_on");

    % Restaurar ST_OFF al finalizar (seguridad)
    [ok_restore, ack_restore, status_restore] = issue_st_command(port, baud, "ST_OFF", false);
    capture_result.st_restore_off_ok = ok_restore;
    capture_result.st_restore_ack = ack_restore;
    capture_result.st_restore_status = status_restore;
else
    fprintf("\n[FASE11.1] Ruta manual-assisted ST.\n");
    fprintf("[FASE11.1] Mantenga orientacion fija en todo el par.\n");
    fprintf("[FASE11.1] Configure ST en OFF (pad lateral desconectado o GND segun modulo).\n");
    countdown_pause(pre_capture_pause_s);
    st_off_run_file = capture_pose_run(script_dir, sensor_id, port, baud, duration_s, "st_off");

    fprintf("\n[FASE11.1] Active ST manualmente (pad lateral a 3V3) sin mover orientacion.\n");
    countdown_pause(st_transition_pause_s);
    st_on_run_file = capture_pose_run(script_dir, sensor_id, port, baud, duration_s, "st_on");
end

manifest_tbl = table(["st_off";"st_on"], [st_off_run_file; st_on_run_file], ...
    'VariableNames', {'label','run_file'});
writetable(manifest_tbl, manifest_csv_out);

capture_result.st_off_run_file = st_off_run_file;
capture_result.st_on_run_file = st_on_run_file;
capture_result.final_decision = "selftest_pair_captured";

write_summary(summary_txt_out, capture_result, repo_dir);

fprintf("\nSELFTEST_CAPTURE_PAIR_OK\n");
fprintf("MODE: %s\n", st_activation_mode);
fprintf("ST_OFF_RUN: %s\n", st_off_run_file);
fprintf("ST_ON_RUN: %s\n", st_on_run_file);
fprintf("MANIFEST_CSV: %s\n", capture_result.manifest_csv);
fprintf("SUMMARY_TXT: %s\n", capture_result.summary_txt);

%% Local functions
function run_file = capture_pose_run(script_dir, sensor_id, port, baud, duration_s, pose_label)
sensor_id = string(sensor_id); %#ok<NASGU>
port = string(port); %#ok<NASGU>
baud = double(baud); %#ok<NASGU>
duration_s = double(duration_s); %#ok<NASGU>
pose_label = string(pose_label); %#ok<NASGU>
clear csv_path session_path;
run(fullfile(script_dir, "capture_single_sensor_baseline.m"));
if ~exist("csv_path", "var") || strlength(string(csv_path)) == 0
    error("No se recupero csv_path tras captura pose=%s.", pose_label);
end
run_file = string(get_filename(string(csv_path)));
end

function [ok, ack_line, status_line] = issue_st_command(port, baud, cmd, desired_on)
ok = false;
ack_line = "";
status_line = "";

s = serialport(port, baud, "Timeout", 1);
cleanup_serial = onCleanup(@() clear("s")); %#ok<NASGU>
configureTerminator(s, "LF");
flush(s);
pause(0.15);

writeline(s, cmd);
[found_ack, ack_line] = wait_for_ack_line(s, cmd, 2.0);

writeline(s, "STATUS");
[found_status, status_line] = wait_for_status_line(s, desired_on, 2.0);

ok = found_ack || found_status;
end

function [ok, line_out] = wait_for_ack_line(s, cmd, timeout_s)
ok = false;
line_out = "";
needle = "# cmd=" + upper(cmd) + " ack=ok";
t0 = tic;
while toc(t0) <= timeout_s
    if s.NumBytesAvailable == 0
        pause(0.01);
        continue;
    end
    line = strtrim(string(readline(s)));
    if startsWith(line, "#") && contains(line, needle)
        ok = true;
        line_out = line;
        return;
    end
end
end

function [ok, line_out] = wait_for_status_line(s, desired_on, timeout_s)
ok = false;
line_out = "";
if desired_on
    expected = "# status st=ON";
else
    expected = "# status st=OFF";
end

t0 = tic;
while toc(t0) <= timeout_s
    if s.NumBytesAvailable == 0
        pause(0.01);
        continue;
    end
    line = strtrim(string(readline(s)));
    if startsWith(line, "#") && contains(line, expected)
        ok = true;
        line_out = line;
        return;
    end
end
end

function write_summary(summary_txt_out, result, repo_dir)
fid = fopen(summary_txt_out, "w");
if fid < 0
    error("No fue posible crear resumen de captura ST: %s", summary_txt_out);
end
cleanup_fid = onCleanup(@() fclose(fid));

fprintf(fid, "script: matlab/calibration/capture_sensorC_selftest_pair.m\n");
fprintf(fid, "sensor_id: %s\n", result.sensor_id);
if strlength(string(result.requested_port)) == 0
    fprintf(fid, "requested_port: (auto)\n");
else
    fprintf(fid, "requested_port: %s\n", result.requested_port);
end
fprintf(fid, "port: %s\n", result.port);
fprintf(fid, "port_resolution_mode: %s\n", result.port_resolution_mode);
fprintf(fid, "port_resolution_detail: %s\n", result.port_resolution_detail);
fprintf(fid, "baud: %d\n", result.baud);
fprintf(fid, "duration_s: %.3f\n", result.duration_s);
fprintf(fid, "st_activation_mode: %s\n", result.st_activation_mode);
fprintf(fid, "st_control_gpio: %d\n", result.st_control_gpio);
fprintf(fid, "dry_run: %s\n", string(result.dry_run));
fprintf(fid, "final_decision: %s\n", result.final_decision);
fprintf(fid, "st_off_run_file: %s\n", result.st_off_run_file);
fprintf(fid, "st_on_run_file: %s\n", result.st_on_run_file);
fprintf(fid, "st_off_command_ok: %s\n", string(result.st_off_command_ok));
fprintf(fid, "st_on_command_ok: %s\n", string(result.st_on_command_ok));
fprintf(fid, "st_restore_off_ok: %s\n", string(result.st_restore_off_ok));
if isfield(result, "st_off_ack")
    fprintf(fid, "st_off_ack: %s\n", result.st_off_ack);
end
if isfield(result, "st_on_ack")
    fprintf(fid, "st_on_ack: %s\n", result.st_on_ack);
end
if isfield(result, "st_restore_ack")
    fprintf(fid, "st_restore_ack: %s\n", result.st_restore_ack);
end
fprintf(fid, "manifest_csv: %s\n", result.manifest_csv);
fprintf(fid, "summary_txt: %s\n", make_relpath(summary_txt_out, repo_dir));
fprintf(fid, "pinout_map: VCC->3V3,GND->GND,X->GPIO32,Y->GPIO33,Z->GPIO34,ST->GPIO23\n");
end

function [st_off_latest, st_on_latest] = find_latest_st_pair(raw_dir, sensor_id)
st_off_latest = find_latest_by_patterns(raw_dir, [sensor_id + "_st_off_*.csv", sensor_id + "_selftest_off_*.csv"]);
st_on_latest = find_latest_by_patterns(raw_dir, [sensor_id + "_st_on_*.csv", sensor_id + "_selftest_on_*.csv"]);
end

function latest = find_latest_by_patterns(base_dir, patterns)
latest = "";
best_time = -inf;
for p = 1:numel(patterns)
    listing = dir(fullfile(base_dir, char(patterns(p))));
    for i = 1:numel(listing)
        if listing(i).datenum > best_time
            best_time = listing(i).datenum;
            latest = string(listing(i).name);
        end
    end
end
end

function countdown_pause(sec)
sec = max(0, round(double(sec)));
for k = sec:-1:1
    fprintf("  ...%d\n", k);
    pause(1);
end
end

function name = get_filename(abs_path)
[~, n, e] = fileparts(char(abs_path));
name = string(strcat(n, e));
end

function rel = make_relpath(abs_path, repo_dir)
rel = strrep(abs_path, [repo_dir filesep], "");
end
