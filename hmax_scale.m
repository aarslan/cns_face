classdef hmax_scale < hmax_base

% Defines the "scale" cell type.  A "scale" stage computes an image pyramid from
% the input layer by resizing.
%
% Note that if the input image does not have the same aspect ratio as the base
% of the image pyramid, the resulting scaled images will be centered and padded.
% The value used for padding is cns_fltmin.

methods (Static)

%-----------------------------------------------------------------------------------------------------------------------

function [m, p] = Construct(m, g, p)

% Called automatically by hmax.Model to add a "scale" stage to the CNS model
% structure M.  User-specified parameters specific to "scale" layers are as
% follows (where C = P.groups{G}):
%
%    C.baseSize - a two element vector specifying the (y, x) size of the "base"
%    scale of the image pyramid in pixels.  (The "base" scale is normally the
%    finest scale, but see the BASESCALE parameter below.)
%
%    C.numScales - the desired number of scales (i.e., layers) in the image
%    pyramid.
%
%    C.scaleFactor - the scale factor between scales.  A number greater than 1;
%    a common value is (2 ^ 1/4).
%
%    C.baseScale - Identifies which of the NUMSCALES scales is considered the
%    "base" scale.  The base scale will have size BASESIZE and cell spacing of
%    1 in the common coordinate system.  If BASESCALE is greater than 1, then
%    scales below BASESCALE will have size greater than BASESIZE and cell
%    spacing less than 1.

c = p.groups{g};

if ~strcmp(p.groups{c.pg}.type, 'input')
    error('g=%u: previous group must be type "input"', g);
end

zs = numel(m.layers) + (1 : c.numScales);

[m, p] = cns_super(m, g, p, zs);
c = p.groups{g};

if ~isfield(c, 'baseScale'), c.baseScale = 1; end
bs = c.baseScale;
m.groups{g}.baseScale = bs;

for i = 1 : numel(zs)

    z = zs(i);

    m.layers{z}.pzs = m.groups{c.pg}.zs;

    m.layers{z}.size{1} = 1;
    m = cns_mapdim(m, z, 2, 'scaledpixels', c.baseSize(1), c.scaleFactor ^ (i - bs), [-0.5 0.5] * c.baseSize(1));
    m = cns_mapdim(m, z, 3, 'scaledpixels', c.baseSize(2), c.scaleFactor ^ (i - bs), [-0.5 0.5] * c.baseSize(2));

end

end

%-----------------------------------------------------------------------------------------------------------------------

function f = CNSFields

% Defines CNS fields specific to this cell type.

% Note: hmax.LoadImage automatically sets both these fields for you when you load a new input image.

f.py_count = {'gp', 'private', 'int', 'dflt', cns_intmax}; % Actual height of the input image in pixels.
f.px_count = {'gp', 'private', 'int', 'dflt', cns_intmax}; % Actual width of the input image in pixels.

end

%-----------------------------------------------------------------------------------------------------------------------

end
end