function map = visualizeBIF(feat, opts)

count = 1;
buff = 10;
map = cell(1, length(opts.patch_size));

if length(feat) == opts.length
    bsym = 1;
elseif length(feat) == opts.length_nonsym
    bsym = 0;
else
    error('Wrong Feature');
end

for i = 1:length(opts.patch_size)
    subplot(length(opts.patch_size), 1, i);
    
    grid_num = opts.grid_num{i};
    
    if bsym
        sym_grid_num = [grid_num(1), ceil(grid_num(2)/2)];
        w = zeros([sym_grid_num, opts.norient]);
        w = reshape(feat(count:(count+numel(w)-1)), size(w));
        count = count+numel(w);
        width = floor(grid_num(2)/2);
        w2 = flipfeat(w, opts.p);
        w = [w(:, 1:width, :), w2];
    else
        w = zeros([grid_num, opts.norient]);
        w = reshape(feat(count:(count+numel(w)-1)), size(w));
        count = count+numel(w);
    end
    
    scale = max(max(w(:)),max(-w(:)));
    pos = BIFpicture(w, opts) * 255/scale;
    neg = BIFpicture(-w, opts) * 255/scale;
    if min(w(:)) < 0
        neg = padarray(neg, [0 buff], 128, 'both');
        im = uint8([pos, neg]);
    else
        im = uint8(pos);
    end
    
    map{i} = im;
    imagesc(im);
    colormap gray;
    axis equal;
    axis off;
    title(sprintf('norm = %0.3f/%0.3f', sum(w(w>0)), -sum(w(w<0))));
end

function im = BIFpicture(w, opts)
bs = 20;
% construct a "glyph" for each orientaion
bim1 = zeros(bs, bs);
bim1(round(bs/2):round(bs/2)+1, :) = 1;
bim = zeros([size(bim1) opts.norient]);
bim(:,:,1) = bim1;

degree = 180/opts.norient;
for i = 2:opts.norient
    bim(:,:,i) = imrotate(bim1, (i-1)*degree, 'crop');
end

% make pictures of positive weights bs adding up weighted glyphs
s = size(w);
w(w < 0) = 0;
im = zeros(bs*s(1), bs*s(2));
for i = 1:s(1),
    iis = (i-1)*bs+1:i*bs;
    for j = 1:s(2),
        jjs = (j-1)*bs+1:j*bs;
        for k = 1:opts.norient,
            im(iis,jjs) = im(iis,jjs) + bim(:,:,k) * w(i,j,k);
        end
    end
end