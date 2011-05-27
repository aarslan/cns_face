classdef hmax_s < hmax_base

% Defines the "s" cell type.  An "s" cell computes the response of a patch of
% cells in a lower layer to a stored template of the same size.  Templates can
% be learned or precomputed.
%
% Note that the stored templates can have different sizes, which means that not
% all templates will 'fit' at all positions.  When this occurs, output cells
% will have the value cns_fltmin.
%
% This is an abstract type; the particular function used to compute the response
% is undefined (and left to subtypes).

methods (Static)

%-----------------------------------------------------------------------------------------------------------------------

function [m, p] = Construct(m, g, p)

% Called automatically by hmax.Model to add an "s" stage to the CNS model
% structure M.  User-specified parameters specific to "s" cells are as follows
% (where C = P.groups{G}):
%
%    C.rfCount - sizes of (square) templates.  For example, [4 8 12 16].
%
%    C.rfSpace - separation of units within a template (default = 1, i.e.
%    contiguous).
%
%    C.rfStep - distance between "s" cell centers, in number of previous layer
%    units.  Commonly 1.
%
%    C.fParams - if using generated (unlearned) templates, this must be a cell
%    array of parameters that define the templates.  For example:
%       C.fParams = {'gabor', 0.3, 3.5, 2.8};
%    "Construct" will call the "GenerateDict" method automatically with these
%    parameters (with FUNC = the first element and VARARGIN = the remaining
%    elements).  See the "GenerateDict" method for details.

c = p.groups{g};

pgzs = m.groups{c.pg}.zs;

zs = numel(m.layers) + (1 : numel(pgzs));

[m, p] = cns_super(m, g, p, zs);
c = p.groups{g};

if ~isfield(c, 'rfSpace'), c.rfSpace = 1; end

m.groups{g}.rfCount    = c.rfCount;
m.groups{g}.rfCountMin = min(c.rfCount);
m.groups{g}.rfSpace    = c.rfSpace;

rfWidthMin = 1 + (min(c.rfCount) - 1) * c.rfSpace;

if isfield(c, 'parity'), parity = c.parity; else parity = []; end

for i = 1 : numel(zs)

    z = zs(i);

    m.layers{z}.pzs = pgzs(i);

    m = cns_mapdim(m, z, 2, 'int', pgzs(i), rfWidthMin, c.rfStep, parity);
    m = cns_mapdim(m, z, 3, 'int', pgzs(i), rfWidthMin, c.rfStep, parity);

end

p.groups{g} = c;

end

%-----------------------------------------------------------------------------------------------------------------------

function d = GenerateDict(m, g, fCount, func, varargin)

% D = hmax_s.GenerateDict(M, G, FCOUNT, FUNC, ...) generates a dictionary of
% precomputed templates (often referred to as "filters") for a group.  Called
% automatically by the "Construct" method.
%
%    M - A CNS model structure.
%
%    G - The number of the stage (group) to which the dictionary will belong.
%    Must be an "s" group.
%
%    FCOUNT - Number of templates to generate.
%
%    FUNC - Function that will generate the templates.  Can be a function handle
%    or a string identifying a known filter (currently the only such option is
%    'gabor').  Refer to code below to see how the filter function is called.
%
%    VARARGIN - Any additional arguments required by the filter function.
%
% Note: the generated dictionary will be a "dense" dictionary, suitable for the
% "sd" cell type.

pfCount  = m.layers{m.groups{m.groups{g}.pg}.zs(1)}.size{1};
rfCounts = m.groups{g}.rfCount;
rfSpace  = m.groups{g}.rfSpace;

if (pfCount == 0) || (fCount == 0)
    d = hmax_s.EmptyDict(m, g);
    return;
end

if isa(func, 'function_handle')
elseif ischar(func)
    switch func
    case 'gabor', func = @Gabor;
    otherwise   , error('invalid filter function');
    end
else
    error('invalid filter function');
end

% Call the function to generate the filters.  All such functions must have the
% same first 4 arguments.
d = func(pfCount, rfCounts, rfSpace, fCount, varargin{:});

for f = 1 : fCount
    v = d.fVals(:, :, :, f);
    v = cns_call(m, -g, 'Normalize', v);
    if isempty(v), error('invalid filter generated'); end
    d.fVals(:, :, :, f) = v;
end

