function [spos, view] = pascal_trunc_split(pos, view)
num_th = 200;
data_num = length(pos);
pos_trunc = pos([pos(:).trunc] == 1);
pos_ntrunc = pos([pos(:).trunc] == 0);

ptrunc = length(pos_trunc)/data_num;

if ptrunc > 0.5 && length(pos_trunc) > num_th
    spos = {pos_trunc, pos_ntrunc};
    view = {view, [view,'Truncated']};
else
	if ptrunc < 0.2 || length(pos) <= 150
   	 spos = {pos};
   	 view = {view};
	else
	 spos = {pos_ntrunc};
	 view = {view};
	end
end
