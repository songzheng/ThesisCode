function rect = GetBoundingBox(boxes)
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

rect = [min(x1, [], 2),...
    min(y1, [], 2),...
    max(x2, [], 2),...
    max(y2, [], 2)];

rect = round(rect);