classdef hmax_g < hmax_c

% Defines the "g" cell type.  This is a subtype of "c" in which the pooling
% range of a cell is restricted to a local region near the position and scale
% from which its particular feature was originally sampled.  This is described
% in section 2.3 of [Mutch & Lowe 2006] under the heading "limit position/scale
% invariance of S2 features".
%
% This is an abstract type; the particular pooling function is undefined (and
% left to subtypes).

methods (Static)

%-----------------------------------------------------------------------------------------------------------------------

function [m, p] = Construct(m, g, p)

% Called automatically by hmax.Model to add a "g" stage to the CNS model
% structure M.  A "g" stage has all the parameters of a "c" stage having rfType
% 'win'.  Additional user-specified parameters for "g" cells are as follows
% (where C = P.groups{G}):
%
%    C.sTol - scale tolerance per [Mutch & Lowe 2006].
%
%    C.yxTol - position tolerance per [Mutch & Lowe 2006].
%
% For a full-image recognition model (i.e. no localization), set C.sCount =
% C.yCount = C.xCount = inf.  The above tolerance parameters are relative to the
% entire image.
%
% For a sliding-window model, set C.sCount, C.yCount, C.xCount, and the other
% "c" cell 'win' parameters to describe the sliding window.  The above tolerance
% parameters will be relative to the sliding window.

c = p.groups{g};

c.rfType = 'win';

if (c.yCount < cns_intmax) ~= (c.xCount < cns_intmax)
    error('yCount and xCount must be both finite or both infinite');
end
if (c.yCount >= cns_intmax) && (c.sCount < cns_intmax)
    error('yCount and xCount cannot be infinite with sCount finite');
end

p.groups{g} = c;
[m, p] = cns_super(m, g, p);
c = p.groups{g};

if c.yCount >= cns_intmax
    % We want an actual window size even in this case.
    % We make the assumption that group 2 is the image pyramid.
    bz = m.groups{2}.zs(m.groups{2}.baseScale);
    pz = m.layers{m.groups{g}.zs(1)}.pzs(1);
    m.groups{g}.yCount = m.layers{bz}.size{2} / m.layers{pz}.y_space;
    m.groups{g}.xCount = m.layers{bz}.size{3} / m.layers{pz}.x_space;
end

m.groups{g}.sTol  = c.sTol;
m.groups{g}.yxTol = c.yxTol;

end

%-----------------------------------------------------------------------------------------------------------------------

function p = CNSProps

p.abstract = true;

end

%-----------------------------------------------------------------------------------------------------------------------

function f = CNSFields

% Defines CNS fields specific to this cell type.

f.sTol  = {'gp', 'private', 'int'}; % Scale tolerance per [Mutch & Lowe 2006].
f.yxTol = {'gp', 'private'};        % Position tolerance per [Mutch & Lowe 2006].

f.fSPos = {'ga', 'private', 'dims', {1}, 'dparts', {1}, 'dnames', {'f'}, 'ind'}; % Scale sample positions.
f.fYPos = {'ga', 'private', 'dims', {1}, 'dparts', {1}, 'dnames', {'f'}};        % Y sample positions.
f.fXPos = {'ga', 'private', 'dims', {1}, 'dparts', {1}, 'dnames', {'f'}};        % X sample positions.

end

%-----------------------------------------------------------------------------------------------------------------------

function [m, lib] = AddDict(m, g, p, lib)

% Called automatically for "g" stages by hmax.Model.  Adds dictionary
% information to the CNS model structure.

[m, lib] = cns_super(m, g, p, lib);
c = p  .groups{g};
d = lib.groups{c.pg};

% Grab the feature sample position information from the previous group's dictionary.
m.groups{g}.fSPos = d.fSPos(:);
m.groups{g}.fYPos = d.fYPos(:);
m.groups{g}.fXPos = d.fXPos(:);

end

%-----------------------------------------------------------------------------------------------------------------------

end
end