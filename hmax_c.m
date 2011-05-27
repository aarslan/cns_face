classdef hmax_c < hmax_base

% Defines the "c" cell type.  A "c" cell pools the values of nearby cells (in
% position or scale) of the same feature type in a previous stage.  It may also
% pool globally over position or scale.
%
% This is an abstract type; the particular pooling function is undefined (and
% left to subtypes).

methods (Static)

%-----------------------------------------------------------------------------------------------------------------------

function [m, p] = Construct(m, g, p)

% Called automatically by hmax.Model to add a "c" stage to the CNS model
% structure M.  User-specified parameters specific to "c" cells are as follows
% (where C = P.groups{G}):
%
%    C.sCount - number of scales across which a cell pools.  Inf = all scales.
%
%    C.sStep - step size (in scale) with which we tile the previous group.
%    Commonly 1.  Ignored if C.sCount = inf.
%
%    C.rfType - type of pooling over (y, x); either 'int' or 'win'.  See below.
%    The default is 'int'.
%
% If C.rfType == 'int', we tile in integral steps over the previous layer; the
% following quantities are numbers of cells in the previous layer (at the finest
% scale being pooled by a cell):
%
%    C.rfCount - size of the (square) receptive field.  Inf = global pooling.
%
%    C.rfStep - distance between "c" cell centers.  Ignored if C.rfCount = inf.
%
%    C.parity - optional; see cns_mapdim('int').
%
% If C.rfType == 'win', we still slide a window over the previous layer;
% however, the following quantities are specified in terms of pixels in the
% first (finest) scale in the image pyramid, and need not be integers:
%
%    C.yCount, C.xCount - height and width of the sliding window.
%
%    C.yStep, C.xStep - vertical and horizontal distance between sliding window
%    positions.
%
%    C.yMargin, C.xMargin - vertical and horizontal margins.  Positive
%    quantities mean we ignore positions near the edges, and negative quantities
%    mean we slide the window off the edges.
%
%    C.yParity, C.xParity - optional; see cns_mapdim('int').

c = p.groups{g};

pgzs = m.groups{c.pg}.zs;

if isfield(c, 'sNos')
    % TODO: document this option.
    pzs = {};
    for i = 1 : numel(c.sNos)
        pzs{i} = pgzs(c.sNos{i});
    end
elseif c.sCount < cns_intmax
    if numel(pgzs) < c.sCount, error('g=%u: not enough input layers', g); end
    pzs = {};
    for i = 1 : c.sStep : numel(pgzs) - c.sCount + 1
        pzs{end + 1} = pgzs(i) + (0 : c.sCount - 1);
    end
else
    pzs = {pgzs};
end

if isfield(c, 'rfType')
    mode = c.rfType;
else
    mode = 'int';
end

switch mode
case 'int'

    yCount = min(c.rfCount, cns_intmax);
    if yCount < cns_intmax
        yArgs = {c.rfStep};
        if isfield(c, 'parity'), yArgs{end + 1} = c.parity; end
    else
        yArgs = {};
    end

    xCount = yCount;
    xArgs  = yArgs;

case 'win'

    % Window size is expressed in common coordinates.
    % We make the assumption that group 2 is the image pyramid.
    iz = m.groups{2}.zs(1);
    yFactor = m.layers{iz}.y_space / m.layers{pgzs(1)}.y_space;
    xFactor = m.layers{iz}.x_space / m.layers{pgzs(1)}.x_space;

    yCount = min(c.yCount * yFactor, cns_intmax);
    if yCount < cns_intmax
        yArgs = {c.yStep * yFactor, c.yMargin * yFactor};
        if isfield(c, 'yParity'), yArgs{end + 1} = c.yParity; end
    else
        yArgs = {};
    end

    xCount = min(c.xCount * xFactor, cns_intmax);
    if xCount < cns_intmax
        xArgs = {c.xStep * xFactor, c.xMargin * xFactor};
        if isfield(c, 'xParity'), xArgs{end + 1} = c.xParity; end
    else
        xArgs = {};
    end

otherwise

    error('invalid rfType');

end

zs = numel(m.layers) + (1 : numel(pzs));

[m, p] = cns_super(m, g, p, zs);
c = p.groups{g};

m.groups{g}.yCount = yCount;
m.groups{g}.xCount = xCount;

for i = 1 : numel(zs)

    z = zs(i);

    m.layers{z}.pzs = pzs{i};

    m.layers{z}.size{1} = m.layers{pzs{i}(1)}.size{1};
    m = cns_mapdim(m, z, 2, mode, pzs{i}(1), yCount, yArgs{:});
    m = cns_mapdim(m, z, 3, mode, pzs{i}(1), xCount, xArgs{:});

end

end

%-----------------------------------------------------------------------------------------------------------------------

function p = CNSProps

p.abstract = true;

end

%-----------------------------------------------------------------------------------------------------------------------

function f = CNSFields

% Defines CNS fields specific to this cell type.

f.yCount = {'gp', 'private'}; % Height of the pooling window, in number of input cells (at the finest scale).
f.xCount = {'gp', 'private'}; % Width of the pooling window, in number of input cells (at the finest scale).

end

%-----------------------------------------------------------------------------------------------------------------------

end
end