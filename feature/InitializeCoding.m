function opt = InitializeCoding(name, feat_opt, varargin)
opt = struct(varargin{:});
opt.name = name;
switch name
    case 'CodingPixelHOG'
        assert(strcmp(feat_opt.name, 'PixelGray4N'));
        opt.param = [0,0];
        
        % sphere or half sphere
        if isfield(opt, 'half_sphere') && opt.half_sphere == 1
            opt.param(2) = pi;
        else
            opt.half_sphere = 0;
            opt.param(2) = 2*pi;
        end
        
        % hog orientation
        if isfield(opt, 'norient')
            opt.param(1) = opt.norient;
        else
            if opt.half_sphere == 1
                opt.param(1) = 8;
            else
                opt.param(1) = 16;
            end
        end
        % length
        opt.length = opt.norient;
        opt.input_length = 5;
        
        
    case 'CodingVectorQuantization'
        codebook_dir = [fileparts(mfilename('fullpath')), '/codebook'];
        if ~isfield(opt, 'codebook_name')
            error('Unspecified codebook name');
        end
                
        if ~isfield(opt, 'codebook_size') || isempty(opt.codebook_size)            
            gt_fea_dim = [20,40,56,128];
            gt_codebook_size = [500,1000,2000,4000];
            
            p = polyfit(gt_fea_dim,gt_codebook_size,2);
            
            opt.codebook_size = max(500,floor(polyval(p,feat_opt.length)/500)*500);
        end
        
        if isfield(opt, 'reduced_dim') && ~isempty(opt.reduced_dim)
            codebook_file = [codebook_dir, '\', ...
                'VQ_', opt.codebook_name, '_', feat_opt.name, ...
                '_', num2str(opt.reduced_dim) '_', num2str(opt.codebook_size)];
        else
            codebook_file = [codebook_dir, '\', ...
                'VQ_', opt.codebook_name, '_', feat_opt.name, ...
                '_ori_', num2str(opt.codebook_size)];
        end
        
        if isfield(opt, 'rot_aware') && opt.rot_aware
            codebook_file = [codebook_file, '_rot'];
            opt.param(1) = 8;
        else
            opt.param(1) = -1;
        end
        
        if exist([codebook_file, '.mat'], 'file')
            load(codebook_file);
        else            
            if ~isfield(opt, 'dataset')
                error('Training data required');
            end
            
            fprintf('No codebook found, Training...\n');            
            codebook = TrainCodebook(opt.dataset, feat_opt, opt);
            save(codebook_file, 'codebook');
        end
        
        opt.vq_codebook = codebook;
        opt.func_decode = @DecodingVQCodebook;
        
        % length
        opt.input_length = feat_opt.length;
        opt.length = opt.codebook_size;
        
    otherwise
        error('Unsupport pixel coding method');
end


function feats = DecodingVQCodebook(codebook)
if isfield(codebook, 'nReducedDim') && codebook.nReducedDim > 0
    feats = codebook.projection * codebook.base;
else
    feats = codebook.base;
end
    

