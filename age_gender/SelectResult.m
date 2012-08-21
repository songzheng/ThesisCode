
function sel = SelectResult(det, score, left_right_rot, up_down_rot)

for i = 1:length(det)
    if isempty(det(i).det_conf)
        det(i).det_conf = 0;
        det(i).part_conf = 0;
        det(i).rotation = [inf, inf, inf];
    end
end

sel = true(1, length(det));

if ~isempty(score)
    sel = sel & (([det.det_conf] >= score(1)) & ([det.det_conf] <= score(2)));
    sel = sel & (([det.part_conf] >= score(1)) & ([det.part_conf] <= score(2)));
end

rot = [det.rotation];
rot = reshape(rot(:), [3, length(det)]);
rot(3, rot(2,:)>0) = -rot(3, rot(2,:)>0);


if ~isempty(left_right_rot)
    sel = sel & ((rot(2, :) >= left_right_rot(1)) & (rot(2, :) <= left_right_rot(2)));
end

if ~isempty(up_down_rot)
    sel = sel & ((rot(3, :) >= up_down_rot(1)) & (rot(3, :) <= up_down_rot(2)));
end

sel = double(sel(:));