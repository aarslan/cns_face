classdef hmax_sdGRBF < hmax_sd

% Defines the "sdGRBF" cell type.  This is a subtype of "sd" which computes
% responses using a Gaussian RBF.

methods (Static)

%-----------------------------------------------------------------------------------------------------------------------

function [m, p] = Construct(m, g, p)

% Called automatically by hmax.Model to add a stage of this type to the CNS
% model structure M.  User-specified parameters specific to this type are as
% follows (C = P.groups{G}):
%
%    C.sigma - standard deviation of the gaussian.

[m, p] = cns_super(m, g, p);
c = p.groups{g};

m.groups{g}.sigma = c.sigma;

end

%-----------------------------------------------------------------------------------------------------------------------

function f = CNSFields

% Defines CNS fields specific to this cell type.

f.sigma = {'gp', 'private'}; % Standard deviation of the gaussian.

end

%-----------------------------------------------------------------------------------------------------------------------

end
end