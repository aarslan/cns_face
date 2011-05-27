classdef hmax_inhib1 < hmax_base

% Defines the "inhib1" cell type.  This type, together with the "inhib2" type,
% implements the lateral inhibition described in section 2.3 of [Mutch & Lowe
% 2006] (under heading "inhibit S1/C1 outputs").  An "inhib1" cell looks at all
% the cells in a single (y, x) position in a lower layer and decides what the
% cutoff value should be.

methods (Static)

%-----------------------------------------------------------------------------------------------------------------------

function [m, p] = Construct(m, g, p)

% Called automatically by hmax.Model to add an "inhib1" stage to the CNS model
% structure M.  User-specified parameters specific to "inhib1" cells are as
% follows (where C = P.groups{G}):
%
%    C.inhibit - inhibition level (h) per [Mutch & Lowe 2006].

c = p.groups{g};

pgzs = m.groups{c.pg}.zs;

zs = numel(m.layers) + (1 : numel(pgzs));

[m, p] = cns_super(m, g, p, zs);
c = p.groups{g};

m.groups{g}.inhibit = c.inhibit;

for i = 1 : numel(zs)

    z = zs(i);

    m.layers{z}.pzs = pgzs(i);

    m.layers{z}.size{1} = 1;
    m = cns_mapdim(m, z, 2, 'copy', pgzs(i));
    m = cns_mapdim(m, z, 3, 'copy', pgzs(i));

end

end

%-----------------------------------------------------------------------------------------------------------------------

function f = CNSFields

% Defines CNS fields specific to this cell type.

f.inhibit = {'gp', 'private'}; % Inhibition level per [Mutch & Lowe 2006].

end

%-----------------------------------------------------------------------------------------------------------------------

end
end