d.fSPos = repmat(1  , 1, fCount);
d.fYPos = repmat(0.5, 1, fCount);
d.fXPos = repmat(0.5, 1, fCount);

end

%-----------------------------------------------------------------------------------------------------------------------

function d = EmptyDict(m, g, fCount)

% D = hmax_s.EmptyDict(M, G) returns an empty feature dictionary for group G.
% This is useful for starting off a dictionary that you're going to be adding
% to with the "SampleFeatures" method.
%
% Note: the empty dictionary will be a "dense" dictionary, suitable for the
% "sd" cell type.

if nargin < 3, fCount = 0; end

pfCount    = m.layers{m.groups{m.groups{g}.pg}.zs(1)}.size{1};
maxRFCount = max(m.groups{g}.rfCount);

d.fSizes = zeros(1, fCount);
d.fVals  = zeros(pfCount, maxRFCount, maxRFCount, fCount, 'single');
d.fSPos  = zeros(1, fCount);
d.fYPos  = zeros(1, fCount);
d.fXPos  = zeros(1, fCount);

end

%-----------------------------------------------------------------------------------------------------------------------

function d = SampleFeatures(m, g, d, numSamples, p)

% D = hmax_s.SampleFeatures(M, G, D, NUMSAMPLES) adds features to dictionary D
% by sampling new features at random positions and scales from the current
% values of the feature hierarchy, i.e. from a single image.  Generally you will
% make a dictionary by calling this method for many images.
%
%    M - The CNS model which is currently instantiated on the GPU.
%
%    G - The number of the stage (group) to which the dictionary belongs.  Must
%    be an "s" stage.
%
%    D - An existing dictionary.  You can create an empty dictionary using the
%    "EmptyDict" method.
%
%    NUMSAMPLES - The number of new features to sample.
%
% Note: D must be a "dense" dictionary, suitable for the "sd" cell type.

if nargin < 5, p = struct; end
if ~isfield(p, 'mask'), p.mask = []; end

rfCounts = m.groups{g}.rfCount;
rfSpace  = m.groups{g}.rfSpace;
rfSizes = 1 + (rfCounts - 1) * rfSpace;

unknown = single(cns_fltmin);

% Get information from previous group.

vals = cns('get', -m.groups{g}.pg, 'val');

zs = m.groups{m.groups{g}.pg}.zs;

yMargs  = zeros(1, numel(zs));
xMargs  = zeros(1, numel(zs));
yCounts = zeros(1, numel(zs));
xCounts = zeros(1, numel(zs));
yStarts = zeros(1, numel(zs));
xStarts = zeros(1, numel(zs));
ySpaces = zeros(1, numel(zs));
xSpaces = zeros(1, numel(zs));

for s = 1 : numel(zs)

    z = zs(s);

    known = shiftdim(any(vals{s} > unknown, 1), 1);
    y = find(any(known, 2), 1, 'first');
    if ~isempty(y)
        yMargs (s) = y - 1;
        yCounts(s) = find(any(known, 2), 1, 'last') - y + 1;
    end
    x = find(any(known, 1), 1, 'first');
    if ~isempty(x)
        xMargs (s) = x - 1;
        xCounts(s) = find(any(known, 1), 1, 'last') - x + 1;
    end

    yStarts(s) = m.layers{z}.y_start;
    xStarts(s) = m.layers{z}.x_start;
    ySpaces(s) = m.layers{z}.y_space;
    xSpaces(s) = m.layers{z}.x_space;

end

% Get information about the image pyramid.
% We make the assumption that this is group 2.

bz = m.groups{2}.zs(m.groups{2}.baseScale);
iy_start = m.layers{bz}.y_start - 0.5;
ix_start = m.layers{bz}.x_start - 0.5;
iy_width = m.layers{bz}.size{2};
ix_width = m.layers{bz}.size{3};

% Count the number of valid sample positions for each feature size (n) and scale (s).

nCounts  = zeros(1, numel(rfSizes));
nsCounts = cell (1, numel(rfSizes));
for n = 1 : numel(rfSizes)
    nsCounts{n} = cumsum(max(yCounts - rfSizes(n) + 1, 0) .* max(xCounts - rfSizes(n) + 1, 0));
    nCounts(n) = nsCounts{n}(end);
end
nCounts = cumsum(nCounts);

