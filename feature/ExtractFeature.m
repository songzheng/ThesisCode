function [feature, points] = ExtractFeature(im, opt, points)

if ~exist('points', 'var')
    points = [];
end

if ~isempty(points)
    points = int32([imag(points)-1; real(points)-1]);
end

% if opt.pixel_opt.image_depth == 1
%     im = rgb2gray(im);
% end

[feature, grids] = patch_feature(im, points, opt);
feature = bsxfun(@rdivide, feature, sqrt(sum(feature.^2))+eps);

if isempty(points)
    if isfield(opt, 'cell_size')
        cell_size = opt.cell_size;
    else
        cell_size = [1,1];
    end
    
    [px, py] = meshgrid(grids.start_x + (0:(grids.num_x-cell_size(2)))*grids.step_x + (cell_size(2)-1)/2*grids.step_x, ...
        grids.start_y + (0:(grids.num_y-cell_size(1)))*grids.step_y + (cell_size(1)-1)/2*grids.step_y);
    points = complex(px(:)'+1, py(:)'+1);
    
    if any(cell_size > 1)
        feature_tmp = reshape(feature, [size(feature,1), grids.num_y, grids.num_x]);
        feature = zeros(prod(cell_size)*size(feature,1), grids.num_y-cell_size(1)+1, grids.num_x-cell_size(2)+1);
        
        istart = 0;
        for ix = 1:cell_size(2)
            for iy = 1:cell_size(1)
                feature(istart+1:istart+size(feature_tmp,1), :, :) = feature_tmp(:, iy:iy+grids.num_y-cell_size(1), ix:ix+grids.num_x-cell_size(2));
                istart = istart + size(feature_tmp,1);
            end
        end
        
%         feature = reshape(feature, [size(feature,1), size(feature,2)*size(feature,3)]);
    end
   
    feature = feature(:)';
end