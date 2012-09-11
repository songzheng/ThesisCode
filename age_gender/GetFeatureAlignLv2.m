function [feat] = GetFeatureAlignLv2(dataset, target_size, opts)
% level 3 alignment, using face alignment
OKAO_flip = [17,16,18,19,22,23,20,21,...
    25,24,26,27,30,31,28,29,...
    1,0,2,3,6,7,4,5,...
    9,8,10,11,14,15,12,13,...
    33,32,34,37,38,35,36,39,42,43,40,41,...
    45,44,46,47,48,49,54,55,56,57,50,51,52,53,62,63,64,65,58,59,60,61,...
    86:-1:66] + 1;
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
feat = zeros(fdim + npoints*2, length(dataset.image_names), 'single');

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
    
    if size(face,1)~=target_size(1) || size(face,2)~=target_size(2)
        error('Warp Failed');
    end
    
    lr_rot = dataset.OMRONFaceDetection(i).rotation(2);
    if lr_rot < 0
        face = face(:, end:-1:1, end);
        contour = complex(size(face,2)-real(contour)+1, imag(contour));
        contour = contour(OKAO_flip);
    end
    
    face_mesh = GetFaceMesh(contour);
            
    if size(face, 3) == 3
        face = rgb2gray(face);
    end
        
    mean_face = mean_face + double(face);
    
    ftmp = opts.func_feat(face, opts, face_mesh);
    ftmp = ftmp(:)/(sqrt(sum(ftmp.^2))+eps);
    contour = contour - mean(target_land_mark);
    norm_contour = sqrt(sum(real(contour).^2) + sum(imag(contour).^2) + eps);
    
    feat(:, i) = [ftmp; real(contour)'/norm_contour; imag(contour)'/norm_contour];
    nface = nface + 1;
end
fprintf('\n');
mean_face = mean_face/nface;
figure(1);
clf;
imshow(uint8(mean_face));
hold on;
plot(target_land_mark, 'ro');
drawnow;

fprintf('%d out of %d faces\n', nface, length(dataset.image_names));