function image = DrawImageFrame(file_list,label,patch_layout,patch_size,margin_size)
if isempty(file_list)
    return;
end

if ~exist('patch_layout','var') || isempty(patch_layout)
    patch_layout = size(file_list);
end

disp_num = 1:prod(patch_layout);

if ~exist('patch_size','var') || isempty(patch_size)
    patch_size = [0,0];
    for i=1:length(disp_num)
        if ischar(file_list{disp_num(i)})
            patch = imread(file_list{disp_num(i)});
        else
            patch = file_list{disp_num(i)};
        end
        patch_size = patch_size + [size(patch,1),size(patch,2)];
    end
    
    patch_size = round(patch_size/length(disp_num));
end

if ~exist('margin_size','var') || isempty(margin_size)
    margin_size=[20,5];
end

image_size=patch_layout.*patch_size+(patch_layout).*margin_size;
image=255*ones(image_size(1),image_size(2),3);

for i=1:length(disp_num)
    if isempty(file_list{disp_num(i)})
        patch = 255*ones(patch_size);
    else
        if ischar(file_list{disp_num(i)})
            patch = imread(file_list{disp_num(i)});
        else
            patch = file_list{disp_num(i)};
        end
        if size(patch,1)~=patch_size(1) || size(patch,2)~=patch_size(2)
            patch=imresize(patch,patch_size,'bilinear');
        end
        if isa(patch,'double')
            patch = patch - min(patch(:));
            patch = uint8(255*patch/max(patch(:)));
        end            
    end
    
%     patch=rgb2gray(patch);
%     patch=histeq(patch);
    if size(patch,3)==1
        patch=repmat(patch,[1,1,3]);
    end
    
    
    m=ceil(1.0*i/patch_layout(1));
    n=i-patch_layout(1)*(m-1);
    
    start_coor=[(n-1),(m-1)].*(margin_size+patch_size)+1;
    end_coor=start_coor+patch_size-1;
    image(start_coor(1):end_coor(1),start_coor(2):end_coor(2),:)=patch; 
%     text(end_coor(1),end_coor(1),num2str(type(rank(i))));
end

image = uint8(image);imshow(image);
% imshow(image,'border','tight');%
% imagesc(image/255);
% imwrite(uint8(image),'temp_rank.bmp');

if ~exist('label','var') || isempty(label)
    return;
end

for i=1:length(disp_num)
   
    if(isa(label(disp_num(i)),'char'))
        disp_char=label(disp_num(i));
    else
        disp_char=num2str(label(disp_num(i)),'%.2f');
    end
    
    m=ceil(1.0*i/patch_layout(1));
    n=i-patch_layout(1)*(m-1);    
    
    start_coor=[(n-1),(m-1)].*(margin_size+patch_size)+1;
    end_coor=start_coor+patch_size-1;
    text(start_coor(2)+1,end_coor(1)+10,disp_char,'color','k');
end