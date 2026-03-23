function parsed = parse_adxl335_stream_line(line)
% parse_adxl335_stream_line
% Parser comun para stream ADXL335 (serial directo o relay ESP-NOW).
%
% Formato de data esperado:
% seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z

parsed = struct();
parsed.kind = "invalid";          % data | header | metadata | empty | invalid
parsed.values = [];
parsed.text = "";

if nargin < 1
    parsed.kind = "empty";
    return;
end

line = string(strtrim(string(line)));
parsed.text = line;

if strlength(line) == 0
    parsed.kind = "empty";
    return;
end

if startsWith(line, "#")
    parsed.kind = "metadata";
    return;
end

if line == "seq,t_us,raw_x,raw_y,raw_z,mv_x,mv_y,mv_z"
    parsed.kind = "header";
    return;
end

tokens = split(line, ",");
if numel(tokens) ~= 8
    parsed.kind = "invalid";
    return;
end

vals = str2double(tokens);
if any(isnan(vals))
    parsed.kind = "invalid";
    return;
end

parsed.kind = "data";
parsed.values = vals(:).';
end
