function [p, g] = hmax_cvpr06_params_full(q)

% P = hmax_cvpr06_params_full(Q) returns a parameter set defining the "full"
% model used in [Mutch & Lowe 2006].  Similar to hmax_cvpr06_params_base; see
% that function for more detail.
%
% See also: hmax_cvpr06_params_base.

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
c.name    = 's1_orig';
c.type    = 'sdNDP';
c.pg      = g.scale;
c.rfCount = 11;
c.rfStep  = 1;
c.zero    = [1 0];
c.thres   = 0;
c.abs     = 1;
c.fCount  = 12;
c.fParams = {'gabor', 0.3, 5.6410, 4.5128};

p.groups{end + 1} = c;
g.s1_orig = numel(p.groups);

c = struct;
c.name    = 's1_thres';
c.type    = 'inhib1';
c.pg      = g.s1_orig;
c.inhibit = 0.5;

p.groups{end + 1} = c;
g.s1_thres = numel(p.groups);

c = struct;
c.name = 's1';
c.type = 'inhib2';
c.pg   = g.s1_orig;
c.ig   = g.s1_thres;

p.groups{end + 1} = c;
g.s1 = numel(p.groups);

%-----------------------------------------------------------------------------------------------------------------------

c = struct;
c.name    = 'c1_orig';
c.type    = 'cMax';
c.pg      = g.s1;
c.sCount  = 2;
c.sStep   = 1;
c.rfCount = 10;
c.rfStep  = 5;

p.groups{end + 1} = c;
g.c1_orig = numel(p.groups);

c = struct;
c.name    = 'c1_thres';
c.type    = 'inhib1';
c.pg      = g.c1_orig;
c.inhibit = 0.5;

p.groups{end + 1} = c;
g.c1_thres = numel(p.groups);

c = struct;
c.name = 'c1';
c.type = 'inhib2';
c.pg   = g.c1_orig;
c.ig   = g.c1_thres;

p.groups{end + 1} = c;
g.c1 = numel(p.groups);

%-----------------------------------------------------------------------------------------------------------------------

c = struct;
c.name    = 's2';
c.type    = 'ssGRBF';
c.pg      = g.c1;
c.rfCount = [4 8 12 16];
c.rfStep  = 1;
c.sigma   = 1;

p.groups{end + 1} = c;
g.s2 = numel(p.groups);

%-----------------------------------------------------------------------------------------------------------------------

c = struct;
c.name   = 'c2';
c.type   = 'gMax';
c.pg     = g.s2;
c.sTol   = 1;
c.yxTol  = 0.0575;
c.sCount = inf;
c.yCount = inf;
c.xCount = inf;

p.groups{end + 1} = c;
g.c2 = numel(p.groups);

%-----------------------------------------------------------------------------------------------------------------------

p.quiet = true;

return;