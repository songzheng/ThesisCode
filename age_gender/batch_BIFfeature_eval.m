addpath ..\tools
addpath(genpath('..\tools'));
addpath ..\feature\
addpath ..\..\data

feat_path = '..\..\data\features\';
model_path = '..\..\data\models\';


target_size = [80,80];
target_land_mark = complex([80/4, 80/4*3], [80/4, 80/4]);

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
    opts = FeatureInit('HOG', 'norient', 6, 'half_sphere', 1, 'sbin', 8, 'scales', [1, 0.5]);
end

for i = 1:nset
    disp(names{i});
    datasets{i}.label_names = {'age', 'gender', 'OMRONFaceDetection'};
    datasets{i}.label_args = {[], [], {'alignment', 'score_max'}};
    datasets{i}.name = names{i};
    
    datasets{i} = LoadDataset(datasets{i});
    if ~exist([feat_path, datasets{i}.name, '_', feat_name, 'Feature.mat'], 'file')
        feat = GetAlignFeature1(datasets{i}, target_size, target_land_mark, opts);
        save([feat_path, datasets{i}.name, '_', feat_name, 'Feature.mat'], 'feat', '-v7.3');
    end
end

%% train BIF models on frontal
names = {'FGNET', 'Morph1', 'Morph2', 'Yamaha', 'WebFace'};
nset = length(names);

train_set = [3,4,5];
age_data_num = zeros(1,nset);

age_limit = [1, 80];

% config model
bProject = 0;
bSplit = 0;

% select frontal faces
left_right_rot = [-10, 10];
up_down_rot = [];
score = [500, inf];
    
for i = train_set
    
    
    sel = SelectResult(datasets{i}.OMRONFaceDetection, score, left_right_rot, up_down_rot);
    
    idx = find(sel>0);
    
    age = datasets{i}.age(idx);
    gender = datasets{i}.gender(idx);
    
    train_split = [];
    ll = unique([age, gender], 'rows');
    for j = 1:size(ll,1)
        split_idx = find(age == ll(j,1) & gender == ll(j,2));
        split_idx = randsample(split_idx, round(length(split_idx)/2));
        
        train_split = [train_split; idx(split_idx)];        
    end    
    
    clear feat
    load([feat_path, datasets{i}.name, '_', feat_name, 'Feature.mat']);
    feat = feat(train_split, :);
    age = datasets{i}.age(train_split);
    gender = datasets{i}.gender(train_split);
    
    datasets{i}.age_model = AgeGenderEvaluationTrain(feat, age, gender, bProject, bSplit, [model_path, datasets{i}.name, '_', feat_name]);
end
    
%% cross set evaluation

age_performance = zeros(nset, nset, 4);

for i = 1:nset
    clear feat
    sel = SelectResult(datasets{i}.OMRONFaceDetection, score, left_right_rot, up_down_rot);
    idx = find(sel>0);
    age_data_num(i) = length(idx);
    load([feat_path, datasets{i}.name, '_', feat_name, 'Feature.mat']);
    feat = feat(idx, :);
    age = datasets{i}.age(idx);
    gender = datasets{i}.gender(idx);
    for j = train_set
        fprintf('Train on %s, Test on %s\n',  datasets{j}.name, datasets{i}.name);
        [age_performance(i,j,1), age_performance(i,j,2), age_performance(i,j,3), age_performance(i,j,4)] ...
            = AgeGenderEvaluationTest(feat, age, gender, datasets{j}.age_model);
    end
end

%% report performance

for i = 1:numel(age_performance)
    age_performance_MAE = age_performance(:,:,2);
    age_performance_ACC = age_performance(:,:,3);
end

age_performance_MAE_cross = zeros(1, nset);
age_performance_MAE_drop = zeros(1, nset);
for i = 1:nset
    age_performance_MAE_cross(i) = age_data_num(setdiff(1:nset, i)) ...
        * age_performance_MAE(setdiff(1:nset, i), i)...
        /sum(age_data_num(setdiff(1:nset, i)));
    age_performance_MAE_drop(i) = age_performance_MAE_cross(i) - age_performance_MAE(i,i);
end

disp(names);
disp(age_performance_MAE_cross);
disp(age_performance_MAE_drop);