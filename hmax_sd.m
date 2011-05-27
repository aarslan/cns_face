classdef hmax_sd < hmax_s

% Defines the "sd" cell type.  This is a subtype of "s" in which the dictionary
% is "dense" -- the stored templates contain values for every feature at every
% position.
%
% This is an abstract type; the particular function used to compute the response
% to a template is undefined (and left to subtypes).

methods (Static)

%-----------------------------------------------------------------------------------------------------------------------

function p = CNSProps

p.abstract = true;

end

%-----------------------------------------------------------------------------------------------------------------------

function f = CNSFields

% Defines CNS fields specific to this cell type.

% Holds the stored values that make up the templates.  The "f" dimension represents features in the previous
% layer, and the "nf" dimension represents the template number.  Comes from the dictionary.
f.fVals = {'ga', 'cache', 'dims', {[1 2] 1 2 [1 2]}, 'dparts', {[2 2] 1 1 [3 3]}, 'dnames', {'f' 'y' 'x' 'nf'}};

end

%-----------------------------------------------------------------------------------------------------------------------

function [m, lib] = AddDict(m, g, p, lib)

% Called automatically for "sd" stages by hmax.Model.  Adds dictionary
% information to the CNS model structure.

[m, lib] = cns_super(m, g, p, lib);
c = p  .groups{g};
d = lib.groups{g};

pfCount = m.layers{m.groups{c.pg}.zs(1)}.size{1};

if isempty(d.fSizes)

    d.fVals = reshape(d.fVals, pfCount, max(c.rfCount), max(c.rfCount), 0);

else

    if isfield(d, 'fMap'), error('dictionary is in sparse format'); end

    if size(d.fVals, 1) ~= pfCount
        error('dimension 1 of fVals does not match the feature count of the previous group');
    end
    if size(d.fVals, 2) < max(d.fSizes)
        error('dimension 2 of fVals is smaller than the largest feature');
    end
    if size(d.fVals, 3) ~= size(d.fVals, 2)
        error('dimension 3 of fVals is different than dimension 2');
    end
    if size(d.fVals, 4) ~= numel(d.fSizes)
        error('dimension 4 of fVals must match the length of fSizes');
    end
    
end

m.groups{g}.fVals = d.fVals;

lib.groups{g} = d;

end

%-----------------------------------------------------------------------------------------------------------------------

end
end