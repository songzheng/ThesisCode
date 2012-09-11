
% clear;
addpath ..\tools
addpath(genpath('..\tools'));
addpath ..\feature\
addpath ..\..\data

feat_path = '..\..\data\features\';
model_path = '..\..\data\models\';

target_size = [80,80];

names = {'FGNET', 'Morph1', 'Morph2', 'Yamaha', 'WebFace'};
nset = length(names);
datasets = cell(1, nset);


feat_name = 'HOG';

if strcmp(feat_name, 'BIF')    
    addpath BIFfeature\
    
    % config pooling window
    patch_size = [4, 8];
    opts.win_size = target_size;
    opts.patch_size = patch_size;
    opts.pooling = 'max';
    
    % config imag preprocess
    opts.histeq = 1;
    opts.centersurround = 1;
    
    % config feature
    opts.tag = 'BIFMaxPool';
    opts = BIFMaxPoolInit(opts);
    
elseif strcmp(feat_name, 'HOG')
    opts = FeatureInit('HOG', 'norient', 16, 'half_sphere', 0, 'sbin', 8, 'scales', [1, 0.75, 0.5]);
end

for i = 1:nset
    disp(names{i});
    datasets{i}.label_names = {'age', 'gender', 'OMRONFaceDetection'};
    datasets{i}.label_args = {[], [], {'alignment', 'score_max'}};
    datasets{i}.name = names{i};
    datasets{i} = LoadDataset(datasets{i});
                
    tag = [datasets{i}.name, '_', feat_name, 'Feature', '_', align_name];
    
    if ~exist([feat_path, tag, '.mat'], 'file')
        func = str2func(['GetFeature', align_name]);
        clear feat;
        feat = func(datasets{i}, target_size, opts);
        save([feat_path, tag], 'feat', '-v7.3');
    end
end

%% train BIF models on frontal
result_path = '..\..\data\Results\';
names = {'FGNET', 'Morph1', 'Morph2', 'Yamaha', 'WebFace'};
nset = length(names);

train_set = [3,4,5];

fold = 10;
age_data_num = zeros(1,nset);

age_limit = [1, 80];

% config model
bProject = 0;
bSplit = 0;

% select frontal faces
left_right_rot = [-10, 10];
up_down_rot = [];
score = [];

%
age_performance = zeros(nset, nset, 4);

age_number = zeros(1, nset);
    
for i = train_set
      
    disp(names{i});
    self_performance = [];
    
    view_split = ViewSplit(datasets{i});
    
    % select all available feature
    all_sel = SelectResult(datasets{i}.OMRONFaceDetection, score, [], []);    
    all_idx = find(all_sel);
    
