classdef hmax < cns_package

% Defines some package-level methods for the HMAX package.  You can call them
% like this:
%
%    hmax.Model(...)
%    hmax.LoadImage(...)

methods (Static)

%-----------------------------------------------------------------------------------------------------------------------

function m = Model(p, lib, extra)

% M = hmax.Model(P, LIB) converts a compact set of parameters specifying an HMAX
% model into a full CNS model structure that can be instantiated on a GPU using
% cns('init').
%
% Each stage of an HMAX model (eg. S1, C1, ...) consists of multiple scales.
% These are represented in CNS as a "group" of "layers", where each layer
% represents a single scale.  (See the CNS manual for an explanation of layers
% and groups.)
%
%    P.groups{g} - A structure containing parameters specifying one stage of
%    your HMAX model.  P.groups{g}.type identifies the cell type.  The remaining
%    parameters are interpreted by that type's "Construct" method.  See those
%    methods for documentation.
%
%    LIB.groups{g} - The learned dictionary for that stage, if any.
%
% See also: hmax_cvpr06_run_simple.

if (nargin < 2) || ~isfield(lib, 'groups')
    lib.groups = {};
end
for g = numel(lib.groups) + 1 : numel(p.groups)
    lib.groups{g} = struct;
end

m.package = 'hmax';
m.groups  = {};
m.layers  = {};

for g = 1 : numel(p.groups)

    [m, p]   = cns_call(m.package, p.groups{g}.type, 'Construct', m, g, p);
    [m, lib] = cns_call(m, -g, 'AddDict', p, lib);

    for z = m.groups{g}.zs
        if any([m.layers{z}.size{2 : 3}] == 0)
            error('z=%u ("%s"): y or x size is zero', z, m.layers{z}.name);
        end
    end
    
end

% Establish the order in which layers will be computed.
m = cns_setstepnos(m, 'field', 'pzs');

if (nargin < 3) || extra
    % CNS itself ignores these fields, but they're useful for us.
    for g = 1 : numel(p.groups), m.( m.groups{g}.name       ) = g             ; end
    for g = 1 : numel(p.groups), m.([m.groups{g}.name '_zs']) = m.groups{g}.zs; end
end

if isfield(p, 'quiet'), m.quiet = p.quiet; end 

end

%-----------------------------------------------------------------------------------------------------------------------

function LoadImage(m, im, varargin)

% hmax.LoadImage(M, IM) loads an image into the input layer of an instantiated
% CNS model.  (The input layer is assumed to be layer 1 of the model.)
%
%    M - The CNS model which is currently instantiated on the GPU.
%
%    IM - Either the path of an image or an array containing an image.

bufSize = [m.layers{1}.size{2 : 3}];

% We also assume that group 2 is the image pyramid.
bz = m.groups{2}.zs(m.groups{2}.baseScale);
n.size  = [m.layers{bz}.size{2 : 3}];
n.start = [m.layers{bz}.y_start, m.layers{bz}.x_start];
n.space = [1 1];

[p, val] = cns_prepimage(bufSize, n, im, varargin{:});

cns('set', {1, 'val', shiftdim(val, -1)}, ...
    {1, 'y_start', p.start(1)}, {1, 'y_space', p.space(1)}, {bz, 'py_count', p.size(1)}, ...
    {1, 'x_start', p.start(2)}, {1, 'x_space', p.space(2)}, {bz, 'px_count', p.size(2)});

end

%-----------------------------------------------------------------------------------------------------------------------

function m = CNSInit(m)

% Called automatically by cns('init').  Performs any final initialization for
% the CNS model structure just before it is instantiated on the GPU.  This
% method calls the "Init" method (if it exists) for each stage.

% Turns off double-buffering.
m.independent = true;

for g = 1 : numel(m.groups)
    m = cns_call(m, -g, 'Init');
end

end

%-----------------------------------------------------------------------------------------------------------------------

end
end