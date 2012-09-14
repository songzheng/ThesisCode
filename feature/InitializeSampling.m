function opt = InitSampling(varargin)

opt = struct(varargin{:});

if ~isfield(opt, 'format')
    opt.format = 'grids';
end

if ~isfield(opt, 'scales') || isempty(opt.scales)
    opt.scales = 1;
end