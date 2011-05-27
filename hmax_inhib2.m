classdef hmax_inhib2 < hmax_base

% Defines the "inhib2" cell type.  This type, together with "inhib1" type,
% implements the lateral inhibition described in section 2.3 of [Mutch & Lowe
% 2006] (under heading "inhibit S1/C1 outputs").  An "inhib2" stage applies the
% cutoffs computed by an "inhib1" stage to a previous stage, generating a copy
% of that stage with weak responses set to zero.  In the "full" model of [Mutch
% & Lowe 2006] this is done for both S1 and C1.

methods (Static)

%-----------------------------------------------------------------------------------------------------------------------

function [m, p] = Construct(m, g, p)

% Called automatically by hmax.Model to add an "inhib2" stage to the CNS model
% structure M.  User-specified parameters specific to "inhib2" cells are as
% follows (where C = P.groups{G}):
%
%    C.ig - group number of the associated "inhib1" stage.

c = p.groups{g};

if ~strcmp(p.groups{c.ig}.type, 'inhib1')
    error('g=%u: "ig" must identify a group of type "inhib1"', g);
end

pgzs = m.groups{c.pg}.zs;
igzs = m.groups{c.ig}.zs;

zs = numel(m.layers) + (1 : numel(pgzs));

[m, p] = cns_super(m, g, p, zs);
c = p.groups{g};

for i = 1 : numel(zs)

    z = zs(i);

    m.layers{z}.pzs = [pgzs(i), igzs(i)];

    m.layers{z}.size{1} = m.layers{pgzs(i)}.size{1};
    m = cns_mapdim(m, z, 2, 'copy', pgzs(i));
    m = cns_mapdim(m, z, 3, 'copy', pgzs(i));

end

end

%-----------------------------------------------------------------------------------------------------------------------

end
end