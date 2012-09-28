function [view_split, view_conf] = ViewSplit(detections, num_view)

max_view = 60;

view_centers = (0:(num_view-1))*(max_view/num_view);
view_width = max_view/num_view;
view_conf = zeros(length(detections),num_view);

sigma = view_width*2/3;

view_sel = false(length(detections),1);

% select multiview faces
for j = 1:num_view
    left_right_rot = [view_centers(j)-view_width, view_centers(j)+view_width];
    sel = SelectResult(detections, [], left_right_rot, []) ...
        | SelectResult(detections, [], -left_right_rot([2,1]), []);
    
    view_sel = view_sel | sel;
    rot = [detections(sel).rotation];
    rot = reshape(rot, [3, length(rot)/3]);
    rot = rot(2, :);
    rot = abs(rot)';
    rot = min(rot, max_view);
    
    for k = 1:num_view
        view_conf(sel, k) = exp(-(rot - view_centers(k)).^2/(2*sigma^2));
    end
    
end

% normalize confidence
view_conf = bsxfun(@rdivide, view_conf, sqrt(sum(view_conf.^2, 2))+eps);
[ignore, view_split] = max(view_conf, [], 2);
view_split(~view_sel) = 0;