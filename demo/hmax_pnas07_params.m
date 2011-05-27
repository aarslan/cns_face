function [p, g] = hmax_pnas07_params(q)

% P = hmax_pnas07_params(Q) returns a parameter set defining the model used in
% [Serre et al. 2007].  Pass this parameter set to hmax.Model (as illustrated
% in hmax_pnas07_run_simple) to generate the corresponding CNS model structure.
%
%    Q.bufSize - Size of buffer for storing images (before scaling).  Larger
%    images will be shrunk using imresize.
%
%    Q.baseSize - Size of the initial image pyramid (after scaling) at the most
%    detailed scale.  This affects the size of all later stages.
%
%    Q.numScales - Number of scales in the initial image pyramid.
%
% The parameters needed to define each stage depend on the cell type, and are
% determined by that cell type's ".m" file.
%
% See also: hmax.Model, hmax_pnas07_run_simple.

%-----------------------------------------------------------------------------------------------------------------------

if nargin < 1
    q.bufSize   = [512 512];
    q.baseSize  = [256 256];
    q.numScales = 10;
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
c.fParams = {'gabor', 0.3, 3.5, 2.8};

p.groups{end + 1} = c;
g.s1 = numel(p.groups);

%-----------------------------------------------------------------------------------------------------------------------

c = struct;
c.name    = 'c1';
c.type    = 'cMax';
c.pg      = g.s1;
c.sCount  = 2;
c.sStep   = 1;
c.rfCount = 8;
c.rfStep  = 3;

p.groups{end + 1} = c;
g.c1 = numel(p.groups);

%-----------------------------------------------------------------------------------------------------------------------

c = struct;
c.name    = 's2b';
c.type    = 'ssGRBFNorm';
c.pg      = g.c1;
c.rfCount = [5 : 2 : 15];
c.rfStep  = 1;
c.sigma   = 1/3;

p.groups{end + 1} = c;
g.s2b = numel(p.groups);

%-----------------------------------------------------------------------------------------------------------------------

c = struct;
c.name    = 'c2b';
c.type    = 'cMax';
c.pg      = g.s2b;
c.sCount  = inf;
c.rfCount = inf;

p.groups{end + 1} = c;
g.c2b = numel(p.groups);

%-----------------------------------------------------------------------------------------------------------------------

c = struct;
c.name    = 's2';
c.type    = 'ssGRBFNorm';
c.pg      = g.c1;
c.rfCount = [3];
c.rfStep  = 1;
c.sigma   = 1/3;

p.groups{end + 1} = c;
g.s2 = numel(p.groups);

%-----------------------------------------------------------------------------------------------------------------------

c = struct;
c.name    = 'c2';
c.type    = 'cMax';
c.pg      = g.s2;
c.sCount  = 2;
c.sStep   = 1;
c.rfCount = 8;
c.rfStep  = 3;

p.groups{end + 1} = c;
g.c2 = numel(p.groups);

%-----------------------------------------------------------------------------------------------------------------------

c = struct;
c.name    = 's3';
c.type    = 'ssGRBFNorm';
c.pg      = g.c2;
c.rfCount = [3];
c.rfStep  = 1;
c.sigma   = 1/3;

p.groups{end + 1} = c;
g.s3 = numel(p.groups);

%-----------------------------------------------------------------------------------------------------------------------

c = struct;
c.name    = 'c3';
c.type    = 'cMax';
c.pg      = g.s3;
c.sCount  = inf;
c.rfCount = inf;

p.groups{end + 1} = c;
g.c3 = numel(p.groups);

%-----------------------------------------------------------------------------------------------------------------------

p.quiet = true;

return;