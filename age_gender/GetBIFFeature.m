function [feat] = GetBIFFeature(dataset, target_size, target_land_mark)
addpath BIFfeature\

% config pooling window
patch_size = [4, 8];
opts.win_size = target_size;
opts.patch_size = patch_size;
opts.pooling = 'max';

% config imag preprocess
opts.histeq = 1;
opts.centersurround = 1;

% config feature
configfunc = @BIFMaxPoolInit;
opts.tag = 'BIFMaxPoolInit';
opts = configfunc(opts);

f = opts.func_feat(zeros(target_size, 'uint8'), opts);
fdim = length(f);
feat = zeros(length(dataset.image_names), fdim);

% config alignment
land_mark_id = [1,2];
land_mark = GetLandMark(dataset.OMRONFaceDetection, land_mark_id);
target_scale = abs(target_land_mark(1) - target_land_mark(2));
mean_face = zeros(target_size);
nface = 0;
for i = 1:length(dataset.image_names)
    if mod(i,round(length(dataset.image_names)/100))==0
        fprintf('%%%d.',round(i*100/length(dataset.image_names)));
    end
    if ~isempty(land_mark{i}) > 0
        image = imread([dataset.data_root, '/', dataset.image_names{i}]);
        
        if size(image,3) == 1
            image = repmat(image, [1,1,3]);
        end
        
        scale = abs(land_mark{i}(1) - land_mark{i}(2));
        image = imresize(image, target_scale/scale);
        land_mark2 = (land_mark{i} - complex(1, 1))*target_scale/scale + 1;
        face = WarpPositive(image, [], land_mark2, target_land_mark, target_size);
        mean_face = mean_face + double(rgb2gray(face));
                       
        if size(face,1)~=target_size(1) || size(face,2)~=target_size(2)
            face=imresize(face,target_size);
        end
        
        if size(face, 3) == 3
            face = rgb2gray(face);
        end
                
        feat(i,:) = opts.func_feat(face, opts);
        nface = nface + 1;
    end
end
fprintf('\n');
mean_face = mean_face/nface;
figure(1);
imshow(uint8(mean_face));
hold on;
plot(target_land_mark, 'ro');
drawnow;



