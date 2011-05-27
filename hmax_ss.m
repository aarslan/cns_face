classdef hmax_ss < hmax_s

% Defines the "ss" cell type.  This is a subtype of "s" in which the dictionary
% is "sparse" -- the stored templates may ignore the values of some features at
% any given position.
%
% This is an abstract type; the particular function used to compute the response
% to a template is undefined (and left to subtypes).

methods (Static)

%-----------------------------------------------------------------------------------------------------------------------

function d = SparsifyDict(d)

% D = hmax_ss.SparsifyDict(D) converts a dictionary of "dense" features
% (probably created by hmax_s.SampleFeatures) to "sparse" features as described
% in Section 2.3 of [Mutch & Lowe 2006].

if isfield(d, 'fMap'), error('dictionary is already in sparse format'); end

% TODO: add more ways to sparsify.

for nf = 1 : numel(d.fSizes)

    v = d.fVals(:, :, :, nf);

    d.fVals(:, :, :, nf) = cns_fltmin;

    for j = 1 : size(v, 3)
    for i = 1 : size(v, 2)
        [a, f] = max(v(:, i, j));
        d.fVals(f, i, j, nf) = a;
    end
    end

end

d = SparseFormat(d);

end

%-----------------------------------------------------------------------------------------------------------------------

function p = CNSProps

p.abstract = true;

end

%-----------------------------------------------------------------------------------------------------------------------

function f = CNSFields

% Defines CNS fields specific to this cell type.

% Hold the stored values that make up the templates.  fVals comes directly from the sparse dictionary (see
% SparsifyDict) and fMap2 is generated in the "Init" method.
f.fVals = {'ga', 'private', 'cache', 'dims', {1 [2 2]}, 'dparts', {1 [1 2]}, 'dnames', {'p' 'nf'}};
f.fMap2 = {'ga', 'private', 'cache', 'dims', {1 [2 2]}, 'dparts', {1 [1 2]}, 'dnames', {'p' 'nf'}, 'int'};

end

%-----------------------------------------------------------------------------------------------------------------------

function [m, lib] = AddDict(m, g, p, lib)

% Called automatically for "ss" stages by hmax.Model.  Adds dictionary
% information to the CNS model structure.

[m, lib] = cns_super(m, g, p, lib);
d = lib.groups{g};

if isempty(d.fSizes)

    if ~isfield(d, 'fMap'), d.fMap = []; end  % Won't be present in new empty dictionary.

    d.fVals = reshape(d.fVals,    0, 0);
    d.fMap  = reshape(d.fMap , 3, 0, 0);

else

    if ~isfield(d, 'fMap'), error('dictionary is not in sparse format'); end

    if size(d.fVals, 2) ~= numel(d.fSizes)
        error('dimension 2 of fVals does not match the length of fSizes');
    end

    if size(d.fMap, 1) ~= 3
        error('dimension 1 of fMap must have size 3');
    end
    if size(d.fMap, 2) ~= size(d.fVals, 1)
        error('dimension 2 of fMap must match dimension 1 of fVals');
    end
    if size(d.fMap, 3) ~= size(d.fVals, 2)
        error('dimension 3 of fMap must match dimension 2 of fVals');
    end

end

m.groups{g}.fVals = d.fVals;
m.groups{g}.fMap  = d.fMap;

lib.groups{g} = d;

end

%-----------------------------------------------------------------------------------------------------------------------

function m = Init(m, g)

% Generates fMap2 from fMap (which comes from the dictionary).  This format is
% a bit more memory efficient.  Called automatically by hmax.CNSInit.

m = cns_super(m, g);
c = m.groups{g};

pfCount = m.layers{m.layers{c.zs(1)}.pzs(1)}.size{1};
if pfCount > 65536
    error('previous group can have at most 65536 features');
end

if any(c.fSizes > 128)
    error('maximum fSizes value cannot exceed 128');
end

fs = double(shiftdim(c.fMap(1, :, :), 1)) - 1;
ys = double(shiftdim(c.fMap(2, :, :), 1)) - 1;
xs = double(shiftdim(c.fMap(3, :, :), 1)) - 1;

cs = sum(fs >= 0, 1);

is = fs; % TODO: could be negative numbers here?
is = is + ys * 65536;
is = is + xs * 65536 * 256;

c.fMap2 = [cs; is]; % The first position in the table for each template is the number of values.

m.groups{g} = c;

end

%-----------------------------------------------------------------------------------------------------------------------

end
end

%***********************************************************************************************************************

function d = SparseFormat(d)

fSizes = d.fSizes;
dVals  = single(d.fVals);

unknown = single(cns_fltmin);

inCounts = zeros(1, numel(fSizes));
for nf = 1 : numel(fSizes)
    inCounts(nf) = sum(reshape(dVals(:, 1 : fSizes(nf), 1 : fSizes(nf), nf), 1, []) > unknown);
end
inCountMax = max(inCounts);

sVals = repmat(unknown         , [   inCountMax, numel(fSizes)]);
sMap  = repmat(single([0 1 1]'), [1, inCountMax, numel(fSizes)]);

for nf = 1 : numel(fSizes)
    p = 1;
    for f = 1 : size(dVals, 1)
    for j = 1 : fSizes(nf)
    for i = 1 : fSizes(nf)
        v = dVals(f, i, j, nf);
        if v > unknown
            sVals(   p, nf) = v;
            sMap (1, p, nf) = f;
            sMap (2, p, nf) = i;
            sMap (3, p, nf) = j;
            p = p + 1;
        end
    end
    end
    end
end

d.fVals = sVals;
d.fMap  = sMap;

end