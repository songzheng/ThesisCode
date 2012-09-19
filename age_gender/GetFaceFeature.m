function [feat] = GetFaceFeature(dataset, align_name, opts)

func = str2func(['GetFeature', align_name]);
% example det
npoints = 87;
det.det = [1,1,80,80;1,80,1,80] - 1;
det.part = [20,60;20,20] - 1;
det.contour = [ones(1, npoints); ones(1,npoints)];
det.rotation = [0,0,0];
f = func(zeros([80,80], 'uint8'), det, opts);

fdim = length(f);
feat = zeros(fdim, length(dataset.image_names), 'single');

% mean_face = zeros(target_size);
nface = 0;

for i = 1:length(dataset.image_names)
    if mod(i,round(length(dataset.image_names)/100))==0
%         fprintf('%%%d.',round(i*100/length(dataset.image_names)));
    end
        
    det = dataset.OMRONFaceDetection(i);
    if isempty(det.det)
        continue;
    end
        
    name = strrep(dataset.image_names{i}, '\', '/');
    
    image = imread([dataset.data_root, '/', name]);             
        
%     mean_face = mean_face + double(face);
    feat(:, i) = func(image, det, opts);
    nface = nface + 1;
end
% fprintf('\n');
% fprintf('%d out of %d faces\n', nface, length(dataset.image_names));