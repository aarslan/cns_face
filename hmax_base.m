classdef hmax_base < cns_base

% Contains definitions shared by all cell types.

methods (Static)

%-----------------------------------------------------------------------------------------------------------------------

function [m, p] = Construct(m, g, p, zs)

% Called automatically for each stage (group) by hmax.Model.  The Construct
% method is analogous to a constructor: its job is to add a CNS group, and its
% constituent layers, to the model structure M.  The CNS group will represent
% one stage of an HMAX model, with each layer representing one scale of that
% stage.
%
% Cell types must supply their own versions of this method, which must first
% call the parent type's version (via the cns_super function).
%
%    P.groups{G} - A struct containing parameters that define this stage
%    (group).  Most parameters are specific to a cell type, and are documented
%    in the Construct methods of those cell types.  However, the user must
%    specify the following parameters for every stage (where C = P.groups{G}):
%
%       C.name - the name of the stage (group).
%
%       C.type - the group's cell type.
%
%       C.pg - number of the previous group, from which this group is to be
%       computed.  (Omitted for the input stage.)
%
%    ZS - When the Construct method of an immediate child of the "base" type
%    calls cns_super, it must supply a vector of layer numbers to be created.
%    The base method (below) actually adds the group and layers to M.
%
% Note: P is also an output parameter, but only for convenience.  A group's
% Construct method might save something in P to be picked up by a subsequent
% group's Construct method.  However, changes to P do *not* propagate back to
% the caller of hmax.Model.

c = p.groups{g};

if ~isfield(c, 'pg'), c.pg = []; end

m.groups{g}.name = c.name;
m.groups{g}.type = c.type;
m.groups{g}.pg   = c.pg;
m.groups{g}.zs   = zs;

for i = 1 : numel(zs)
    m.layers{zs(i)}.name    = sprintf('%s_%u', c.name, i);
    m.layers{zs(i)}.type    = c.type;
    m.layers{zs(i)}.groupNo = g;
end

p.groups{g} = c;

end

%-----------------------------------------------------------------------------------------------------------------------

function p = CNSProps

% Defines CNS properties common to all cell types.

% These properties define the dimensionality of a layer.  Recall that we use one CNS layer to represent a single scale
% of a single stage.  Regardless of cell type, all layers are three dimensional.  A given cell within a layer is
% identified by its feature number (f) and its y and x indices.  The y and x dimensions of all layers are mapped to
% absolute retinal positions so that correspondences may be established between cells in different layers.

p.dims   = {[1 2] 1 2};
p.dparts = {[2 2] 1 1};
p.dnames = {'f' 'y' 'x'};
p.dmap   = [0 1 1];

% You cannot make cells of type "base".

p.abstract = true;

end

%-----------------------------------------------------------------------------------------------------------------------

function f = CNSFields

% Defines CNS fields common to all cell types.

% Previous layer number(s) used to compute this layer.
f.pzs = {'lz', 'mv', 'type', 'base'};

% Holds the output value of a cell.  Computed by the cell's kernel (except for the input layer).
f.val = {'cv', 'cache', 'dflt', 0};

end

%-----------------------------------------------------------------------------------------------------------------------

function [m, lib] = AddDict(m, g, p, lib)

% Called automatically for each stage (group) by hmax.Model.  Cell types that
% use dictionaries (eg. "s" cells) must override this method with one that does
% something.
%
% The "AddDict" method's job is to add dictionary information contained in
% LIB.groups{G} to the CNS model structure M.
%
%    P.groups{G} - Parameters that were used by the cell type's "Construct"
%    method to construct group G of the model.
%
%    LIB.groups{G} - The learned dictionary for group G.
%
% Note: LIB is also an output parameter, but only for convenience.  A group's
% AddDict method might save something in LIB to be picked up by a subsequent
% group's AddDict method.  However, changes to LIB do *not* propagate back to
% the caller of hmax.Model.

end

%-----------------------------------------------------------------------------------------------------------------------

function m = Init(m, g)

% Called automatically for each stage (group) by hmax.CNSInit.  Some cell types
% override this with a method that actually does something.

end

%-----------------------------------------------------------------------------------------------------------------------

end
end