addpath ..\DetectionCommon\
load ..\ArticulatedPoseModels\upperbody_detection.mat

test_list = {'girl shopping_4.jpg', 'girl shopping_96.jpg', 'girl shopping_177.jpg', 'girl shopping_184.jpg'};


for i = 1:length(test_list)
    im = imread(test_list{i});
    
    % normalize to height of 500
    ratio = max(1, size(im, 1)/500);
    im = imresize(im, 1/ratio);
    
    box = detect_pose(im, model, [], [60, 120]);
    box = nms_pose(box, 0.5);
    
    
    % get first detection
    box = box(1,:);
    score = box(end-1:end);
    
    % format to part boxes
    nparts = floor(length(box)/5);
    box = box(1:nparts*5);
    box = reshape(box, [5 nparts]);
    type = box(end,:);
    box = box(1:4, :);
    box = (box-1)*ratio + 1;
    
    box = [box; type];
    box = [box(:)', score];
    
    showskeleton(im, box, model);
    pause;
end 