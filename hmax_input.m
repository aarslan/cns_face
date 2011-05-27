classdef hmax_input < hmax_base

% Defines the "input" cell type.  An "input" layer just holds an input image
% without computing anything.
%
% Note: use the hmax.LoadImage method, not cns('set'), to load an image into the
% input layer.

methods (Static)

%-----------------------------------------------------------------------------------------------------------------------

function [m, p] = Construct(m, g, p)

% Called automatically by hmax.Model to add an "input" layer to the CNS model
% structure M.  (The input layer must be the first layer.)  User-specified
% parameters specific to "input" layers are as follows (where C = P.groups{G}):
%
%    C.size - a two element vector specifying the (y, x) size of the input
%    layer.  Note that the input layer is just a memory buffer.  It is not the
%    base of the image pyramid from which the simplest HMAX features are
%    computed.  The image pyramid is produced from the input layer via a
%    subsequent "scale" stage.  Thus, the size of the input layer does not
%    affect the rest of the HMAX computation.  Make the input layer big enough
%    to hold all, or most, of your images without resizing.  If the occasional
%    image is larger, that's ok: hmax.LoadImage will downsize such images for
%    you on the CPU side before copying them into the input layer on the GPU.

z = numel(m.layers) + 1;

[m, p] = cns_super(m, g, p, z);
c = p.groups{g};

m.layers{z}.pzs = [];

m.layers{z}.size{1} = 1;
m = cns_mapdim(m, z, 2, 'pixels', c.size(1), [-0.5 0.5] * c.size(1));
m = cns_mapdim(m, z, 3, 'pixels', c.size(2), [-0.5 0.5] * c.size(2));

end

%-----------------------------------------------------------------------------------------------------------------------

end
end