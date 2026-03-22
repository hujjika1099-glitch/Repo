function eval_out = coupled_eval_model(A_mv, c_mv, runs_tbl, expected_pose_order)
n = height(runs_tbl);

g = zeros(n, 3);
mean_gnorm = zeros(n, 1);
mean_error_gnorm = zeros(n, 1);
expected_axis_mean = zeros(n, 1);
cross_axis_abs_mean = zeros(n, 1);
dominant_axis = strings(n, 1);
dominant_sign = zeros(n, 1);
axis_match = false(n, 1);
sign_match = false(n, 1);
exact_match = false(n, 1);

for i = 1:n
    v = [runs_tbl.mean_mv_x(i); runs_tbl.mean_mv_y(i); runs_tbl.mean_mv_z(i)];
    gi = A_mv * v + c_mv;
    g(i, :) = gi(:)';
    mean_gnorm(i) = norm(gi);
    mean_error_gnorm(i) = abs(mean_gnorm(i) - 1.0);

    [exp_axis, exp_sign] = coupled_expected_from_pose(runs_tbl.pose(i));
    exp_idx = coupled_axis_to_index(exp_axis);
    cross_idx = setdiff(1:3, exp_idx);
    expected_axis_mean(i) = gi(exp_idx) * exp_sign;
    cross_axis_abs_mean(i) = mean(abs(gi(cross_idx)));

    [~, dom_idx] = max(abs(gi));
    dom_axes = ["x", "y", "z"];
    dominant_axis(i) = dom_axes(dom_idx);
    dominant_sign(i) = sign(gi(dom_idx));
    axis_match(i) = (dom_idx == exp_idx);
    sign_match(i) = (sign(gi(exp_idx)) == exp_sign) && (abs(gi(exp_idx)) >= 0.20);
    exact_match(i) = axis_match(i) && sign_match(i);
end

runs_eval = table( ...
    runs_tbl.pose, runs_tbl.run_file, runs_tbl.samples, runs_tbl.duration_s, runs_tbl.freq_hz, runs_tbl.seq_jumps, ...
    runs_tbl.mean_mv_x, runs_tbl.mean_mv_y, runs_tbl.mean_mv_z, ...
    g(:,1), g(:,2), g(:,3), ...
    mean_gnorm, mean_error_gnorm, mean_error_gnorm, ...
    expected_axis_mean, cross_axis_abs_mean, ...
    dominant_axis, dominant_sign, axis_match, sign_match, exact_match, ...
    'VariableNames', { ...
    'pose','run_file','samples','duration_s','freq_hz','seq_jumps', ...
    'mean_mv_x','mean_mv_y','mean_mv_z', ...
    'mean_gx','mean_gy','mean_gz', ...
    'mean_gnorm','mean_error_gnorm','max_error_gnorm', ...
    'expected_axis_mean','cross_axis_abs_mean', ...
    'dominant_axis','dominant_sign','axis_match','sign_match','exact_match'});

pose_name = string(expected_pose_order(:));
n_pose = numel(pose_name);
runs_found = zeros(n_pose,1);
seq_jumps_total = zeros(n_pose,1);
freq_mean_hz = zeros(n_pose,1);
mean_gx = zeros(n_pose,1);
mean_gy = zeros(n_pose,1);
mean_gz = zeros(n_pose,1);
mean_gnorm_p = zeros(n_pose,1);
mean_err_p = zeros(n_pose,1);
max_err_p = zeros(n_pose,1);
mean_expected_axis_p = zeros(n_pose,1);
mean_cross_axis_p = zeros(n_pose,1);
dominant_axis_p = strings(n_pose,1);
dominant_sign_p = zeros(n_pose,1);
axis_match_p = false(n_pose,1);
sign_match_p = false(n_pose,1);
exact_match_p = false(n_pose,1);

for i = 1:n_pose
    p = pose_name(i);
    s = runs_eval(runs_eval.pose == p, :);
    runs_found(i) = height(s);
    seq_jumps_total(i) = sum(s.seq_jumps);
    freq_mean_hz(i) = mean(s.freq_hz);
    mean_gx(i) = mean(s.mean_gx);
    mean_gy(i) = mean(s.mean_gy);
    mean_gz(i) = mean(s.mean_gz);
    mean_gnorm_p(i) = mean(s.mean_gnorm);
    mean_err_p(i) = mean(s.mean_error_gnorm);
    max_err_p(i) = max(s.max_error_gnorm);
    mean_expected_axis_p(i) = mean(s.expected_axis_mean);
    mean_cross_axis_p(i) = mean(s.cross_axis_abs_mean);

    [exp_axis, exp_sign] = coupled_expected_from_pose(p);
    exp_idx = coupled_axis_to_index(exp_axis);
    gp = [mean_gx(i), mean_gy(i), mean_gz(i)];
    [~, dom_idx] = max(abs(gp));
    dom_axes = ["x", "y", "z"];
    dominant_axis_p(i) = dom_axes(dom_idx);
    dominant_sign_p(i) = sign(gp(dom_idx));
    axis_match_p(i) = (dom_idx == exp_idx);
    sign_match_p(i) = (sign(gp(exp_idx)) == exp_sign) && (abs(gp(exp_idx)) >= 0.20);
    exact_match_p(i) = axis_match_p(i) && sign_match_p(i);
