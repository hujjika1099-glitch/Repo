function cvm = coupled_cross_validate_lambda(lambda, runs_tbl, expected_pose_order)
runs_sorted = sortrows(runs_tbl, {'pose','run_file'}, {'ascend','ascend'});
runs_sorted.fold_idx = zeros(height(runs_sorted),1);

pose_set = unique(runs_sorted.pose, 'stable');
min_runs = inf;
for i = 1:numel(pose_set)
    idx = find(runs_sorted.pose == pose_set(i));
    n = numel(idx);
    min_runs = min(min_runs, n);
    runs_sorted.fold_idx(idx) = (1:n)';
end

n_folds = min_runs;
if n_folds < 2
    error("No hay suficientes corridas por pose para CV.");
end

fold_mean_err = zeros(n_folds,1);
fold_max_err = zeros(n_folds,1);
fold_expected_axis = zeros(n_folds,1);
fold_cross_axis = zeros(n_folds,1);
fold_pair_axis = zeros(n_folds,1);
fold_pair_sign = zeros(n_folds,1);
fold_pair_dom = zeros(n_folds,1);
fold_worst_pair_dom = zeros(n_folds,1);
fold_exact_pose = zeros(n_folds,1);

for f = 1:n_folds
    train_tbl = runs_sorted(runs_sorted.fold_idx ~= f, :);
    test_tbl = runs_sorted(runs_sorted.fold_idx == f, :);

    X_train = [train_tbl.mean_mv_x, train_tbl.mean_mv_y, train_tbl.mean_mv_z, ones(height(train_tbl),1)];
    Y_train = [train_tbl.target_gx, train_tbl.target_gy, train_tbl.target_gz];
    [A_mv, c_mv] = coupled_fit_ridge(X_train, Y_train, lambda);

    eval_fold = coupled_eval_model(A_mv, c_mv, test_tbl, expected_pose_order);
    fold_mean_err(f) = eval_fold.metrics.global_mean_abs_gnorm_err;
    fold_max_err(f) = eval_fold.metrics.global_max_abs_gnorm_err;
    fold_expected_axis(f) = eval_fold.metrics.mean_expected_axis;
    fold_cross_axis(f) = eval_fold.metrics.mean_cross_axis_abs;
    fold_pair_axis(f) = eval_fold.metrics.pair_axis_match_count;
    fold_pair_sign(f) = eval_fold.metrics.pair_sign_opposition_count;
    fold_pair_dom(f) = eval_fold.metrics.avg_pair_dominance_ratio;
    fold_worst_pair_dom(f) = eval_fold.metrics.worst_pair_dominance_ratio;
    fold_exact_pose(f) = eval_fold.metrics.exact_pose_count;
end

cvm = struct();
cvm.cv_n_folds = n_folds;
cvm.cv_mean_abs_gnorm_err = mean(fold_mean_err);
cvm.cv_max_abs_gnorm_err = max(fold_max_err);
cvm.cv_expected_axis_mean = mean(fold_expected_axis);
cvm.cv_cross_axis_abs_mean = mean(fold_cross_axis);
cvm.cv_pair_axis_match_count = mean(fold_pair_axis);
cvm.cv_pair_sign_opposition_count = mean(fold_pair_sign);
cvm.cv_avg_pair_dominance_ratio = mean(fold_pair_dom);
cvm.cv_worst_pair_dominance_ratio = min(fold_worst_pair_dom);
cvm.cv_exact_pose_match_count = mean(fold_exact_pose);
end
