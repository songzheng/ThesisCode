
function land_mark = GetLandMark(det, land_mark_id)
land_mark = cell(length(det), 1);
for i = 1:length(det)
    
    if isempty(det(i).part)
        continue;
    end
    
    land_mark{i} = complex(det(i).part(1, land_mark_id)+1, ...
        det(i).part(2, land_mark_id)+1);
end