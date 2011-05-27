function [y, v] = hmax_linclass_test(c, x)

% [Y, V] = hmax_linclass_test(C, X) classifies vectors using a linear
% classifier returned by hmax_linclass_train.
%
%    C - the classifier returned by hmax_linclass_train.
%
%    X - a matrix of column vectors for testing.
%
%    Y - The predicted category numbers (1-n), one per test vector.
%
%    V - The raw classifier outputs.  This will be an AxB matrix where A is the
%    number of categories and B is the number of test vectors.  (Exception: for
%    2-category classification, A will be 1, and only the output for class 1 is
%    returned.  The output for class 2 can be assumed to be its negation.)
%
% See also: hmax_linclass_train.

%-----------------------------------------------------------------------------------------------------------------------

% Normalize the vectors and set any "unknown" feature values to the feature mean.
for i = 1 : size(x, 1)
    x(i, x(i, :) == cns_fltmin) = c.fMeans(i);
    x(i, :) = (x(i, :) - c.fMeans(i)) / c.fStds(i);
end

% Now classify the vectors.
siz = size(x);
siz(1) = size(c.w, 1);
v = double(reshape(bsxfun(@plus, c.w * x(:, :), c.b), siz));
if size(v, 1) == 1
    y = 2 - (v >= 0);
else
    [ans, y] = max(v, [], 1);
end

return;