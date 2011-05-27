function c = hmax_linclass_train(x, y)

% C = hmax_linclass_train(X, Y) trains a multiclass one-vs-rest linear
% classifier.  The algorithm used to train the classifier is weighted
% regularized least-squares.  Note that a linear SVM was used in
% [Mutch & Lowe 2006].  RLS is much faster and the training code is contained
% entirely in this m-file, allowing for simpler installation.
%
%    X - a matrix of column vectors for training.
%
%    Y - a vector of category numbers (1-n), one per training vector.
%
%    C - a classifier you can pass to hmax_linclass_test.
%
% Thanks to Hristo Paskov (hristo.paskov@cs.stanford.edu) for the RLS code.
%
% See also: hmax_linclass_test.

%-----------------------------------------------------------------------------------------------------------------------

% Find the mean and standard deviation of the response to each feature across the entire training set.
% These statistics will be used to normalize the training and test vectors.

c.fMeans = zeros(size(x, 1), 1, 'single');
c.fStds  = zeros(size(x, 1), 1, 'single');

for i = 1 : size(x, 1)
    values = x(i, x(i, :) ~= cns_fltmin);
    if isempty(values)
        c.fMeans(i) = 0;
        c.fStds (i) = inf;
    else
        c.fMeans(i) = mean(values);
        c.fStds (i) = std (values);
        if c.fStds(i) == 0, c.fStds(i) = inf; end
    end
end

% Normalize the training vectors and set any "unknown" feature values to the feature mean.

for i = 1 : size(x, 1)
    x(i, x(i, :) == cns_fltmin) = c.fMeans(i);
    x(i, :) = (x(i, :) - c.fMeans(i)) / c.fStds(i);
end

% Now train one linear classifier per category.

nc = max(y);
if nc == 2, nc = 1; end

c.w = zeros(nc, size(x, 1), 'single');
c.b = zeros(nc, 1         , 'single');

k = x' * x;

for i = 1 : nc

    [w, b] = Solve(x, k, find(y == i), find(y ~= i));

    c.w(i, :) = w;
    c.b(i, 1) = b;

end

return;

%***********************************************************************************************************************

function [w, b] = Solve(x, k, pinds, ninds)

% Written by Hristo Paskov.

cost = 1;

np = numel(pinds);
nn = numel(ninds);

y = [ones(np, 1); -ones(nn, 1)];
x = double(x(:, [pinds ninds]));
k = double(k([pinds ninds], [pinds ninds]));

W = sqrt([repmat(0.5 / np, np, 1); repmat(0.5 / nn, nn, 1)]);
M = zeros(numel(y));
for i = 1 : numel(y)
    M(:, i) = k(:, i) .* W * W(i);
end
Z = y .* W;
R = chol(M + eye(numel(y)) * cost);
[C, b] = CholeskyCB(R, W, Z);

w = single(x * C);
b = single(b);

return;

%***********************************************************************************************************************

function [ C b ] = CholeskyCB( R, W, Y)

% Written by Hristo Paskov.

if isscalar(W)
    W = ones(size(Y, 1), 1)*W;
end

r = R\(R'\W);
b = sum(Y.*r)/sum(W.*r);
C = W.*(R\(R'\(Y - b.*W)));

return;