function box = DetectPartBox(im, model, name)

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

switch name
    case 'upperbody_detection'
        assert(nparts == 18);
        % interpolate box
        box = interpolate_upper(box(1:4, :));
        type = [type, 0, 0];
    case  'lowerbody_detection'
        assert(nparts == 10);
        box = interpolate_lower(box(1:4, :));
        type = [type, 0, 0];
    otherwise
        error('Unsupported part detection');
end

% append type and score
box = [box; type];
box = [box(:)', score];

function box = interpolate_upper(box)

% upper
t1= box(:,8);
t2= box(:,16);
t3 = box(:,9);
t4= box(:,17);
t5= box(:,2);
left = (t1(1)+t1(3)+t3(1)+t3(3))/4;
right = (t2(1)+t2(3)+t4(1)+t4(3))/4;
up = (t1(2)+t2(2)+ t5(2))/3;
down = (t4(2)+t4(4)+t3(2)+t3(4))/4;

center = [left+right, up+down]/2;
half_width = max(right-left, down-up)/2;

box = [box, round([center(1)-half_width; center(2)-half_width; ...
    center(1)+half_width; center(2)+half_width])];

% lower
t1= box(:,9);
t2= box(:,17);
t3 = box(:,10);
t4= box(:,18);
left = (t1(1)+t1(3)+t3(1)+t3(3))/4;
right = (t2(1)+t2(3)+t4(1)+t4(3))/4;
up = (t1(2)+t2(2))/2;
down = (t4(4)+t3(4))/2;

center = [left+right, up+down]/2;
half_width = max(max(right-left, down-up)/2, 10);

box = [box, round([center(1)-half_width; center(2)-half_width; ...
    center(1)+half_width; center(2)+half_width])];



function box = interpolate_lower(box)

% upper
t1= box(:,1);
t2= box(:,4);
t3 = box(:,3);
t4= box(:,8);
left = min(t1(1), t2(1));
right = max(t3(3), t4(3));
up = t1(2);
down = t4(4);

center = [left+right, up+down]/2;
half_width = max(right-left, down-up)/2;

box = [box, round([center(1)-half_width; center(2)-half_width; ...
    center(1)+half_width; center(2)+half_width])];

% lower
t1= box(:,4);
t2= box(:,6);
t3 = box(:,8);
t4= box(:,10);
left = min(t1(1), t2(1));
right = max(t3(3), t4(3));
up = t1(2);
down = t4(4);

center = [left+right, up+down]/2;
half_width = max(max(right-left, down-up)/2, 10);

box = [box, round([center(1)-half_width; center(2)-half_width; ...
    center(1)+half_width; center(2)+half_width])];