function pos = FeatureVisualizeDenseHOG(w, feature, bs, type)

% visualizeHOG(w)
% Visualize HOG features/weights.
if ~exist('type', 'var') || type == 1
    if ~exist('bs', 'var')
        bs = 20;
    end
    buff = 0;
    % make pictures of positive and negative weights
    scale = max(w(:));
    pos = HOGpicture(w, bs);
    pos = pos * 255/scale;
%     neg = HOGpicture(-w, bs) * 255/scale;
    
    % put pictures together and draw
    pos = padarray(pos, [buff buff], 128, 'both');
    pos = uint8(pos);
%     if min(w(:)) < 0
%         neg = padarray(neg, [buff buff], 128, 'both');
%         if size(pos, 1) > size(pos, 2)
%             im = uint8([pos, neg]);
%         else
%             im = uint8([pos; neg]);
%         end
%     else
%         im = uint8(pos);
%     end
%     clf;
%     imagesc(im);
%     colormap gray;
%     axis equal;
%     axis off;
else
%     clf;
    colorwheel = makeColorwheel();
    ncols = size(colorwheel, 1);
    
    vec = complex(feature.orient_vec(:,1), feature.orient_vec(:,2));
        
    w = max(w, 0);
    wsize = size(w);
    w = reshape(w, [wsize(1)* wsize(2), wsize(3)]);
    w = w./repmat(sum(w,2), [1, size(w, 2)]);
    w = w * vec;
    w = reshape(w, [wsize(1), wsize(2)]);
    a = angle(w)/pi;
    rad = ones([wsize(1),wsize(2)]);

%     rad = abs(w);
    fk = a*(ncols-1) + 1;
    
    k0 = floor(fk);                 % 1, 2, ..., ncols
    
    k1 = k0+1;
    k1(k1==ncols+1) = 1;
    
    f = fk - k0;
    img = zeros([wsize(1), wsize(2),3]);
    for i = 1:size(colorwheel,2)
        tmp = colorwheel(:,i);
        col0 = tmp(k0)/255;
        col1 = tmp(k1)/255;
        col = (1-f).*col0 + f.*col1;
        
        idx = rad <= 1;
        col(idx) = 1-rad(idx).*(1-col(idx));    % increase saturation with radius
        
        col(~idx) = col(~idx)*0.75;             % out of range
        
        img(:,:, i) = uint8(floor(255*col));
    end;
    w = uint8(img);
%     imshow(im);
%     if min(w(:)) < 0        
%         subplot(1,2,2);
%         im = -min(w, 0);
%         im = im ./ repmat(sum(im, 3), [1,1,size(im,3)]);
%         
%         im = reshape(im, [size(w,1)*size(w,2), size(w,3)]) * colors;
%         im = reshape(im, [size(w,1), size(w,2), 3]);
% %         imshow(im);
%     end
end


function im = HOGpicture(w, bs)

% HOGpicture(w, bs)
% Make picture of positive HOG weights.
norient = size(w, 3);
% construct a "glyph" for each orientaion
bim1 = zeros(bs, bs);
bim1(round(bs/2):round(bs/2)+1,:) = 1;
bim = zeros([size(bim1) norient]);
bim(:,:,1) = bim1;
for i = 2:norient,
    bim(:,:,i) = imrotate(bim1, (i-1)*180/norient, 'crop');
end

% make pictures of positive weights bs adding up weighted glyphs
s = size(w);
w(w < 0) = 0;
% w = w(:, :, 1:9) + w(:, :, 10:18) + w(:, :, 19:27);
im = zeros(bs*s(1), bs*s(2));
for i = 1:s(1),
    iis = (i-1)*bs+1:i*bs;
    for j = 1:s(2),
        jjs = (j-1)*bs+1:j*bs;
        for k = 1:norient,
            im(iis,jjs) = im(iis,jjs) + bim(:,:,k) * w(i,j,k);
        end
    end
end


function colorwheel = makeColorwheel()

%   color encoding scheme

%   adapted from the color circle idea described at
%   http://members.shaw.ca/quadibloc/other/colint.htm


RY = 15;
YG = 6;
GC = 4;
CB = 11;
BM = 13;
MR = 6;

ncols = RY + YG + GC + CB + BM + MR;

colorwheel = zeros(ncols, 3); % r g b

col = 0;
%RY
colorwheel(1:RY, 1) = 255;
colorwheel(1:RY, 2) = floor(255*(0:RY-1)/RY)';
col = col+RY;

%YG
colorwheel(col+(1:YG), 1) = 255 - floor(255*(0:YG-1)/YG)';
colorwheel(col+(1:YG), 2) = 255;
col = col+YG;

%GC
colorwheel(col+(1:GC), 2) = 255;
colorwheel(col+(1:GC), 3) = floor(255*(0:GC-1)/GC)';
col = col+GC;

%CB
colorwheel(col+(1:CB), 2) = 255 - floor(255*(0:CB-1)/CB)';
colorwheel(col+(1:CB), 3) = 255;
col = col+CB;

%BM
colorwheel(col+(1:BM), 3) = 255;
colorwheel(col+(1:BM), 1) = floor(255*(0:BM-1)/BM)';
col = col+BM;

%MR
colorwheel(col+(1:MR), 3) = 255 - floor(255*(0:MR-1)/MR)';
colorwheel(col+(1:MR), 1) = 255;
