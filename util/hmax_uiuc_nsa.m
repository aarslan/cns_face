function locs = hmax_uiuc_nsa(m, g, imSize, maps, p)

% LOCS = hmax_uiuc_nsa(M, G, IMSIZE, MAPS, P) implements the neighborhood
% suppression algorithm of [Agarwal et al. 2004] as used in [Mutch & Lowe 2006].
%
%    M - The CNS model structure.
%
%    G - The group number of the "c2" stage.
%
%    IMSIZE - Size of the raw image in pixels: [ySize xSize].
%
%    MAPS - Activation maps (one per scale) representing the output of a
%    classifier on the "c2" stage.
%
%    P - A few additional parameters; see code.

%-----------------------------------------------------------------------------------------------------------------------

% This code relies heavily on CNS's common coordinate system.
% We assume group 2 is the image pyramid.

zs = m.groups{g}.zs;

pzs = zeros(1, numel(zs));
for i = 1 : numel(zs)
    pzs(i) = m.layers{zs(i)}.pzs(1);
end

% Re-express suppression region size in terms of finest scale.
iz = m.groups{2}.zs(1);
yHood = p.yHood * m.layers{iz}.y_space;
xHood = p.xHood * m.layers{iz}.x_space;

% Invalidate missing edges (necessary because of different-sized test images).
bz = m.groups{2}.zs(m.groups{2}.baseScale);
yLoss = (-0.5 * imSize(1) * p.factor) - (m.layers{bz}.y_start - 0.5);
xLoss = (-0.5 * imSize(2) * p.factor) - (m.layers{bz}.x_start - 0.5);
for s = 1 : numel(maps)
    yr = 0.5 * m.layers{zs(s)}.size{2} * m.layers{zs(s)}.y_space - yLoss;
    xr = 0.5 * m.layers{zs(s)}.size{3} * m.layers{zs(s)}.x_space - xLoss;
    [y1, y2] = cns_findwithin_at(m, zs(s), 2, 0, yr);
    [x1, x2] = cns_findwithin_at(m, zs(s), 3, 0, xr);
    bad = true(size(maps{s}));
    bad(y1 : y2, x1 : x2) = false;
    maps{s}(bad) = -1e10;
end

% Apply threshold to activations.
for s = 1 : numel(maps)
    maps{s}(maps{s} < p.thres) = -1e10;
end

candidates = maps;

locs = struct;
locs.y = [];
locs.x = [];
locs.h = [];
locs.w = [];

while true

    % Find best location among remaining candidates.
    v = -1e10;
    for s2 = 1 : numel(maps)
        [v2, i2] = max(candidates{s2}(:));
        if v < v2
            v = v2;
            s = s2;
            [y, x] = ind2sub(size(maps{s2}), i2);
        end
    end
    if v == -1e10, break; end
    yc = cns_center(m, zs(s), 2, y);
    xc = cns_center(m, zs(s), 3, x);

    % Find suppression region.
    yr = yHood / m.layers{zs(1)}.y_space * m.layers{zs(s)}.y_space;
    xr = xHood / m.layers{zs(1)}.x_space * m.layers{zs(s)}.x_space;

    % Is this the best point in the suppression region?
    best = true;
    for s2 = 1 : numel(maps)
        [y1, y2] = cns_findwithin_at(m, zs(s2), 2, yc, yr);
        [x1, x2] = cns_findwithin_at(m, zs(s2), 3, xc, xr);
        if any(maps{s2}(y1 : y2, x1 : x2) > v)
            best = false;
            break;
        end
    end

    if best

        % Return this location.
        ySize = m.groups{g}.yCount * m.layers{pzs(s)}.y_space;
        xSize = m.groups{g}.xCount * m.layers{pzs(s)}.x_space;
        locs.y(end + 1) = (yc - 0.5 * ySize) / p.factor + 0.5 * imSize(1);
        locs.x(end + 1) = (xc - 0.5 * xSize) / p.factor + 0.5 * imSize(2);
        locs.h(end + 1) = ySize / p.factor;
        locs.w(end + 1) = xSize / p.factor;

        % Invalidate the region.
        for s2 = 1 : numel(maps)
            [y1, y2] = cns_findwithin_at(m, zs(s2), 2, yc, yr);
            [x1, x2] = cns_findwithin_at(m, zs(s2), 3, xc, xr);
            candidates{s2}(y1 : y2, x1 : x2) = -1e10;
        end

    else

        % Invalidate the location.
        candidates{s}(y, x) = -1e10;

    end

end

return;