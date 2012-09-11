function [feat] = GetFeatureAlignLv0(dataset, target_size, opts)
% level 0 alignment, using detection boxes

% config alignment
target_land_mark = complex([1, target_size(2)], [1, target_size(1)]);
target_scale = abs(target_land_mark(1) - target_land_mark(2));

f = opts.func_feat(zeros(target_size, 'uint8'), opts);
fdim = length(f);
feat = zeros(fdim, length(dataset.image_names), 'single');

mean_face = zeros(target_size);
nface = 0;
for i = 1:length(dataset.image_names)
    if mod(i,round(length(dataset.image_names)/100))==0
        fprintf('%%%d.',round(i*100/length(dataset.image_names)));
    end
        
    det = dataset.OMRONFaceDetection(i).det;
    if isempty(det)
        continue;
    end
    
    land_mark = complex(det(1, [1,4])+1, ...
        det(2, [1,4])+1);
    
    image = imread([dataset.data_root, '/', dataset.image_names{i}]);
    
    if size(image,3) == 1
        image = repmat(image, [1,1,3]);
    end
    
    scale = abs(land_mark(1) - land_mark(2));
    image = imresize(image, target_scale/scale);
    land_mark2 = (land_mark - complex(1, 1))*target_scale/scale + 1;
    face = WarpPositive(image, [], land_mark2, target_land_mark, target_size);
    mean_face = mean_face + double(rgb2gray(face));
    
    if size(face,1)~=target_size(1) || size(face,2)~=target_size(2)
        face=imresize(face,target_size);
    end
    
    if size(face, 3) == 3
        face = rgb2gray(face);
    end
    
    ftmp = opts.func_feat(face, opts);
    feat(:, i) = ftmp(:);
    
    %         + opts.func_feat(face(:, end:-1:1), opts);
    %         feat(i,:) = feat(i,:)/sqrt(sum(feat(i,:).^2)+eps);
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