function [feat] = GetFeatureAlignLv1(dataset, target_size, opts)
% level 1 alignment, using eye centers

% config alignment
target_land_mark = complex([target_size(2)/4, target_size(2)/4*3], [target_size(1)/4, target_size(1)/4]);
target_scale = abs(target_land_mark(1) - target_land_mark(2));
land_mark_id = [1,2];

f = opts.func_feat(zeros(target_size, 'uint8'), opts);
fdim = length(f);
feat = zeros(length(dataset.image_names), fdim, 'single');

mean_face = zeros(target_size);
nface = 0;
for i = 1:length(dataset.image_names)
    if mod(i,round(length(dataset.image_names)/100))==0
        fprintf('%%%d.',round(i*100/length(dataset.image_names)));
    end
        
    part = dataset.OMRONFaceDetection(i).part;
    if isempty(part)
        continue;
    end
    
    land_mark = complex(part(1, land_mark_id)+1, ...
        part(2, land_mark_id)+1);
    
    image = imread([dataset.data_root, '/', dataset.image_names{i}]);
    
    if size(image,3) == 1
        image = repmat(image, [1,1,3]);
    end
    
    scale = abs(land_mark(1) - land_mark(2));
    image = imresize(image, target_scale/scale);
    land_mark = (land_mark - complex(1, 1))*target_scale/scale + 1;
    face = WarpPositive(image, [], land_mark, target_land_mark, target_size);
    mean_face = mean_face + double(rgb2gray(face));
    
    if size(face,1)~=target_size(1) || size(face,2)~=target_size(2)
        face=imresize(face,target_size);
    end
    
    if size(face, 3) == 3
        face = rgb2gray(face);
    end
    
    feat(i,:) = opts.func_feat(face, opts)  ...  
            + opts.func_feat(face(:, end:-1:1), opts);
    
    feat(i,:) = feat(i,:)/sqrt(sum(feat(i,:).^2)+eps);
    nface = nface + 1;
end
fprintf('\n');
mean_face = mean_face/nface;
figure(1);
imshow(uint8(mean_face));
hold on;
plot(target_land_mark, 'ro');
drawnow;

fprintf('%d out of %d faces\n', nface, length(dataset.image_names));



