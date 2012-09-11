function view_split = ViewSplit(dataset)

lr_rot_set = {[-inf, -40], [-40, -25], [-25, -10], [-10, 10], [10, 25], [25, 40], [40, inf]};
set_id = [4,3,2,1,2,3,4];

view_split = zeros(length(dataset.image_names),1);
% select multiview faces
for j = 1:length(lr_rot_set)
    left_right_rot = lr_rot_set{j};
    sel = SelectResult(dataset.OMRONFaceDetection, [], left_right_rot, []);
    view_split(sel) = set_id(j);
end