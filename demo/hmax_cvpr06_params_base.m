function [p, g] = hmax_cvpr06_params_base(q)

% P = hmax_cvpr06_params_base(Q) returns a parameter set defining the "base"
% model used in [Mutch & Lowe 2006].  Pass this parameter set to hmax.Model (as
% illustrated in hmax_cvpr06_run_simple) to generate the corresponding CNS
% model structure.
%
%    Q.bufSize - Size of buffer for storing images (before scaling).  Larger
%    images will be shrunk using imresize.
%
%    Q.baseSize - Size of the initial image pyramid (after scaling) at the most
%    detailed scale.  This affects the size of all later stages.
%
%    Q.numScales - Number of scales in the initial image pyramid.
%
% The parameters needed to define each stage depend on the cell type; see each
% cell type's ".m" file for a description of its parameters.
%
% See also: hmax.Model, hmax_cvpr06_run_simple.

%-----------------------------------------------------------------------------------------------------------------------

if nargin < 1
    q.bufSize   = [400 600];
    q.baseSize  = [140 140];
    q.numScales = 9;
    q.baseScale = 1;
elseif ~isfield(q, 'baseScale')
    q.baseScale = 1;
end

p.groups = {};

%-----------------------------------------------------------------------------------------------------------------------

c = struct;
c.name = 'input';
c.type = 'input';
c.size = q.bufSize;

p.groups{end + 1} = c;
g.input = numel(p.groups);

%-----------------------------------------------------------------------------------------------------------------------

c = struct;
c.name        = 'scale';
c.type        = 'scale';
c.pg          = g.input;
c.baseSize    = q.baseSize;
c.scaleFactor = 2 ^ (1/4);
c.numScales   = q.numScales;
c.baseScale   = q.baseScale;

p.groups{end + 1} = c;
g.scale = numel(p.groups);

%-----------------------------------------------------------------------------------------------------------------------

c = struct;
c.name    = 's1';
c.type    = 'sdNDP';
c.pg      = g.scale;
c.rfCount = 11;
c.rfStep  = 1;
c.zero    = [1 0];
c.thres   = 0;
c.abs     = 1;
c.fCount  = 4;
c.fParams = {'gabor', 0.3, 5.6410, 4.5128};

p.groups{end + 1} = c;
g.s1 = numel(p.groups);

%-----------------------------------------------------------------------------------------------------------------------

c = struct;
c.name    = 'c1';
c.type    = 'cMax';
c.pg      = g.s1;
c.sCount  = 2;
c.sStep   = 1;
c.rfCount = 10;
c.rfStep  = 5;

p.groups{end + 1} = c;
g.c1 = numel(p.groups);

%-----------------------------------------------------------------------------------------------------------------------

c = struct;
c.name    = 's2';
c.type    = 'sdGRBF';
c.pg      = g.c1;
c.rfCount = [4 8 12 16];
c.rfStep  = 1;
c.sigma   = 1;

p.groups{end + 1} = c;
g.s2 = numel(p.groups);

%-----------------------------------------------------------------------------------------------------------------------

c = struct;
c.name    = 'c2';
c.type    = 'cMax';
c.pg      = g.s2;
c.sCount  = inf;
c.rfCount = inf;

p.groups{end + 1} = c;
g.c2 = numel(p.groups);

%-----------------------------------------------------------------------------------------------------------------------

p.quiet = true;

return;