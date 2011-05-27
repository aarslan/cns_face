classdef hmax_sdNDP < hmax_sd

% Defines the "sdGRBF" cell type.  This is a subtype of "sd" which computes
% responses using a normalized dot product.

methods (Static)

%-----------------------------------------------------------------------------------------------------------------------

function [m, p] = Construct(m, g, p)

% Called automatically by hmax.Model to add a stage of this type to the CNS
% model structure M.  User-specified parameters specific to this type are as
% follows (where C = P.groups{G}):
%
%    C.zero - true if the mean should be subtracted from both the template and
%    the input patch prior to computing the dot product and the norm, false if
%    not.  To use different settings for templates and input patches, specify
%    [t p] where t=0/1 applies to templates and p=0/1 applies to input patches.
%
%    C.thres - Minimum value for (norm/sqrt(n)), where n is the dimensionality
%    of the dot product.  This avoids dividing by very small norms, which tends
%    to amplify noise.  If a template's norm is less than the minimum value, it
%    will be rejected from the dictionary.  If a patch's norm is less than the
%    minimum, the response to the patch will be 0.  To use different thresholds
%    for (t)emplates and input (p)atches, give the two thresholds as [t p].
%
%    C.abs - true if the absolute value of the result should be taken, false to
%    preserve the sign.

[m, p] = cns_super(m, g, p);
c = p.groups{g};

m.groups{g}.zero_temp  = c.zero(1);
m.groups{g}.zero       = c.zero(end);
m.groups{g}.thres_temp = c.thres(1);
m.groups{g}.thres      = c.thres(end);
m.groups{g}.abs        = c.abs;

end

%-----------------------------------------------------------------------------------------------------------------------

function v = Normalize(m, g, v)

% V = hmax_sdNDP.Normalize(M, G, V) normalizes a prospective template V
% according to the parameters used to construct stage G of the CNS model
% structure M.  If the norm of the template is too small, [] will be returned.
%
% This method is called automatically by hmax_s.GenerateDict and
% hmax_s.SampleFeatures to normalize templates before they are inserted into
% the dictionary.

zero  = m.groups{g}.zero_temp;
thres = m.groups{g}.thres_temp;

inds = (v > cns_fltmin);
if ~any(inds), v = []; return; end

if zero, v(inds) = v(inds) - mean(v(inds)); end

norm = sqrt(sum(v(inds) .* v(inds)));
if norm < thres * sqrt(sum(inds)), v = []; return; end
if norm == 0
    v(inds) = 0;
else
    v(inds) = v(inds) / norm;
end

end

%-----------------------------------------------------------------------------------------------------------------------

function f = CNSFields

% Defines CNS fields specific to this cell type.

f.zero  = {'gp', 'private', 'int'}; % 0 or 1
f.thres = {'gp', 'private'};        
f.abs   = {'gp', 'private', 'int'}; % 0 or 1

end

%-----------------------------------------------------------------------------------------------------------------------

end
end