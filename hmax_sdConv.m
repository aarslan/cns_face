classdef hmax_sdConv < hmax_sd

% Defines the "sdConv" cell type.  This is a subtype of "sd" which computes
% responses via simple convolution.

methods (Static)

%-----------------------------------------------------------------------------------------------------------------------

function [m, p] = Construct(m, g, p)

% Called automatically by hmax.Model to add a stage of this type to the CNS
% model structure M.  User-specified parameters specific to this type are as
% follows (C = P.groups{G}):
%
%    C.abs - true if the absolute value of the result should be taken, false to
%    preserve the sign.

[m, p] = cns_super(m, g, p);
c = p.groups{g};

m.groups{g}.abs = c.abs;

end

%-----------------------------------------------------------------------------------------------------------------------

function f = CNSFields

% Defines CNS fields specific to this cell type.

f.abs = {'gp', 'private', 'int'}; % 0 or 1

end

%-----------------------------------------------------------------------------------------------------------------------

end
end