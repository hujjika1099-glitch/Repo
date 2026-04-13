function parsed = parse_adxl335_stream_line(line)
% parse_adxl335_stream_line
% Parser comun para stream ADXL335 (serial directo o relay ESP-NOW).
%
% Formatos de data soportados:
% - seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z
% - sensor_id,seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z

parsed = struct();
parsed.kind = "invalid";          % data | header | metadata | empty | invalid
parsed.values = [];
parsed.text = "";

if nargin < 1
    parsed.kind = "empty";
    return;
end

line = string(line);
if isempty(line)
    parsed.kind = "empty";
    return;
end

if numel(line) > 1
    line = join(line, "");
end

if ismissing(line)
    parsed.kind = "empty";
    return;
end

line = string(strtrim(line));
parsed.text = line;

if strlength(line) == 0
    parsed.kind = "empty";
    return;
end

if startsWith(line, "#")
    parsed.kind = "metadata";
    return;
end

if ismember(line, [ ...
        "seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z", ...
        "sensor_id,seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z"])
    parsed.kind = "header";
    return;
end

tokens = split(line, ",");
if numel(tokens) ~= 8 && numel(tokens) ~= 9
    parsed.kind = "invalid";
    return;
end

vals = str2double(tokens);
if any(isnan(vals))
    parsed.kind = "invalid";
    return;
end

if numel(vals) == 8
    vals = [1 vals];
end

parsed.kind = "data";
parsed.values = vals(:).';
end
