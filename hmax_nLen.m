classdef hmax_nLen < hmax_n

% Defines the "nLen" cell type.  This is a subtype of "n" which divides by the
% local L2 norm.

methods (Static)

%-----------------------------------------------------------------------------------------------------------------------

function [m, p] = Construct(m, g, p)

% Called automatically by hmax.Model to add a stage of this type to the CNS
% model structure M.  User-specified parameters specific to this type are as
% follows (where C = P.groups{G}):
%
%    C.zero - true if the local mean should be subtracted prior to computing
%    the norm.
%
%    C.thres - Minimum value for (norm/sqrt(n)), where n is the number of cells
%    in the local neighborhood.  This avoids dividing by very small norms, which
%    tends to amplify noise.

[m, p] = cns_super(m, g, p);
c = p.groups{g};

m.groups{g}.zero  = c.zero;
m.groups{g}.thres = c.thres;

end

%-----------------------------------------------------------------------------------------------------------------------

function f = CNSFields

% Defines CNS fields specific to this cell type.

f.zero  = {'gp', 'private', 'int'}; % 0 or 1
f.thres = {'gp', 'private'};

end

%-----------------------------------------------------------------------------------------------------------------------

end
end