classdef hmax_n < hmax_base

% Defines the "n" (normalization) cell type.  An "n" layer is the same size as
% the layer it is computed from, but with each cell's value normalized by the
% values of all the cells in a local neighborhood.  Neighborhood is defined by
% (y, x) position; "n" cells do not normalize over scales.
%
% This is an abstract type; the particular normalization function is undefined
% (and left to subtypes).

methods (Static)

%-----------------------------------------------------------------------------------------------------------------------

function [m, p] = Construct(m, g, p)

% Called automatically by hmax.Model to add an "n" stage to the CNS model
% structure M.  User-specified parameters specific to "n" cells are as follows
% (where C = P.groups{G}):
%
%    C.rfCount - size of the normalization (y, x) neighborhood, in number of
%    units.

c = p.groups{g};

pgzs = m.groups{c.pg}.zs;

zs = numel(m.layers) + (1 : numel(pgzs));

[m, p] = cns_super(m, g, p, zs);
c = p.groups{g};

m.groups{g}.rfCount = c.rfCount;

for i = 1 : numel(zs)

    z = zs(i);

    m.layers{z}.pzs = pgzs(i);

    m.layers{z}.size{1} = m.layers{pgzs(i)}.size{1};
    m = cns_mapdim(m, z, 2, 'copy', pgzs(i));
    m = cns_mapdim(m, z, 3, 'copy', pgzs(i));

end

end

%-----------------------------------------------------------------------------------------------------------------------

function p = CNSProps

p.abstract = true;

end

%-----------------------------------------------------------------------------------------------------------------------

function f = CNSFields

% Defines CNS fields specific to this cell type.

f.rfCount = {'gp', 'private', 'int'};

end

%-----------------------------------------------------------------------------------------------------------------------

end
end