function draw_img=DrawCircle(img, center, radius, color, fill)
if size(img,3)==1
    error('Only color image accept.');
end
if size(center,1) ~= size(radius,1)
    error('Wrong Rectangle Format');
end
color_panel=[0,0,0  %black
    0,0,255         %blue
    255,0,0         %red
    0,255,0         %green
    255,255,0       %orange
    255,0,255       %purple
    0,255,255];     %yellow

if ~exist('color','var')
    color=3;
end

if ~exist('fill','var')
    fill=0;
end

draw_img=img;

[x, y] = meshgrid(1:size(img,2), 1:size(img,1));
y = y(:);
x = x(:);
draw_idx = [];

for i = 1:size(center,1)
    
    err = sqrt((x - center(i,2)).^2 + (y - center(i,1)).^2) - radius(i);
    if ~fill
        draw_idx = union(draw_idx, find(abs(err)<=0.5));
    else
        draw_idx = union(draw_idx, find(err<=0.5));
    end
end

pixel_r = sub2ind(size(draw_img),y(draw_idx), x(draw_idx),1*ones(length(draw_idx),1));
pixel_g = sub2ind(size(draw_img),y(draw_idx), x(draw_idx),2*ones(length(draw_idx),1));
pixel_b = sub2ind(size(draw_img),y(draw_idx), x(draw_idx),3*ones(length(draw_idx),1));

draw_img(pixel_r) = color_panel(color,1);
draw_img(pixel_g) = color_panel(color,2);
draw_img(pixel_b) = color_panel(color,3);
