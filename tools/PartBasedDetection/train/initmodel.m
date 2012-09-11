function model = initmodel(cls, pos, note, symmetry, sbin, sz)

% model = initmodel(cls, pos, note, symmetry, sbin, sz)
% Initialize model structure.
%
% If not supplied the dimensions of the model template are computed
% from statistics in the postive examples.

% model.
%       filters: data struct of filters
%           .flip: whether a flipped filter of another filter
%           .symmetric: 'N' or 'M', whether a symmetric filter (no need to flip)
%           .blocklabel: block label writing to .dat and .mod file
%           .symbol: correspond "symbol" struct index
%       symbol: parameter struct for filters
%           .filter: correspond filter index
%           .type: 'N' or 'T' for Nonterminal or Terminal, 'T' indicates
%           start of the model filter chain, i.e. the filter convolution of
%           shape model.
%           .i: index of this symbol, don't know why has this element
%       rules{symbol_index}(rule_index): detect entry, includes offsets and
%       deformation models
%           symbol_index: correspond symbol
%           rule_index: 
%           .type: 'S' or 'D' for shape model and deformation model
%           .detwindow: detect window size (in sbins)
%           .offset: offset filter
%           .lhs/rhs: correspond left/right-hand-side symbol
%                   rules always return maximum score of lhs and rhs,
%                   detections start from lhs, but rhs symbol links to read
%                   filter
%           .anchor: for 'S' type only
%           .def: deformation block, for 'D' type only

% pick mode of aspect ratios
h = [pos(:).y2]' - [pos(:).y1]' + 1;
w = [pos(:).x2]' - [pos(:).x1]' + 1;
xx = -2:.02:2;
filter = exp(-[-100:100].^2/400);
aspects = hist(log(h./w), xx);
aspects = convn(aspects, filter, 'same');
[peak, I] = max(aspects);
aspect = exp(xx(I));

% pick 20 percentile area
areas = sort(h.*w);
area = areas(floor(length(areas) * 0.2));
area = max(min(area, 5000), 3000);

% pick dimensions
w = sqrt(area/aspect);
h = w*aspect;

if nargin < 3
  note = '';
end

% get an empty model
model = model_create(cls, note);
model.interval = 10;

if nargin < 4
  symmetry = 'N';
end

% size of HOG features
if nargin < 5
  model.sbin = 8;
else
  model.sbin = sbin;
end

% size of root filter
if nargin < 6
  sz = [round(h/model.sbin) round(w/model.sbin)];
end

% choose feature
name_feature = 'hoglbp';

switch name_feature
    case 'hog'
        dims=31;
        model.features=@features_hog;
        model.flipfeat=@flipfeat_hog;
    case 'hoglbp'
        dims=31+59;
        model.features=@features_hoglbp;
        model.flipfeat=@flipfeat_hoglbp;
    case 'color'
        dims = 24;
        model.features=@features_color;
        model.flipfeat=@flipfeat_color;
    case 'hoglbpcolor'
        dims=31+59+24;
        model.features=@features_hoglbpcolor;
        model.flipfeat=@flipfeat_hoglbpcolor;
        
    otherwise
        error('Unsuppored feature');
end

% add root filter
[model, symbol, filter] = model_addfilter(model, zeros([sz dims+1]), symmetry);

% start non-terminal symbol for empty symmetric filter
[model, Q] = model_addnonterminal(model);
% start from empty symbol
model.start = Q;

% add structure rule deriving only a root filter placement
model = model_addrule(model, 'S', Q, symbol, 0, {[0 0 0]});

% set detection window
model = model_setdetwindow(model, Q, 1, sz);
