function opt = FeatureInit(name, varargin)

args = struct(varargin{:});

switch name
    case 'HOG'        
        pixel_opt.name = 'PixelGray4N';
        pixel_opt.image_depth = 1;
        pixel_coding_opt.name = 'CodingPixelHOG';
        
        % hog orientation
        if isfield(args, 'norient')        
            pixel_coding_opt.param = args.norient; 
        else
            pixel_coding_opt.param = 16;
        end
        opt.length = args.norient;
        
        opt.name = 'HOG';
        opt.pixel_opt = pixel_opt;
        opt.pixel_coding_opt = pixel_coding_opt;
        
        
        % hog patch size
        if isfield(args, 'sbin') 
            sbin = args.sbin;
        else
            sbin = 8;
        end
        
        opt.size_x = sbin; 
        opt.size_y = sbin; 
        opt.func_feat = @ExtractFeature;
        
    otherwise
        error('Unsupport Feature');
end


if isfield(args, 'cell_size')
    opt.cell_size = args.cell_size;
    opt.length = opt.length * prod(opt.cell_size);
end
    