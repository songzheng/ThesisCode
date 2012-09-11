function [spos, spos_sym_inds, models, view_name] = pascal_pos_split(cls, pos, note)
spos = {};
spos_mirror = {};
view_name = {};
models = {};

pos_frontal = pos(strcmp({pos(:).view}, 'Frontal'));
pos_rear = pos(strcmp({pos(:).view}, 'Rear'));
pos_left = pos(strcmp({pos(:).view}, 'Left'));
pos_right = pos(strcmp({pos(:).view}, 'Right'));
pos_dump = pos(strcmp({pos(:).view}, ''));
data_num = length(pos_frontal) + length(pos_rear) + length(pos_left) + length(pos_right);

fprintf('View parsing...\nFrontal# %d,\tRear# %d,\tLeft# %d,\tRight# %d,\tDump# %d\n%f%%,\t%f%%,\t%f%%,\t%f%%\n', ...
    length(pos_frontal), length(pos_rear), length(pos_left), length(pos_right), length(pos_dump),...
    length(pos_frontal)/data_num*100, length(pos_rear)/data_num*100,...
    length(pos_left)/data_num*100, length(pos_right)/data_num*100);

th = 0.15;
num_th = 150;
num_th2 = 400;
view_count = 1;
bMergeRear = 0;
if length(pos_rear)/data_num > th ...
    || (length(pos_rear) > num_th2 && length(pos_rear)/length(pos_frontal) > 0.4)
    [spos_f, view_f] = pascal_trunc_split(pos_rear, 'Rear');  
    for i = 1:length(spos_f)
	if length(spos_f{i}) < num_th
		pos_frontal = [pos_frontal, spos_f{i}];
		continue;
	end
        models{view_count} = initmodel(cls, spos_f{i}, note, 'N');
        inds = 1:length(spos_f{i});
        spos{view_count} = spos_f{i};
        spos_sym_inds{view_count} = inds;
        view_name{view_count} = view_f{i};
        view_count = view_count+1;
    end
else
    pos_frontal = [pos_frontal, pos_rear];
    bMergeRear = 1;
end

if length(pos_frontal)/data_num > th && length(pos_frontal) > num_th ...
    || length(pos_frontal) > num_th2
    if bMergeRear
        [spos_f, view_f] = pascal_trunc_split(pos_frontal, 'FrontalRear');
    else
        [spos_f, view_f] = pascal_trunc_split(pos_frontal, 'Frontal');
    end

   for i = 1:length(spos_f)
	if length(spos_f{i}) < num_th
		pos_dump = [pos_dump, spos_f{i}];
		continue;
	end	
        models{view_count} = initmodel(cls, spos_f{i}, note, 'N');
        inds = 1:length(spos_f{i});
        spos{view_count} = spos_f{i};
        spos_sym_inds{view_count} = inds;
        view_name{view_count} = view_f{i};
        view_count = view_count+1;
    end
else
    pos_dump = [pos_dump, pos_frontal];
end


if (length(pos_left)/data_num > th/2 && length(pos_left) > num_th/2) ...
        || length(pos_left) > num_th2
    [spos_left, view_left] = pascal_trunc_split(pos_left, 'Left');
%     spos = [spos, spos_f];
%     view_name = [view_name, view_f];
else    
    pos_dump = [pos_dump, pos_left];
end

if (length(pos_right)/data_num > th/2 && length(pos_right) > num_th/2) ...
        || length(pos_right) > num_th2/2
    [spos_f, view_f] = pascal_trunc_split(pos_right, 'RightLeft');   
    for i = 1:length(spos_f)
	if length(spos_f{i})+length(spos_left{i}) < num_th
		pos_dump = [pos_dump, spos_f{i}];
		continue;
	end
        models{view_count} = initmodel(cls, [spos_f{i},spos_left{i}], note, 'N');
        inds = 1:length(spos_f{i});
        spos{view_count} = [spos_f{i},spos_left{i}];
        spos_sym_inds{view_count} = inds;
        view_name{view_count} = view_f{i};
        view_count = view_count+1;
    end
else
    pos_dump = [pos_dump, pos_right];
end

if length(pos_dump)/length(pos) > 0.3
    models{view_count} = initmodel(cls, pos_dump, note, 'N');
    inds = lrsplit(models{view_count}, pos_dump, view_count);
    spos{view_count} = pos_dump;
    spos_sym_inds{view_count} = inds;
    view_name = [view_name, {'N/A'}];
end

fprintf('Initialized Model View:\n');
for i=1:length(view_name)
    fprintf('%s: %d\n', view_name{i}, length(spos{i}));
end
