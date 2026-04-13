function [resolved_port, info] = resolve_adxl_serial_port(varargin)
% resolve_adxl_serial_port
% Resuelve automaticamente el puerto serial del stream ADXL335 o del relay ESP-NOW.

p = inputParser;
p.addParameter("preferred_port", "", @(x) ischar(x) || isstring(x));
p.addParameter("baud", 115200, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter("probe_timeout_s", 1.6, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter("verbose", false, @(x) islogical(x) || isnumeric(x));
p.parse(varargin{:});

preferred_port = normalize_scalar_string(p.Results.preferred_port);
baud = double(p.Results.baud);
probe_timeout_s = double(p.Results.probe_timeout_s);
verbose = logical(p.Results.verbose);

available_ports = list_available_ports();
inventory = get_windows_serial_inventory();
candidate_ports = build_candidate_list(preferred_port, available_ports, inventory);

if isempty(candidate_ports)
    error([ ...
        "No se detectaron puertos seriales disponibles. " ...
        "Conecte la ESP32 relay USB y cierre monitores seriales externos antes de reintentar."]);
end

probe_results = repmat(empty_probe_result(), numel(candidate_ports), 1);
inventory_scores = zeros(numel(candidate_ports), 1);
inventory_labels = strings(numel(candidate_ports), 1);

for k = 1:numel(candidate_ports)
    port_k = candidate_ports(k);
    inv_k = find_inventory_entry(inventory, port_k);
    [inventory_scores(k), inventory_labels(k)] = score_inventory_entry(inv_k);
    probe_results(k) = probe_serial_candidate(port_k, baud, probe_timeout_s);
end

[resolved_port, selection_mode, selection_detail] = select_candidate( ...
    candidate_ports, probe_results, inventory_scores, inventory_labels, preferred_port, available_ports);

info = struct();
info.preferred_port = preferred_port;
info.available_ports = available_ports;
info.candidate_ports = candidate_ports;
info.inventory = inventory;
info.inventory_scores = inventory_scores;
info.inventory_labels = inventory_labels;
info.probe_results = probe_results;
info.selection_mode = selection_mode;
info.selection_detail = selection_detail;

if verbose
    fprintf("PORT_RESOLUTION_MODE: %s\n", selection_mode);
    fprintf("PORT_RESOLUTION_DETAIL: %s\n", selection_detail);
    fprintf("PORT_AVAILABLE: %s\n", join_or_none(available_ports));
    fprintf("PORT_CANDIDATES: %s\n", join_or_none(candidate_ports));
    fprintf("PORT_SELECTED: %s\n", resolved_port);
end
end

function result = empty_probe_result()
result = struct( ...
    "port", "", ...
    "open_ok", false, ...
    "match_kind", "none", ...
    "lines", strings(0, 1), ...
    "probe_error", "");
end

function out = normalize_scalar_string(in)
tmp = string(in);
if isempty(tmp) || all(ismissing(tmp))
    out = "";
else
    out = strtrim(tmp(1));
end
end

function ports = list_available_ports()
ports = strings(0, 1);

try
    raw = serialportlist("available");
catch
    try
        raw = serialportlist;
    catch
        raw = [];
    end
end

if isempty(raw)
    return;
end

ports = unique_preserve_order(string(raw(:)));
ports = ports(strlength(ports) > 0);
end

function inventory = get_windows_serial_inventory()
inventory = struct("DeviceID", {}, "Name", {}, "Description", {}, "PNPDeviceID", {});

if ~ispc
    return;
end

cmd = ['powershell -NoProfile -ExecutionPolicy Bypass -Command "' ...
    '[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; ' ...
    '$ports = Get-CimInstance Win32_SerialPort | ' ...
    'Select-Object DeviceID,Name,Description,PNPDeviceID; ' ...
    'if ($null -eq $ports) { '''' } else { $ports | ConvertTo-Json -Compress }"'];

try
    [status, raw] = system(cmd);
catch
    status = 1;
    raw = "";
end

if status ~= 0
    return;
end

raw = strtrim(string(raw));
if strlength(raw) == 0
    return;
end

try
    decoded = jsondecode(char(raw));
catch
    return;
end

if isstruct(decoded)
    inventory = decoded;
else
    inventory = struct("DeviceID", {}, "Name", {}, "Description", {}, "PNPDeviceID", {});
end
end

function ports = build_candidate_list(preferred_port, available_ports, inventory)
ports = strings(0, 1);

if strlength(preferred_port) > 0
    ports(end+1, 1) = preferred_port; %#ok<AGROW>
end

if ~isempty(inventory)
    for k = 1:numel(inventory)
        port_k = normalize_scalar_string(inventory(k).DeviceID);
        if strlength(port_k) > 0
            ports(end+1, 1) = port_k; %#ok<AGROW>
        end
    end
end

ports = [ports; available_ports(:)];
ports = unique_preserve_order(ports);
ports = ports(strlength(ports) > 0);
end

function inv = find_inventory_entry(inventory, port)
inv = struct("DeviceID", "", "Name", "", "Description", "", "PNPDeviceID", "");

if isempty(inventory) || strlength(port) == 0
    return;
end

for k = 1:numel(inventory)
    if normalize_scalar_string(inventory(k).DeviceID) == port
        inv = inventory(k);
        return;
    end
end
end

function [score, label] = score_inventory_entry(inv)
parts = [
    normalize_scalar_string(inv.DeviceID)
    normalize_scalar_string(inv.Name)
    normalize_scalar_string(inv.Description)
    normalize_scalar_string(inv.PNPDeviceID)
    ];
text = lower(strjoin(parts(parts ~= ""), " | "));

score = 0;
tags = strings(0, 1);

if strlength(text) == 0
    label = "sin_inventario";
    return;
end

if contains(text, "bluetooth") || contains(text, "bthenum")
    score = score - 100;
    tags(end+1, 1) = "bluetooth"; %#ok<AGROW>
end
if contains(text, "cp210") || contains(text, "silicon labs")
    score = score + 80;
    tags(end+1, 1) = "cp210"; %#ok<AGROW>
end
if contains(text, "usb serial") || contains(text, "usb-to-uart") || contains(text, "usb to uart")
    score = score + 60;
    tags(end+1, 1) = "usb_serial"; %#ok<AGROW>
end
if contains(text, "wch") || contains(text, "ch340")
    score = score + 55;
    tags(end+1, 1) = "ch340"; %#ok<AGROW>
end
if contains(text, "ftdi")
    score = score + 55;
    tags(end+1, 1) = "ftdi"; %#ok<AGROW>
end
if contains(text, "uart")
    score = score + 40;
    tags(end+1, 1) = "uart"; %#ok<AGROW>
end
if contains(text, "esp32") || contains(text, "jtag")
    score = score + 35;
    tags(end+1, 1) = "esp32"; %#ok<AGROW>
end

if isempty(tags)
    label = "generico";
else
    label = strjoin(unique_preserve_order(tags), "+");
end
end

function result = probe_serial_candidate(port, baud, probe_timeout_s)
result = empty_probe_result();
result.port = port;

if strlength(port) == 0
    result.probe_error = "port_empty";
    return;
end

try
    s = serialport(char(port), baud, "Timeout", 0.25); %#ok<NASGU>
    cleanup_serial = onCleanup(@() clear("s")); %#ok<NASGU>
    result.open_ok = true;
    configureTerminator(s, "LF");
    flush(s);
    pause(0.15);

    saw_header = false;
    saw_data = false;
    saw_relay = false;
    saw_status = false;
    lines = strings(0, 1);

    t0 = tic;
    while toc(t0) <= probe_timeout_s
        if s.NumBytesAvailable == 0
            pause(0.02);
            continue;
        end

        line = strtrim(string(readline(s)));
        if strlength(line) == 0
            continue;
        end

        lines(end+1, 1) = line; %#ok<AGROW>

        if line == "seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z" || ...
                line == "sensor_id,seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z"
            saw_header = true;
        elseif startsWith(line, "# relay=espnow_receiver")
            saw_relay = true;
        elseif startsWith(line, "#STAT,relay=receiver")
            saw_status = true;
        elseif ~startsWith(line, "#")
            tokens = split(line, ",");
            if numel(tokens) == 8 || numel(tokens) == 9
                vals = str2double(tokens);
                if ~any(isnan(vals))
                    saw_data = true;
                end
            end
        end

        if saw_relay || saw_status || saw_header || saw_data
            break;
        end
    end

    result.lines = lines;
    if saw_relay || saw_status
        result.match_kind = "relay_stream";
    elseif saw_header || saw_data
        result.match_kind = "adxl_stream";
    else
        result.match_kind = "open_no_signature";
    end
catch ME
    result.probe_error = string(ME.message);
end
end

function [resolved_port, selection_mode, selection_detail] = select_candidate(candidate_ports, probe_results, inventory_scores, inventory_labels, preferred_port, available_ports)
resolved_port = "";
selection_mode = "";
selection_detail = "";

relay_idx = find(arrayfun(@(r) r.match_kind == "relay_stream", probe_results));
if numel(relay_idx) == 1
    idx = relay_idx(1);
    resolved_port = candidate_ports(idx);
    selection_mode = "relay_signature";
    selection_detail = "relay ESP-NOW identificado por stream serial";
    return;
elseif numel(relay_idx) > 1
    [resolved_port, selection_mode, selection_detail] = try_disambiguate( ...
        candidate_ports, relay_idx, inventory_scores, inventory_labels, preferred_port, "relay_signature_multi");
    if strlength(resolved_port) > 0
        return;
    end
    error(build_ambiguity_error(candidate_ports(relay_idx), inventory_labels(relay_idx), "Se detectaron multiples relays seriales compatibles."));
end

stream_idx = find(arrayfun(@(r) r.match_kind == "adxl_stream", probe_results));
if numel(stream_idx) == 1
    idx = stream_idx(1);
    resolved_port = candidate_ports(idx);
    selection_mode = "stream_signature";
    selection_detail = "stream ADXL335 identificado por header/data CSV";
    return;
elseif numel(stream_idx) > 1
    [resolved_port, selection_mode, selection_detail] = try_disambiguate( ...
        candidate_ports, stream_idx, inventory_scores, inventory_labels, preferred_port, "stream_signature_multi");
    if strlength(resolved_port) > 0
        return;
    end
    error(build_ambiguity_error(candidate_ports(stream_idx), inventory_labels(stream_idx), "Se detectaron multiples streams seriales ADXL335 compatibles."));
end

positive_inventory_idx = find(inventory_scores > 0 & ismember(candidate_ports, available_ports));
if numel(positive_inventory_idx) == 1
    idx = positive_inventory_idx(1);
    resolved_port = candidate_ports(idx);
    selection_mode = "inventory_score";
    selection_detail = "seleccionado por inventario del SO (USB-UART priorizado)";
    return;
elseif numel(positive_inventory_idx) > 1
    [resolved_port, selection_mode, selection_detail] = try_disambiguate( ...
        candidate_ports, positive_inventory_idx, inventory_scores, inventory_labels, preferred_port, "inventory_score_multi");
    if strlength(resolved_port) > 0
        return;
    end
    error(build_ambiguity_error(candidate_ports(positive_inventory_idx), inventory_labels(positive_inventory_idx), ...
        "Hay varios puertos USB-UART candidatos y ninguno emitio una firma unica del relay."));
end

available_idx = find(ismember(candidate_ports, available_ports));
if numel(available_idx) == 1
    idx = available_idx(1);
    resolved_port = candidate_ports(idx);
    selection_mode = "single_available";
    selection_detail = "solo existe un puerto serial disponible";
    return;
end

if strlength(preferred_port) > 0 && any(candidate_ports == preferred_port) && any(available_ports == preferred_port)
    resolved_port = preferred_port;
    selection_mode = "preferred_fallback";
    selection_detail = "se conserva puerto preferido al no haber firma concluyente";
    return;
end

error(build_no_match_error(candidate_ports, inventory_labels, probe_results));
end

function [resolved_port, selection_mode, selection_detail] = try_disambiguate(candidate_ports, idx_list, inventory_scores, inventory_labels, preferred_port, base_mode)
resolved_port = "";
selection_mode = "";
selection_detail = "";

if strlength(preferred_port) > 0
    preferred_hits = idx_list(candidate_ports(idx_list) == preferred_port);
    if numel(preferred_hits) == 1
        resolved_port = candidate_ports(preferred_hits(1));
        selection_mode = base_mode + "_preferred";
        selection_detail = "desempate por puerto preferido";
        return;
    end
end

scores = inventory_scores(idx_list);
max_score = max(scores);
best_rel = find(scores == max_score);
if numel(best_rel) == 1
    idx = idx_list(best_rel(1));
    if max_score > 0
        resolved_port = candidate_ports(idx);
        selection_mode = base_mode + "_inventory";
        selection_detail = "desempate por prioridad de inventario: " + inventory_labels(idx);
    end
end
end

function msg = build_ambiguity_error(ports, labels, intro)
detail_lines = strings(0, 1);
for k = 1:numel(ports)
    detail_lines(end+1, 1) = " - " + ports(k) + " [" + labels(k) + "]"; %#ok<AGROW>
end
msg = intro + newline + ...
    "Especifique `port=""COMx""` en MATLAB o desconecte los puertos extra antes de reintentar." + newline + ...
    strjoin(detail_lines, newline);
end

function msg = build_no_match_error(candidate_ports, inventory_labels, probe_results)
detail_lines = strings(0, 1);
for k = 1:numel(candidate_ports)
    probe_k = probe_results(k);
    line_hint = "";
    if ~isempty(probe_k.lines)
        line_hint = " first_line=" + probe_k.lines(1);
    elseif strlength(probe_k.probe_error) > 0
        line_hint = " probe_error=" + probe_k.probe_error;
    end
    detail_lines(end+1, 1) = " - " + candidate_ports(k) + " [" + inventory_labels(k) + "]" + line_hint; %#ok<AGROW>
end

msg = [ ...
    "No fue posible identificar automaticamente el puerto del stream ADXL335/relay ESP-NOW." newline ...
    "Verifique que la ESP32 relay USB este conectada, que ningun monitor serial externo tenga el puerto abierto y que el firmware este corriendo." newline ...
    strjoin(detail_lines, newline)];
end

function out = unique_preserve_order(in)
if isempty(in)
    out = strings(0, 1);
    return;
end

in = string(in(:));
[~, idx] = unique(in, "stable");
out = in(sort(idx));
end

function txt = join_or_none(values)
if isempty(values)
    txt = "(none)";
else
    txt = strjoin(values, ", ");
end
end
