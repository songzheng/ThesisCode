function [mag, ori] = canny(im, sbin)
dims = size(im);
assert(dims(3) == 3);
% C = makecform('srgb2lab');
% im = applycform(im, C);
im = double(im);
out = dims(1:2) - 2; % keep one block margin

% sobel edge
x_ex = out(2);
y_ex = out(1);

dx = im(2:y_ex+1, 3:x_ex+2, :) - im(2:y_ex+1, 1:x_ex, :);
dy = im(3:y_ex+2, 2:x_ex+1, :) - im(1:y_ex, 2:x_ex+1, :);

mag = dx.^2 + dy.^2;

[mag, z_sub] = max(mag,[], 3);

[x_sub, y_sub] = meshgrid(1:out(2), 1:out(1));
idx = sub2ind([out,3],y_sub(:), x_sub(:), z_sub(:));

dx = dx(idx);
dy = dy(idx);
dx = reshape(dx, out);
dy = reshape(dy, out);


norm = imfilter(mag, ones(2*sbin+1)/(2*sbin+1)^2, 'same');
mag = mag./(norm+eps);
mag = min(mag,2)/2;
% mag(mag<1) = 0;
% mag(mag>=1) = 1;
ori = atan2(dy, dx);
% norm2 = abs(ori - imfilter(ori, ones(2*sbin+1)/(2*sbin+1)^2, 'same'))/(2*pi);
% norm2(norm2 > 1) = norm2(norm2 > 1) - floor(norm2(norm2 > 1));

