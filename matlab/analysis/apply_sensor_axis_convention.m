function [g_oper, detail] = apply_sensor_axis_convention(g_channel, convention_cfg)
% apply_sensor_axis_convention
% Applies explicit channel->chip->operational mapping with signed convention.
%
% Inputs:
%   g_channel      : Nx3 matrix, channel-frame g in [x y z] channel order.
%   convention_cfg : struct from phase11 convention JSON.
%
% Outputs:
%   g_oper : Nx3 matrix, operational frame g in [x y z] order.
%   detail : struct with intermediate transforms.

if ~isnumeric(g_channel) || size(g_channel,2) ~= 3
    error("g_channel debe ser una matriz numerica Nx3 en orden [x y z].");
end
if ~isstruct(convention_cfg)
    error("convention_cfg debe ser struct.");
end

required_top = ["identity", "convention"];
for i = 1:numel(required_top)
    if ~isfield(convention_cfg, required_top(i))
        error("Config incompleta: falta %s.", required_top(i));
    end
end

axis_labels = ["x", "y", "z"];

% channel -> chip (permutation)
if ~isfield(convention_cfg.identity, "channel_to_chip_axis")
    error("Config incompleta: identity.channel_to_chip_axis.");
end
chan_to_chip = convention_cfg.identity.channel_to_chip_axis;

m_chan_to_chip = zeros(3,3);
for c = 1:3
    ch = axis_labels(c);
    if ~isfield(chan_to_chip, ch)
        error("Config incompleta: channel_to_chip_axis.%s.", ch);
    end
    chip_axis = normalize_axis_string(chan_to_chip.(ch));
    chip_idx = axis_to_index(chip_axis);
    m_chan_to_chip(chip_idx, c) = 1;
end

validate_permutation(m_chan_to_chip, "channel_to_chip");

% chip -> operational (signed permutation)
if ~isfield(convention_cfg.convention, "chip_axis_to_operational_axis")
    error("Config incompleta: convention.chip_axis_to_operational_axis.");
end
if ~isfield(convention_cfg.convention, "chip_axis_sign_to_operational")
    error("Config incompleta: convention.chip_axis_sign_to_operational.");
end
chip_to_oper = convention_cfg.convention.chip_axis_to_operational_axis;
chip_sign_to_oper = convention_cfg.convention.chip_axis_sign_to_operational;

m_chip_to_oper = zeros(3,3);
for chip_i = 1:3
    chip_axis = axis_labels(chip_i);

    if ~isfield(chip_to_oper, chip_axis)
        error("Config incompleta: chip_axis_to_operational_axis.%s.", chip_axis);
    end
    if ~isfield(chip_sign_to_oper, chip_axis)
        error("Config incompleta: chip_axis_sign_to_operational.%s.", chip_axis);
    end

    oper_axis = normalize_axis_string(chip_to_oper.(chip_axis));
    oper_idx = axis_to_index(oper_axis);

    sign_val = double(chip_sign_to_oper.(chip_axis));
    if ~(sign_val == 1 || sign_val == -1)
        error("Signo invalido en chip_axis_sign_to_operational.%s (debe ser +/-1).", chip_axis);
    end

    m_chip_to_oper(oper_idx, chip_i) = sign_val;
end

validate_signed_permutation(m_chip_to_oper, "chip_to_operational");

% Transform application on row-wise data
% g_chip = g_channel * m_chan_to_chip'
% g_oper = g_chip * m_chip_to_oper'
g_chip = g_channel * m_chan_to_chip';
g_oper = g_chip * m_chip_to_oper';

detail = struct();
detail.axis_order = axis_labels;
detail.m_channel_to_chip = m_chan_to_chip;
detail.m_chip_to_operational = m_chip_to_oper;
detail.m_channel_to_operational = m_chip_to_oper * m_chan_to_chip;
detail.identity_status = get_optional_string(convention_cfg.identity, "status", "unknown");

end

function idx = axis_to_index(axis_name)
switch axis_name
    case "x"
        idx = 1;
    case "y"
        idx = 2;
    case "z"
        idx = 3;
    otherwise
        error("Eje no soportado: %s", axis_name);
end
end

function out = normalize_axis_string(in)
out = lower(strtrim(string(in)));
if ~ismember(out, ["x", "y", "z"])
    error("Eje invalido en config: %s", out);
end
end

function validate_permutation(m, name)
if any(sum(m,1) ~= 1) || any(sum(m,2) ~= 1)
    error("Matriz %s no es permutacion valida 3x3.", name);
end
end

function validate_signed_permutation(m, name)
if any(sum(abs(m),1) ~= 1) || any(sum(abs(m),2) ~= 1)
    error("Matriz %s no es permutacion con signo valida 3x3.", name);
end
if any(~ismember(nonzeros(m), [-1, 1]))
    error("Matriz %s contiene valores no permitidos (solo -1/1).", name);
end
end

function out = get_optional_string(s, field_name, default_val)
if isfield(s, field_name)
    out = string(s.(field_name));
else
    out = string(default_val);
end
end
