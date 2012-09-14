function [features_all, points_all] = ExtractPatchFeaturePoints(im, opt, points)

if ~exist('points', 'var')
    points = [];
end


% if opt.pixel_opt.image_depth == 1
%     im = rgb2gray(im);
% end

scales = opt.scales;
features_all = cell(1, length(scales));
points_all = cell(1, length(scales));

for s = 1:length(scales)
    if ~isempty(points)
        p = int32([imag(points)-1; real(points)-1] * scales(s));
        feature = patch_feature(imresize(im, scales(s)), p, opt);
    else
        p = [];
        [feature, grids] = patch_feature(imresize(im, scales(s)), p, opt);
    end
    
    feature = bsxfun(@rdivide, feature, sqrt(sum(feature.^2))+eps);
    
    if isempty(points)
        if isfield(opt, 'cell_size')
            cell_size = opt.cell_size;
        else
            cell_size = [1,1];
        end
        
        [px, py] = meshgrid(grids.start_x + (0:(grids.num_x-cell_size(2)))*grids.step_x + (cell_size(2)-1)/2*grids.step_x, ...
            grids.start_y + (0:(grids.num_y-cell_size(1)))*grids.step_y + (cell_size(1)-1)/2*grids.step_y);
        p = complex(px(:)'+1, py(:)'+1);        
    end
    
    features_all{s} = feature(:)';
    points_all{s} = p;
end

features_all = cell2mat(features_all);
points_all = cell2mat(points_all);