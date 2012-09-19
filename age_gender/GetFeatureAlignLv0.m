function [feat] = GetFeatureAlignLv0(image, det, opts)
% level 0 alignment, using detection boxes
% config alignment
target_size = [80,80];
target_land_mark = complex([1, target_size(2)], [1, target_size(1)]);
target_scale = abs(target_land_mark(1) - target_land_mark(2));
    
land_mark = complex(det.det(1, [1,4])+1, ...
    det.det(2, [1,4])+1);

if size(image,3) == 1
    image = repmat(image, [1,1,3]);
end

scale = abs(land_mark(1) - land_mark(2));
image = imresize(image, target_scale/scale);
land_mark = (land_mark - complex(1, 1))*target_scale/scale + 1;
face = WarpPositive(image, [], land_mark, target_land_mark, target_size);
        
if size(face, 3) == 3
    face = rgb2gray(face);
end
feat = ExtractFeature(face, opts);

for i = 1:length(feat)
    if length(size(feat{i})) == 3
        feat{i} =reshape(feat{i}, [size(feat{i},1), size(feat{i},2)*size(feat{i},3)]);
    end
end
feat = cell2mat(feat);
feat = bsxfun(@rdivide, feat, sqrt(sum(feat.^2,1))+eps);
feat = feat(:)/(sqrt(sum(feat(:).^2))+eps);