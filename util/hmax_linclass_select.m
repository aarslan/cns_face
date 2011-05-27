function dims = hmax_linclass_select(x, y, rounds)

% Performs a feature selection 'tournament' as described in [Mutch & Lowe 2006].

%-----------------------------------------------------------------------------------------------------------------------

if rounds == 0

    dims = 1 : size(x, 1);

else

    % First (recursively) conduct two sub-tournaments to get the candidate features.

    dims = randperm(size(x, 1));

    d1 = dims(1 : floor(0.5 * numel(dims)));
    d2 = dims(numel(d1) + 1 : end);

    d1 = d1(hmax_linclass_select(x(d1, :), y, rounds - 1));
    d2 = d2(hmax_linclass_select(x(d2, :), y, rounds - 1));

    dims = [d1 d2];

    % Now select the best half of the remaining candidate features.

    c = hmax_linclass_train(x(dims, :), y);

    [ans, inds] = sort(sum(abs(c.w), 1), 'descend');
    inds = inds(1 : floor(0.5 * numel(inds)));

    dims = sort(dims(inds));

end

return;