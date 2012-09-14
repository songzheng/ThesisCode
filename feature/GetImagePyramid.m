function im_pyra = GetImagePyramid(image, scales)

im_pyra = cell(1, length(scales));

[ignore, order] = sort(scales, 'descend');


for i = 1:length(scales)

    if i == 1
        im_pyra{order(i)} = imresize(image, scales(order(i)));
    else
        im_pyra{order(i)} = imresize(im_pyra{order(i-1)}, scales(order(i))/scales(order(i-1)));
    end
    
end
    