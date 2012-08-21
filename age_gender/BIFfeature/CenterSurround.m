function im = CenterSurround(im, fsize)
assert(size(im,3) == 1);
im = double(im)/255;
im = imadjust(im);
meanfilter = ones(fsize)/prod(fsize);
im = im./(imfilter(im, meanfilter, 'symmetric') + eps);

im = min(im, 1);
im = 1 - im;
% 
% im2 = min(im, 0.25)*4;

% im = im/max(im(:))