function [g_xyz, g_norm, info] = estimate_sensorB_accel_g(mv_xyz, varargin)
% estimate_sensorB_accel_g
% Estimacion base de aceleracion para sensor_B en modo live.
%
% Rutas soportadas:
% - nominal_quick_g (default)
% - provisional_sensorB_g

p = inputParser;
p.addRequired("mv_xyz", @(x) isnumeric(x) && size(x,2) == 3);
p.addParameter("mode", "nominal_quick_g", @(x) isstring(x) || ischar(x));
p.addParameter("bias_mv", [], @(x) isempty(x) || (isnumeric(x) && numel(x) == 3));
p.addParameter("bias_init_samples", 200, @(x) isnumeric(x) && isscalar(x) && x >= 1);
p.addParameter("nominal_sens_mv_per_g", 300, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter("sensorB_sens_mv_per_g", [300 300 300], @(x) isnumeric(x) && numel(x) == 3);
p.parse(mv_xyz, varargin{:});

cfg = p.Results;
mode = lower(string(cfg.mode));
mv_xyz = double(mv_xyz);

n = size(mv_xyz, 1);
if isempty(cfg.bias_mv)
    n_bias = min(n, max(1, round(double(cfg.bias_init_samples))));
    bias_mv = mean(mv_xyz(1:n_bias, :), 1);
else
    bias_mv = reshape(double(cfg.bias_mv), 1, 3);
end

switch mode
    case "nominal_quick_g"
        sens = [cfg.nominal_sens_mv_per_g cfg.nominal_sens_mv_per_g cfg.nominal_sens_mv_per_g];
        g_xyz = (mv_xyz - bias_mv) ./ sens;
        route = "nominal_quick_g";

    case "provisional_sensorb_g"
        sens = reshape(double(cfg.sensorB_sens_mv_per_g), 1, 3);
        g_xyz = (mv_xyz - bias_mv) ./ sens;
        route = "provisional_sensorB_g";

    otherwise
        error("Modo no soportado para estimate_sensorB_accel_g: %s", mode);
end

g_norm = sqrt(sum(g_xyz.^2, 2));

info = struct();
info.route = route;
info.bias_mv = bias_mv;
info.sens_mv_per_g = sens;
info.samples_used_for_bias = min(n, max(1, round(double(cfg.bias_init_samples))));
end
