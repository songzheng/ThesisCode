function [feat_raw, box_index] = ExtractFeatureRaw(img, box, feat_opt)
feat_funcs = feat_opt.feat_funcs;
[heigth width depth]=size(img);
% assert(depth == 3);
if depth == 1
    img = repmat(img, [1,1,3]);
end

nparts = floor(size(box,2)/5);
box = box(1, 1:5*nparts);
box = reshape(box, [5, nparts]);

box = round(box);
box(1,:) = max(1,box(1,:));
box(2,:) = max(1,box(2,:));
box(3,:) = min(box(3,:), width);
box(4,:) = min(box(4,:), heigth);
% extract raw feature
feat_raw = [];
box_index = cell(5, size(box, 2));
for i = 1:size(box,2)
    temp_box = box(:,i);
    subimg = img(temp_box(2):temp_box(4),temp_box(1):temp_box(3),:);
    subimg = imresize(subimg,feat_opt.win_size);
    for f = 1:length(feat_funcs)
        i1 = length(feat_raw) + 1;
        feat = feat_funcs{f}(subimg, feat_opt);
        feat_raw = [feat_raw, feat(:)'];
        i2 = length(feat_raw);
        box_index{f,i} = i1:i2;
    end  
end