if nCounts(end) == 0
    error('no valid sample positions');
end
if nCounts(end) < numSamples
    warning('more samples (%u) than valid sample positions (%u) requested', numSamples, nCounts(end));
end

% Now start sampling features.

nf = find(d.fSizes > 0, 1, 'last');
if isempty(nf), nf = 0; end

for i = 1 : numSamples

    found = false;

    for attempt = 1 : 1000

        n = find(randi(nCounts(end)) <= nCounts, 1);
        s = find(randi(nsCounts{n}(end)) <= nsCounts{n}, 1);

        y = randi(yCounts(s) - rfSizes(n) + 1) + yMargs(s);
        x = randi(xCounts(s) - rfSizes(n) + 1) + xMargs(s);
        yPos = yStarts(s) + (y - 1 + (rfSizes(n) - 1) / 2) * ySpaces(s);
        xPos = xStarts(s) + (x - 1 + (rfSizes(n) - 1) / 2) * xSpaces(s);

        if ~isempty(p.mask)
            % Make sure this position contains at least some of the object.
            [y1, y2] = cns_findwithin_at(m, bz, 'y', yPos, p.rad);
            [x1, x2] = cns_findwithin_at(m, bz, 'x', xPos, p.rad);
            if ~any(reshape(p.mask(y1 : y2, x1 : x2), 1, [])), continue; end
        end

        v = vals{s}(:, y : rfSpace : y + rfSizes(n) - 1, x : rfSpace : x + rfSizes(n) - 1);
        if ~all(v(:) > unknown), continue; end

        v = cns_call(m, -g, 'Normalize', v);
        if isempty(v), continue; end

        found = true;
        break;

    end

    if ~found
        warning('unable to sample features from this image');
        break;
    end

    nf = nf + 1;

    d.fSizes(nf) = rfCounts(n);

    d.fVals(:, 1 : rfCounts(n), 1 : rfCounts(n), nf) = v;

    d.fSPos(nf) = s;
    d.fYPos(nf) = (yPos - iy_start) / iy_width;
    d.fXPos(nf) = (xPos - ix_start) / ix_width;

end

end

%-----------------------------------------------------------------------------------------------------------------------

function d = CombineDicts(d, d2)

% D = hmax_s.CombineDicts(D1, D2) combines the features in two dictionaries to
% make a larger dictionary.
%
% Note: D1 and D2 must be "dense" dictionaries, suitable for the "sd" cell type.

if isempty(d2.fSizes), return; end
if isempty(d.fSizes)
    d = d2;
    return;
end

if isfield(d, 'fMap') || isfield(d2, 'fMap')
    error('not supported for sparse dictionaries');
end

if size(d.fVals, 1) ~= size(d2.fVals, 1), error('previous feature counts do not match'); end

d.fSizes(end + 1 : end + numel(d2.fSizes)) = d2.fSizes;

d.fVals(:, end + 1 : size(d2.fVals, 2), :, :) = 0;
d.fVals(:, :, end + 1 : size(d2.fVals, 3), :) = 0;
d.fVals(:, :, :, end + 1 : end + size(d2.fVals, 4)) = d2.fVals;

d.fSPos(end + 1 : end + numel(d2.fSPos)) = d2.fSPos;
d.fYPos(end + 1 : end + numel(d2.fYPos)) = d2.fYPos;
d.fXPos(end + 1 : end + numel(d2.fXPos)) = d2.fXPos;

end

%-----------------------------------------------------------------------------------------------------------------------

function d = SortFeatures(d)

% D = hmax_s.SortFeatures(D) sorts a dictionary's features by size.  This
% increases the speed of models that use the dictionary.

[ans, inds] = sort(d.fSizes);

d = hmax_s.SelectFeatures(d, inds);

end

%-----------------------------------------------------------------------------------------------------------------------

function d = SelectFeatures(d, inds)

% D = hmax_s.SelectFeatures(D, INDS) retains specific dictionary features.
%
%    INDS - The feature numbers to retain.

d.fSizes = d.fSizes(inds);

if isfield(d, 'fMap')
    d.fVals = d.fVals(:, inds);
    d.fMap  = d.fMap (:, :, inds);
else
    d.fVals = d.fVals(:, :, :, inds);
end

d.fSPos = d.fSPos(inds);
d.fYPos = d.fYPos(inds);
d.fXPos = d.fXPos(inds);

