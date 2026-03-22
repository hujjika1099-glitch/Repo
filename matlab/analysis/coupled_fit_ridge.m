function [A_mv, c_mv] = coupled_fit_ridge(X, Y, lambda)
R = diag([1, 1, 1, 0]);
lhs = (X' * X) + lambda * R;
rhs = X' * Y;
if lambda == 0
    B = X \ Y;
else
    if rcond(lhs) > 1e-12
        B = lhs \ rhs;
    else
        B = pinv(lhs) * rhs;
    end
end
A_mv = B(1:3, :)';
c_mv = B(4, :)';
end
