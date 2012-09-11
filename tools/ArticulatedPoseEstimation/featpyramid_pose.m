function pyra = featpyramid(im, model, scale_th)
% Compute feature pyramid.
%
% pyra.feat{i} is the i-th level of the feature pyramid.
% pyra.scales{i} is the scaling factor used for the i-th level.
% pyra.feat{i+interval} is computed at exactly half the resolution of feat{i}.
% first octave halucinates higher resolution data.

sbin      = model.sbin;
interval  = model.interval;
padx      = max(model.maxsize(2)-1-1,0);
pady      = max(model.maxsize(1)-1-1,0);
sc = 2 ^(1/interval);
imsize = [size(im, 1) size(im, 2)];
max_scale = 1 + floor(log(min(imsize)/(5*sbin))/log(sc));

pyra.scale = zeros(max_scale,1);
for i = 1:interval
    pyra.scale(i) = 1/sc^(i-1);
    for j = i+interval:interval:max_scale
        pyra.scale(j) = 0.5 * pyra.scale(j-interval);
    end
end

scale_idx = find(pyra.scale >= scale_th(1) & pyra.scale <= scale_th(2));
pyra.feat = cell(max_scale,1);

if size(im, 3) == 1
    im = repmat(im,[1 1 3]);
end
im = double(im); % our resize function wants floating point values

for i = 1:interval
    scaled = resize(im, 1/sc^(i-1));
    
    if any(i == scale_idx)
        pyra.feat{i} = features(scaled,sbin);
    end
    % remaining interals
    for j = i+interval:interval:max_scale
        scaled = reduce(scaled);
        if any(j == scale_idx)
            pyra.feat{j} = features(scaled,sbin);
        end
    end
end

pyra.feat = pyra.feat(scale_idx);
pyra.scale = pyra.scale(scale_idx);

for i = 1:length(pyra.feat)
    % add 1 to padding because feature generation deletes a 1-cell
    % wide border around the feature map
    pyra.feat{i} = padarray(pyra.feat{i}, [pady+1 padx+1 0], 0);
    % write boundary occlusion feature
    pyra.feat{i}(1:pady+1, :, end) = 1;
    pyra.feat{i}(end-pady:end, :, end) = 1;
    pyra.feat{i}(:, 1:padx+1, end) = 1;
    pyra.feat{i}(:, end-padx:end, end) = 1;
end

pyra.scale    = model.sbin./pyra.scale;
pyra.interval = interval;
pyra.imy = imsize(1);
pyra.imx = imsize(2);
pyra.pady = pady;
pyra.padx = padx;
