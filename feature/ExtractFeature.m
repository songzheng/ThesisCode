function [features_all, grids_all] = ExtractFeature(im, opt, sampling)

if opt.image_depth == 1 && size(im,3) == 3
    im = rgb2gray(im);
end

if ~exist('sampling', 'var') || isempty(sampling)
    sampling.format = 'grids';
end

scales = opt.scales;
features_all = cell(1, length(scales));
grids_all = cell(1, length(scales));

im_pyra = GetImagePyramid(im, scales);

for s = 1:length(scales)
    
    if strcmp(sampling.format, 'points')
        p = int32([imag(sampling.points)-1; real(sampling.points)-1] * scales(s));    
        feature = opt.func_feat(im_pyra{s}, opt, p);
        grids = [];
    elseif strcmp(sampling.format, 'grids')
        [feature, grids] = opt.func_feat(im_pyra{s}, opt);
        grids.step_x = grids.step_x/scales(s);
        grids.step_y = grids.step_y/scales(s);
    else
        error('Unsupport Sampling');
    end
                
    if strcmp(sampling.format, 'grids') 
        if isfield(sampling, 'cell_size')
            cell_size = opt.cell_size;
            
            feature_old = reshape(feature, [size(feature,1), grids.num_y, grids.num_x]);
            feature = zeros(prod(cell_size)*size(feature,1), grids.num_y-cell_size(1)+1, grids.num_x-cell_size(2)+1);
            
            grids.num_y = grids.num_y-cell_size(1)+1;
            grids.num_x = grids.num_x-cell_size(2)+1;
            
            istart = 0;
            for ix = 1:cell_size(2)
                for iy = 1:cell_size(1)
                    feature(istart+1:istart+size(feature_old,1), :, :) = feature_old(:, iy:iy+grids.num_y-1, ix:ix+grids.num_x-1);
                    istart = istart + size(feature_old,1);
                end
            end
        end
        feature = reshape(feature, [size(feature,1), grids.num_y, grids.num_x]);
    end        
    
    features_all{s} = feature;
    grids_all{s} = grids;
end