end

poses_eval = table( ...
    pose_name, runs_found, seq_jumps_total, freq_mean_hz, ...
    mean_gx, mean_gy, mean_gz, ...
    mean_gnorm_p, mean_err_p, max_err_p, ...
    mean_expected_axis_p, mean_cross_axis_p, ...
    dominant_axis_p, dominant_sign_p, ...
    axis_match_p, sign_match_p, exact_match_p, ...
    'VariableNames', { ...
    'pose','runs_found','seq_jumps_total','freq_mean_hz', ...
    'mean_gx','mean_gy','mean_gz', ...
    'mean_gnorm','mean_error_gnorm','max_error_gnorm', ...
    'mean_expected_axis','mean_cross_axis_abs', ...
    'dominant_axis','dominant_sign','axis_match','sign_match','exact_match'});

pairs_eval = local_build_pairs(poses_eval);

metrics = struct();
metrics.global_mean_abs_gnorm_err = mean(runs_eval.mean_error_gnorm);
metrics.global_max_abs_gnorm_err = max(runs_eval.max_error_gnorm);
metrics.mean_expected_axis = mean(runs_eval.expected_axis_mean);
metrics.mean_cross_axis_abs = mean(runs_eval.cross_axis_abs_mean);
metrics.pose_axis_match_count = sum(poses_eval.axis_match);
metrics.pose_sign_match_count = sum(poses_eval.sign_match);
metrics.exact_pose_match_count = sum(poses_eval.exact_match);
metrics.pair_axis_match_count = sum(pairs_eval.pair_axis_match);
metrics.pair_sign_opposition_count = sum(pairs_eval.pair_sign_opposition_ok);
metrics.avg_pair_dominance_ratio = mean(pairs_eval.pair_dominance_ratio);
metrics.worst_pair_dominance_ratio = min(pairs_eval.pair_dominance_ratio);
metrics.seq_jumps_total = sum(runs_eval.seq_jumps);
metrics.exact_pose_count = sum(poses_eval.exact_match);

eval_out = struct( ...
    "runs_tbl", runs_eval, ...
    "poses_tbl", poses_eval, ...
    "pairs_tbl", pairs_eval, ...
    "metrics", metrics);
end

function pairs_tbl = local_build_pairs(poses_tbl)
pair_name = ["x_pair","y_pair","z_pair"]';
expected_pair_axis = ["x","y","z"]';
delta_gx_pair = zeros(3,1);
delta_gy_pair = zeros(3,1);
delta_gz_pair = zeros(3,1);
dominant_pair_axis = strings(3,1);
pair_axis_match = false(3,1);
pair_sign_opposition_ok = false(3,1);
pair_expected_delta_abs = zeros(3,1);
pair_cross_delta_abs_max = zeros(3,1);
pair_dominance_ratio = zeros(3,1);

for i = 1:3
    ax = expected_pair_axis(i);
    pos_idx = poses_tbl.pose == ("pos_" + ax);
    neg_idx = poses_tbl.pose == ("neg_" + ax);
    gpos = [poses_tbl.mean_gx(pos_idx), poses_tbl.mean_gy(pos_idx), poses_tbl.mean_gz(pos_idx)];
    gneg = [poses_tbl.mean_gx(neg_idx), poses_tbl.mean_gy(neg_idx), poses_tbl.mean_gz(neg_idx)];
    d = gpos - gneg;

    delta_gx_pair(i) = d(1);
    delta_gy_pair(i) = d(2);
    delta_gz_pair(i) = d(3);

    [~, dom_idx] = max(abs(d));
    dom_axes = ["x","y","z"];
    dominant_pair_axis(i) = dom_axes(dom_idx);
    expected_idx = coupled_axis_to_index(ax);
    cross_idx = setdiff(1:3, expected_idx);
    pair_axis_match(i) = (dom_idx == expected_idx);
    pair_expected_delta_abs(i) = abs(d(expected_idx));
    pair_cross_delta_abs_max(i) = max(abs(d(cross_idx)));
    pair_dominance_ratio(i) = pair_expected_delta_abs(i) / max(pair_cross_delta_abs_max(i), eps);
    pair_sign_opposition_ok(i) = (gpos(expected_idx) >= 0.20) && (gneg(expected_idx) <= -0.20);
end

pairs_tbl = table( ...
    pair_name, expected_pair_axis, ...
    delta_gx_pair, delta_gy_pair, delta_gz_pair, ...
    dominant_pair_axis, pair_axis_match, pair_sign_opposition_ok, ...
    pair_expected_delta_abs, pair_cross_delta_abs_max, pair_dominance_ratio);
end