%     % select frontal faces
%     frontal_sel = SelectResult(datasets{i}.OMRONFaceDetection, score, left_right_rot, up_down_rot);
%     frontal_idx = find(frontal_sel);
%     age_number_frontal(i) = length(frontal_idx);
        
    age = datasets{i}.age;
    gender = datasets{i}.gender;
    tag = [datasets{i}.name, '_', feat_name, 'Feature', '_', align_name];
    
    
    for f = 1:fold       
        fprintf('.');
        train_split{f} = [];
        ll = unique([age, gender], 'rows');
        for j = 1:size(ll,1)
            split_idx = find(age == ll(j,1) & gender == ll(j,2));
            split_idx = randsample(split_idx, round(length(split_idx)*0.5));
            
            train_split{f} = [train_split{f}; split_idx];
        end
        
        test_split{f} = setdiff(all_idx, train_split{f});
                
        clear feat
        load([feat_path, tag]);
                
        feat = feat(train_split{f}, :);
        
        fold_model{f} = AgeGenderEvaluationTrain(feat, age(train_split{f}), gender(train_split{f}),...
            bProject, bSplit, []);       
    end
    fprintf('\n');
    
    clear feat
    load([feat_path, tag]);
    
    self_performance_view = zeros(max(view_split), 4);
    view_number = zeros(max(view_split), 1);
    for f = 1:fold    
        [res_age, res_gender, self_performance(f,:)] ...
            = AgeGenderEvaluationTest(feat(test_split{f}, :), age(test_split{f}), gender(test_split{f}), fold_model{f});
        
        res_view = view_split(test_split{f});
        
        for v = 1:max(view_split)
            view_age = res_age(res_view==v);
            view_gt = age(test_split{f}(res_view==v));
            self_performance_view(v, 2) = self_performance_view(v, 2) + sum(abs(view_age - view_gt));
            self_performance_view(v, 3) = self_performance_view(v, 3) + length(find(abs(view_age - view_gt)<=5));
            view_number(v) = view_number(v) + length(view_gt);
        end
    end
    
    for v = 1:max(view_split)
        self_performance_view(v, 2) = self_performance_view(v, 2)/view_number(v);
        self_performance_view(v, 3) = self_performance_view(v, 3)/view_number(v);
    end
    self_performance = mean(self_performance,1);
    age_performance(i, i, :) = reshape(self_performance, [1,1,4]);
    
    fprintf('Train on %s, Test on %s\n\t MAE=%f, ACC = %f\n',...
        datasets{i}.name, datasets{i}.name,...
        age_performance(i,i,2), age_performance(i,i,3));
    disp(self_performance_view(:,2));
    disp(self_performance_view(:,3));
    
    save([result_path, '\', tag], 'self_performance', 'self_performance_view');
%     % train overall model
%     feat = feat(all_idx, :);
%     datasets{i}.age_model = AgeGenderEvaluationTrain(feat, age(all_idx), gender(all_idx),...
%             bProject, bSplit, [model_path, tag]);
end
    
%% cross set evaluation

% for i = 1:nset
%     disp(names{i});
%     if isempty(setdiff(train_set, i))
%         continue;
%     end
%     
%         
%     sel = SelectResult(datasets{i}.OMRONFaceDetection, score, [], []);
%     all_idx = find(sel>0);
%     age_number(i) = length(all_idx);
%     
%     clear feat
%     tag = [datasets{i}.name, '_', feat_name, 'Feature', '_', align_name];
%     load([feat_path, tag]);
%     age = datasets{i}.age;
%     gender = datasets{i}.gender;
%     for j = setdiff(train_set, i);
%         [~,~,p] ...
%             = AgeGenderEvaluationTest(feat(all_idx, :), age(all_idx), gender(all_idx), datasets{j}.age_model);
%           
%         age_performance(i,j,:) = reshape(p, [1,1,4]);
%         fprintf('Train on %s, Test on %s\n\t MAE=%f, ACC = %f\n',...
%             datasets{j}.name, datasets{i}.name,...
%             age_performance(i,j,2),age_performance(i,j,3));
%     end
% end
% 
% %% report performance
% fprintf('---------------------------------------------\n');
% age_performance_MAE = age_performance(:,:,2);
% age_performance_ACC = age_performance(:,:,3);
% 
% age_performance_MAE_self = zeros(1, nset);
% age_performance_MAE_cross = zeros(1, nset);
% age_performance_MAE_drop = zeros(1, nset);
% age_performance_ACC_self = zeros(1, nset);
% age_performance_ACC_cross = zeros(1, nset);
% age_performance_ACC_drop = zeros(1, nset);
% for i = 1:nset
%     age_performance_MAE_self(i) = age_performance_MAE(i,i);
%     age_performance_ACC_self(i) = age_performance_ACC(i,i);
%     age_performance_MAE_cross(i) = age_number(setdiff(1:nset, i)) ...
%         * age_performance_MAE(setdiff(1:nset, i), i)...
%         /sum(age_number(setdiff(1:nset, i)));
%     age_performance_MAE_drop(i) = age_performance_MAE_cross(i) - age_performance_MAE(i,i);
%     
%     age_performance_ACC_cross(i) = age_number(setdiff(1:nset, i)) ...
%         * age_performance_ACC(setdiff(1:nset, i), i)...
%         /sum(age_number(setdiff(1:nset, i)));
%     age_performance_ACC_drop(i) = -(age_performance_ACC_cross(i) - age_performance_ACC(i,i));
% end
% 
% disp(names);
% disp(age_performance_MAE_self);
% disp(age_performance_MAE_cross);
% disp(age_performance_MAE_drop);
% disp(age_performance_ACC_self);
% disp(age_performance_ACC_cross);
% disp(age_performance_ACC_drop);
% 
% fprintf('---------------------------------------------\n');