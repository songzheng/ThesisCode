function f = GetFeatureAlignLv2(image, det, opts)

% introduce larger face area to include all alignment landmarks
target_size = [160,160];
target_land_mark = complex([target_size(2)/8*3, target_size(2)/8*5], [target_size(1)/8*3, target_size(1)/8*3]);
target_scale = abs(target_land_mark(1) - target_land_mark(2));
land_mark_id = [1,2];
target_center = mean(target_land_mark);

% level 3 alignment, using face alignment
OKAO_flip = [17,16,18,19,22,23,20,21,...
    25,24,26,27,30,31,28,29,...
    1,0,2,3,6,7,4,5,...
    9,8,10,11,14,15,12,13,...
    33,32,34,37,38,35,36,39,42,43,40,41,...
    45,44,46,47,48,49,54,55,56,57,50,51,52,53,62,63,64,65,58,59,60,61,...
    86:-1:66] + 1;

contour = complex(det.contour(1, :)+1,...
    det.contour(2, :)+1);
land_mark = complex(det.part(1, land_mark_id)+1, ...
    det.part(2, land_mark_id)+1);

if size(image,3) == 1
    image = repmat(image, [1,1,3]);
end

scale = abs(land_mark(1) - land_mark(2));
image = imresize(image, target_scale/scale);
land_mark = (land_mark - complex(1, 1))*target_scale/scale + 1;
contour = (contour - complex(1, 1))*target_scale/scale + 1;

[face, contour] = WarpPositive(image, contour, land_mark, target_land_mark, target_size);

if size(face, 3) == 3
    face = rgb2gray(face);
end

if size(face,1)~=target_size(1) || size(face,2)~=target_size(2)
    error('Warp Failed');
end

lr_rot = det.rotation(2);
if lr_rot < 0
    face = face(:, end:-1:1, end);
    contour = complex(size(face,2)-real(contour)+1, imag(contour));
    contour = contour(OKAO_flip);
end

points = GetFaceMesh(contour);

sampling.format = 'points';
sampling.points = points;

f = ExtractFeature(face, opts, sampling);
if iscell(f)
    f = cell2mat(f);
end
f = bsxfun(@rdivide, f, sqrt(sum(f.^2,1))+eps);
f = f(:)/(sqrt(sum(f(:).^2))+eps);

contour = contour - target_center;
norm = sqrt(sum(real(contour).^2) + sum(imag(contour).^2)) + eps;

f = [f; real(contour)'/norm; imag(contour)'/norm];