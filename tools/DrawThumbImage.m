function im = DrawThumbImage(im, boxes, colorset)
colorset_num = zeros(size(colorset));
colorset_num(colorset == 'r') = 3;
colorset_num(colorset == 'g') = 4;
colorset_num(colorset == 'y') = 7;
colorset_num(colorset == 'b') = 2;
colorset_num(colorset == 'c') = 6;
colorset_num(colorset == 'm') = 5;


numpart = floor(size(boxes,2)/5);

x1 = zeros(size(boxes,1),numpart);
y1 = zeros(size(boxes,1),numpart);
x2 = zeros(size(boxes,1),numpart);
y2 = zeros(size(boxes,1),numpart);
for p = 1:numpart
    x1(:,p) = boxes(:,1+(p-1)*5);
    y1(:,p) = boxes(:,2+(p-1)*5);
    x2(:,p) = boxes(:,3+(p-1)*5);
    y2(:,p) = boxes(:,4+(p-1)*5);
end

x1 = min(max(x1, 1), size(im, 2));
y1 = min(max(y1, 1), size(im, 1));
x2 = min(max(x2, 1), size(im, 2));
y2 = min(max(y2, 1), size(im, 1));

rect = [min(x1, [], 2),...
    min(y1, [], 2),...
    max(x2, [], 2),...
    max(y2, [], 2)];

rect = round(rect);

im = im(rect(2):rect(4), rect(1):rect(3), :);
im = repmat(rgb2gray(im), [1,1,3]);

x1 = x1 - rect(1) + 1;
x2 = x2 - rect(1) + 1;
y1 = y1 - rect(2) + 1;
y2 = y2 - rect(2) + 1;

center = [(y1+y2)/2, (x1+x2)/2];
radius = [(y2-y1+1)/2, (x2-x1+1)/2];

for p = 1:numpart
    im = DrawCircle(im, center(:, [p, p+numpart]), radius(:,[p, p+numpart]), colorset_num(p));
end
