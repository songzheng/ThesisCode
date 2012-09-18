function opt = InitializeFeature(name, varargin)

opt = struct(varargin{:});
opt.type = name(1:5);
opt.name = name;

if ~(strcmp(opt.type, 'Patch') || strcmp(opt.type, 'Pixel'))
    error('Feature must be from patches or pixels');
end

if strcmp(opt.type, 'Patch')
    if exist(['patch_feature_', name(6:end)], 'file') == 3
        opt.func_feat = str2func(['patch_feature_', name(6:end)]);
    else
        opt.func_feat = @patch_feature_mex;
    end
end

if strcmp(opt.type, 'Pixel')
    if exist(['patch_feature_', name(6:end)], 'file') == 3
        opt.func_feat = str2func(['pixel_feature_', name(6:end)]);
    else
        opt.func_feat = @pixel_feature_mex;
    end
end

switch name
    case 'PatchHOG'        
        pixel_opt = InitializeFeature('PixelGray4N', varargin{:});        
        pixel_coding_opt = InitializeCoding('CodingPixelHOG', pixel_opt, varargin{:});
        opt.length = pixel_coding_opt.length;
        opt.image_depth = pixel_opt.image_depth;
        
        opt.pixel_opt = pixel_opt;
        opt.pixel_coding_opt = pixel_coding_opt;        
        
        % patch size
        if ~isfield(opt, 'sbin') 
            opt.sbin = 8;
        end
        
        opt.size_x = opt.sbin; 
        opt.size_y = opt.sbin;         
        
    case 'PatchAppearance'
        pixel_opt = InitializeFeature('PixelGray4x4', varargin{:});  
        pixel_coding_opt = InitializeCoding('CodingVectorQuantization', pixel_opt, varargin{:});    
        opt.length = pixel_coding_opt.length;
        opt.image_depth = pixel_opt.image_depth;
        opt.pixel_opt = pixel_opt;
        opt.pixel_coding_opt = pixel_coding_opt;        
        
        % patch size
        if ~isfield(opt, 'sbin') 
            opt.sbin = 8;
        end
        
        opt.size_x = opt.sbin; 
        opt.size_y = opt.sbin;         
        
%         feats = pixel_coding_opt.func_decode(pixel_coding_opt.VQCodebook);
%         visual = pixel_opt.func_visualize(feats);
        
    case 'PixelGray4N'
        opt.length = 5;
        opt.image_depth = 1;
                
    case 'PixelGray4x4'
        opt.length = 16;
        opt.image_depth = 1;
        opt.func_visualize = @VisualizePixelGray4x4;        
        
    case 'PixelGray4x4Rot'
        opt.length = 18;
        opt.image_depth = 1;
        opt.func_visualize = @VisualizePixelGray4x4Rot;
        
    case 'PixelGray4x4DCT'
        opt.length = 16;
        opt.image_depth = 1;
        opt.func_visualize = @VisualizePixelGray4x4DCT;
        
    otherwise
        error('Unsupport Feature');
end    

if ~isfield(opt, 'scales')
    opt.scales = 1;
end

function image = VisualizePixelGray4x4DCT(feats)
for i = 1:size(feats,2)
    tmp = reshape(feats(:,i), [4,4]);
    tmp = idct2(tmp);
    feats(:, i) = tmp(:);
end
feats = sortrows(feats')';
image = cell(1, size(feats,2));
for i = 1:size(feats,2)    
    image{i} = reshape(feats(:,i), [4,4]);
end


function image = VisualizePixelGray4x4(feats)
% feats = sortrows(feats')';
image = cell(1, size(feats,2));
for i = 1:size(feats,2)
    image{i} = reshape(feats(:,i), [4,4]);
end
