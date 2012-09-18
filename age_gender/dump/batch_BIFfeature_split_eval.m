addpath ..\..\Tools\Matlab\
addpath(genpath('..\..\Tools\Matlab\'));
addpath ..\..\..\data\

dataset.label_names = {'age', 'gender', 'OMRONFaceDetection'};
dataset.label_args = {[], [], {'alignment', 'score_max'}};

target_size = [80,80];
target_land_mark = complex([80/4, 80/4*3], [80/4, 80/4]);
names = {'FGNET', 'Morph1', 'Morph2', 'Yamaha', 'WebFace'};
% names = {'Yamaha'};
nset = length(names);
for i = 1:nset
    disp(names{i});
    dataset.name = names{i};
    if ~exist(['feature\', dataset.name, '_BIFFeature_Frontal.mat'], 'file')
        dataset = LoadDataset(dataset);
        [feat, sel] = GetBIFFeatureFrontal(dataset, target_size, target_land_mark);
        save(['feature\', dataset.name, '_BIFFeature_Frontal'], 'feat', 'sel', '-v7.3');
    end
end

%% self evaluation
age_performance = cell(nset,nset);

age_performance_MAE = zeros(nset,nset);
age_performance_ACC = zeros(nset,nset);
gender_performance = zeros(nset, nset);
split_performance = zeros(nset, nset);
age_data_num = zeros(1,nset);

age_limit = [5, 60];
datasets = cell(1, nset);
age_group = 1;
gender_group = 0;
for i = 4
    datasets{i}.label_names = {'age', 'gender', 'OMRONFaceDetection'};
    datasets{i}.label_args = {[], [], {'alignment', 'score_max'}};
    datasets{i}.name = names{i};
    disp(datasets{i}.name);
    
    datasets{i} = LoadDataset(datasets{i});

    load(['feature\', datasets{i}.name, '_BIFFeature_Frontal.mat']);
    
    idx = find(sel>0);
    age_data_num(i) = length(idx);
%     load model;
%     datasets{i}.age_model = model;
    [datasets{i}.age_model age_performance{i,i}] = AgeGenderEvaluationTrain(feat(idx, :), datasets{i}.age(idx), datasets{i}.gender(idx), age_limit, age_group, gender_group);    
end
    
%% cross set evaluation

for i = 1:nset
    clear feat
    datasets{i}.label_names = {'age', 'gender', 'OMRONFaceDetection'};
    datasets{i}.label_args = {[], [], {'alignment', 'score_max'}};
    datasets{i}.name = names{i};
    disp(datasets{i}.name);
    
    datasets{i} = LoadDataset(datasets{i});
    load(['feature\', datasets{i}.name, '_BIFFeature_Frontal.mat']);
    idx = find(sel>0);
    feat = feat(idx, :);
    age_data_num(i) = length(idx);
    for j = setdiff(4, i)
        fprintf('Train on %s, Test on %s\n',  datasets{j}.name, datasets{i}.name);
        [split_performance(i,j), age_performance_MAE(i,j), age_performance_ACC(i,j), gender_performance(i,j)] ...
            = AgeGenderEvaluationTest(feat, datasets{i}.age(idx), datasets{i}.gender(idx), datasets{j}.age_model);
    end
end

%% report performance

weighted_cross = zeros(1, nset);
drop = zeros(1, nset);
for i = 1:nset
    weighted_cross(i) = age_data_num(setdiff(1:nset, i)) ...
        * age_performance_MAE(setdiff(1:nset, i), i)...
        /sum(age_data_num(setdiff(1:nset, i)));
    drop(i) = weighted_cross(i) - age_performance_MAE(i,i);
end

disp(weighted_cross);
% disp(drop);


% weighted_cross = zeros(1, nset);
% drop = zeros(1, nset);
% for i = 1:nset
%     weighted_cross(i) = age_data_num(setdiff(1:nset, i)) * ...
%         age_performance_ACC(setdiff(1:nset, i), i)...
%         /sum(age_data_num(setdiff(1:nset, i)));
%     drop(i) = -(weighted_cross(i) - age_performance_ACC(i,i));
% end
% 
% disp(weighted_cross);
% disp(drop);