end

%-----------------------------------------------------------------------------------------------------------------------

function v = Normalize(m, g, v)

% This method is meant to be overridden by subtypes.  A subtype can supply a
% method that will be called to normalize a template prior to inserting it into
% the dictionary.  It will be called automatically by "GenerateDict" and
% "SampleFeatures".
%
%    M - A CNS model structure.
%
%    G - The number of the stage (group) to whose dictionary a template is
%    being added.  Must be an "s" stage.
%
%    V - The template values.
%
% The subtype implementation should return [] if it considers the template
% invalid, i.e. if it should not be inserted into the dictionary.  For example,
% a template sampled from a uniform patch of an image might be considered
% useless.

end

%-----------------------------------------------------------------------------------------------------------------------

function p = CNSProps

p.abstract = true;

end

%-----------------------------------------------------------------------------------------------------------------------

function f = CNSFields

% Defines CNS fields specific to this cell type.

f.rfCountMin = {'gp', 'private', 'int'}; % Minimum size of a (square) template.
f.rfSpace    = {'gp', 'private', 'int'}; % Separation of units within a template (1 = contiguous).

% Size of each template in the dictionary.
f.fSizes = {'ga', 'dims', {1}, 'dparts', {1}, 'dnames', {'nf'}, 'int'};

end

%-----------------------------------------------------------------------------------------------------------------------

function [m, lib] = AddDict(m, g, p, lib)

% Called automatically for "s" stages by hmax.Model.  Adds dictionary
% information to the CNS model structure.

[m, lib] = cns_super(m, g, p, lib);
c = p  .groups{g};
d = lib.groups{g};

if isfield(d, 'fSizes')

    if any(d.fSizes < 1)
        error('invalid fSizes value');
    end
    if (mod(c.rfSpace, 2) == 1) && (numel(unique(mod(d.fSizes, 2))) > 1)
        error('when rfSpace is odd, fSizes must be all even or all odd');
    end
    if any(diff(d.fSizes) < 0)
        warning('dictionary is not sorted by feature size; this is inefficient');
    end

    if numel(d.fSPos) ~= numel(d.fSizes), error('incorrect fSPos length'); end
    if numel(d.fYPos) ~= numel(d.fSizes), error('incorrect fYPos length'); end
    if numel(d.fXPos) ~= numel(d.fSizes), error('incorrect fXPos length'); end

elseif isfield(c, 'fParams')

    d = hmax_s.GenerateDict(m, g, c.fCount, c.fParams{:});

else

    d = hmax_s.EmptyDict(m, g);

end

d.fSizes = reshape(d.fSizes, 1, []);
d.fSPos  = reshape(d.fSPos , 1, []);
d.fYPos  = reshape(d.fYPos , 1, []);
d.fXPos  = reshape(d.fXPos , 1, []);

m.groups{g}.fSizes = d.fSizes(:);

for z = m.groups{g}.zs
    m.layers{z}.size{1} = numel(d.fSizes);
end

lib.groups{g} = d;

end

%-----------------------------------------------------------------------------------------------------------------------

end
end

%***********************************************************************************************************************

function d = Gabor(pfCount, rfCount, rfSpace, fCount, aspectRatio, lambda, sigma)

% Generates Gabor filters.  Called by "GenerateDict".

if pfCount ~= 1, error('previous group feature count must be 1'); end
if ~isscalar(rfCount), error('only one feature size supported'); end
if rfSpace ~= 1, error('rf spacing must be 1'); end

d.fSizes = repmat(rfCount, 1, fCount);
d.fVals  = zeros(1, rfCount, rfCount, fCount, 'single');

points = (1 : rfCount) - ((1 + rfCount) / 2);

for f = 1 : fCount

    theta = (f - 1) / fCount * pi;

    for j = 1 : rfCount
        for i = 1 : rfCount

            x = points(j) * cos(theta) - points(i) * sin(theta);
            y = points(j) * sin(theta) + points(i) * cos(theta);

            if sqrt(x * x + y * y) <= rfCount / 2
                e = exp(-(x * x + aspectRatio * aspectRatio * y * y) / (2 * sigma * sigma));
                e = e * cos(2 * pi * x / lambda);
            else
                e = 0;
            end

            d.fVals(1, i, j, f) = e;

        end
    end

end

end