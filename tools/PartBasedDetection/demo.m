figure(1)
load('..\PartBasedDetectionModels\bus_final');

imgname = '000034.jpg';
im = imread(imgname);
tic;
[dets, boxes] = imgdetect(im, model, 0);
toc;
if ~isempty(boxes)
    boxes = reduceboxes(model, boxes);
    [dets boxes] = clipboxes(im, dets, boxes);
    I = nms(dets, 0.5);
    boxes1 = dets(I,[1:4 end]);
    parts1 = boxes(I,:);
else
    boxes1 = [];
    parts1 = [];
end

clf;
show_boxes_class(im, boxes1(1:min(4, size(boxes1,1)), 1:4));

pause

load('..\PartBasedDetectionModels\bicycle_final.mat');

imgname = '000084.jpg';
im = imread(imgname);
tic;
[dets, boxes] = imgdetect(im, model, 0);
toc;
if ~isempty(boxes)
    boxes = reduceboxes(model, boxes);
    [dets boxes] = clipboxes(im, dets, boxes);
    I = nms(dets, 0.5);
    boxes1 = dets(I,[1:4 end]);
    parts1 = boxes(I,:);
else
    boxes1 = [];
    parts1 = [];
end

clf;
show_boxes_class(im, boxes1(1:min(4, size(boxes1,1)), 1:4));


pause
load('..\PartBasedDetectionModels\person_final.mat');

imgname = '000061.jpg';
im = imread(imgname);
tic;
[dets, boxes] = imgdetect(im, model, -0.5);
toc;
if ~isempty(boxes)
    boxes = reduceboxes(model, boxes);
    [dets boxes] = clipboxes(im, dets, boxes);
    I = nms(dets, 0.5);
    boxes1 = dets(I,[1:4 end]);
    parts1 = boxes(I,:);
else
    boxes1 = [];
    parts1 = [];
end

clf;
show_boxes_class(im, boxes1(1:min(4, size(boxes1,1)), 1:4));