im = imread('test.jpg');

while max(size(im))>50
    [mag, ori] = canny(im, 8);
    figure;
    imshow(computeColor(mag, ori));
    im = imresize(im, 0.8);
end
%% translation of patches
% patch_x = 15 + round(rand * (size(im,2)-30));
% patch_y = 15 + round(rand * (size(im,1)-30));
% patches = cell(7,7);
% patches_ori = cell(7,7);
% 
% patches_dct = cell(7,7);
% 
% for ix = 0:6
%     for iy = 0:6
%         patches_ori{ix+1, iy+1} = rgb2gray(im((patch_y+iy):(patch_y+iy)+7, (patch_x+ix):(patch_x+ix)+7, :));
%         patches{ix+1, iy+1} = double(patches_ori{ix+1, iy+1});
%         patches{ix+1, iy+1} = patches{ix+1, iy+1} - mean(mean(patches{ix+1, iy+1}));
%         patches{ix+1, iy+1} = patches{ix+1, iy+1} / (std(std(patches{ix+1, iy+1}))+eps);
%         patches_dct{ix+1, iy+1} = dct2(patches{ix+1, iy+1});
%     end
% end
% figure(1); 
% subplot(1,2,1);
% DrawImageFrame(patches, [], [], [], 2);
% title('original patch')
% subplot(1,2,2); 
% DrawImageFrame(patches_dct, [], [], [], 2);
% title('dct patch')

%% rotation & scaling of patches
patch_x = 15 + round(rand * (size(im,2)-30));
patch_y = 15 + round(rand * (size(im,1)-30));
rotations = (-2:2)*10/2;
scalings = exp(-0.4:0.1:0.4);

patch_origin = rgb2gray(im(patch_y-14:patch_y+14, patch_x-14:patch_x+14, :));
patches = cell(length(rotations),length(scalings));
patches_ori = cell(length(rotations),length(scalings));
patches_dct = cell(length(rotations),length(scalings));

for ir = 1:length(rotations)
    ptmp = imrotate(patch_origin, rotations(ir), 'bilinear');
    for is = 1:length(scalings)
        ptmp2 = imresize(ptmp, scalings(is), 'bilinear');
        cidx = round(size(ptmp2)/2);
        
        patches_ori{ir, is} = ptmp2(cidx(1)-3:cidx(1)+4, cidx(2)-3:cidx(2)+4);
        patches{ir, is} = double(patches_ori{ir, is});
        patches{ir, is} = patches{ir, is} - mean(mean(patches{ir, is}));
        patches{ir, is} = patches{ir, is} / (std(std(patches{ir, is}))+eps);
        patches_dct{ir, is} = dct2(patches{ir, is});
    end
end


figure(1); 
subplot(1,2,1);
DrawImageFrame(patches, [], [], [], 2);
title('original patch')
subplot(1,2,2); 
DrawImageFrame(patches_dct, [], [], [], 2);
title('dct patch')

