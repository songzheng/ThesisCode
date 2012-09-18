addpath ..\..\Tools\Matlab\
addpath(genpath('..\..\Tools\Matlab\'));
addpath ..\..\..\data\
addpath ..\BIFfeature\

dataset.label_names = {'age', 'gender', 'OMRONFaceDetection'};
dataset.label_args = {[], [], {'alignment', 'score_max'}};

target_size = [80,80];
target_land_mark = complex([80/4, 80/4*3], [80/4, 80/4]);
target_scale = abs(target_land_mark(1) - target_land_mark(2));
% for name = {'WebFace'}
%     disp(name{1});
%     dataset.name = name{1};
%     dataset = LoadDataset(dataset);
% end

%%

lr_rot_set = {[-40,-30], [-30, -20], [-20, -10], [-10, 10], [10, 20], [20, 30], [30, 40]};
ud_rot_set = {[-20, 0], [0, 20]};

stat = cell(length(ud_rot_set), length(lr_rot_set));

% select multiview faces
for i = 1:length(ud_rot_set)
    for j = 1:length(lr_rot_set)
        up_down_rot = ud_rot_set{i};
        left_right_rot = lr_rot_set{j};
        score = [500, inf];
        sel = SelectResult(dataset.OMRONFaceDetection, score, left_right_rot, up_down_rot);

        stat{i,j}.count = length(find(sel~=0));
        stat{i,j}.face = zeros(target_size);
        stat{i,j}.contour = complex(zeros(1, 87), zeros(1, 87));
        
        land_mark_id = [1,2];
        data_land_mark = GetLandMark(dataset.OMRONFaceDetection, land_mark_id, sel);        
        
        for n = 1:length(dataset.image_names)
            if mod(i,round(length(dataset.image_names)/100))==0
                fprintf('%%%d.',round(n*100/length(dataset.image_names)));
            end
            if sel(n) <= 0
                continue;
            end
            
            image = imread([dataset.data_root, '/', dataset.image_names{n}]);
            
            scale = abs(data_land_mark{n}(1) - data_land_mark{n}(2));
            image2 = imresize(image, target_scale/scale);
            land_mark = (data_land_mark{n} - complex(1, 1))*target_scale/scale + 1;
            contour = complex(dataset.OMRONFaceDetection(n).contour(1,:)+1, dataset.OMRONFaceDetection(n).contour(2,:)+1);
            contour = (contour - complex(1,1)) *target_scale/scale + 1; 
            [face, contour] = WarpPositive(image2, contour, land_mark, target_land_mark, target_size);
            
            if size(face,1)~=target_size(1) || size(face,2)~=target_size(2)
                face=imresize(face,target_size);
            end
            
            if size(face, 3) == 3
                face = rgb2gray(face);
            end
            
            stat{i,j}.face = stat{i,j}.face + double(face);
            stat{i,j}.contour = stat{i,j}.contour + contour;
        end
        stat{i,j}.face = stat{i,j}.face / stat{i,j}.count;
        stat{i,j}.contour = stat{i,j}.contour / stat{i,j}.count;
    end
end

%%
clf;
for i = 1:length(ud_rot_set)
    for j = 1:length(lr_rot_set)
        subplot(length(ud_rot_set), length(lr_rot_set), (i-1)*length(lr_rot_set) + j);
        imshow(uint8(stat{i,j}.face));
        hold on
        plot(stat{i,j}.contour, '.');
        title(num2str(stat{i,j}.count));
    end
end
