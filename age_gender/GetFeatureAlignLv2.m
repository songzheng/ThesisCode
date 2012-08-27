function [feat] = GetFeatureAlignLv2(dataset, target_size, opts)
% level 3 alignment, using face alignment

% introduce larger face area to include all alignment landmarks
target_size = target_size * 2;
target_land_mark = complex([target_size(2)/8*3, target_size(2)/8*5], [target_size(1)/8*3, target_size(1)/8*3]);
target_scale = abs(target_land_mark(1) - target_land_mark(2));
land_mark_id = [1,2];

% mesh
npoints = 87;
ex_contour = complex(zeros(1, npoints), zeros(1,npoints));
ex_mesh = GetFaceMesh(ex_contour);

f = opts.func_feat(zeros(target_size, 'uint8'), opts, ex_mesh);
fdim = length(f);
feat = zeros(length(dataset.image_names), fdim + npoints*2, 'single');

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
    
    contour = complex(dataset.OMRONFaceDetection(i).contour(1, :)+1,...
        dataset.OMRONFaceDetection(i).contour(2, :)+1);
    land_mark = complex(part(1, land_mark_id)+1, ...
        part(2, land_mark_id)+1);
    
    image = imread([dataset.data_root, '/', dataset.image_names{i}]);
    
    if size(image,3) == 1
        image = repmat(image, [1,1,3]);
    end
    
    scale = abs(land_mark(1) - land_mark(2));
    image = imresize(image, target_scale/scale);
    land_mark = (land_mark - complex(1, 1))*target_scale/scale + 1;
    contour = (contour - complex(1, 1))*target_scale/scale + 1;
        
    [face, contour] = WarpPositive(image, contour, land_mark, target_land_mark, target_size);
    face_mesh = GetFaceMesh(contour);
    
    mean_face = mean_face + double(rgb2gray(face));
    
    if size(face,1)~=target_size(1) || size(face,2)~=target_size(2)
        face=imresize(face,target_size);
    end
    
    if size(face, 3) == 3
        face = rgb2gray(face);
    end
    
    feat(i,1:fdim) = opts.func_feat(face, opts, face_mesh);
    
    %         + opts.func_feat(face(:, end:-1:1), opts);
    feat(i,1:fdim) = feat(i,1:fdim)/sqrt(sum(feat(i,1:fdim).^2)+eps);
    contour = contour - mean(target_land_mark);
    norm_contour = sqrt(sum(real(contour).^2) + sum(imag(contour).^2) + eps);
    feat(i,fdim+1:end) = [real(contour)/norm_contour, imag(contour)/norm_contour];
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