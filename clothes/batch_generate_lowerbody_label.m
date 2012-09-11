label_new = zeros(length(all_img_index),1);

shorts_cate = {'Shorts'};
trousers_cate = {'Jeans', 'Leggings', 'PantsCapris'};
dress_cate = {'CausualDresses_down','cocktaildress_down', 'dresstowork_down', 'Skirts'};

for i = 1:length(all_img_index)
    [path, name] = fileparts(all_img_index{i});
    [~, category] = fileparts(path);
    
    if any(strcmp(category, shorts_cate))
        label_new(i) = 1;
    end
    
    if any(strcmp(category, trousers_cate))
        label_new(i) = 2;
    end
    
    if any(strcmp(category, dress_cate))
        label_new(i) = 3;
    end
end

%%
rm_idx = [];

for i = 1:length(all_img_index)
    [path, name] = fileparts(all_img_index{i});
    [~, category] = fileparts(path);
    if category