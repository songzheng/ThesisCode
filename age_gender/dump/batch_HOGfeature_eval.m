addpath ..\tools
addpath(genpath('..\.tools'));
addpath ..\..\data
addpath ..\feature\

feat_path = '..\..\data\features\';
model_path = '..\..\data\models\';

dataset.label_names = {'age', 'gender', 'OMRONFaceDetection'};
dataset.label_args = {[], [], {'alignment', 'score_max'}};

target_size = [80,80];
target_land_mark = complex([80/4, 80/4*3], [80/4, 80/4]);
names = {'FGNET', 'Morph1', 'Morph2', 'Yamaha', 'WebFace'};
nset = length(names);

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
    opts = FeatureInit('HOG', 'norient', 16, 'sbin', 8);
end

for i = 1:nset
    disp(names{i});
    dataset.name = names{i};
    dataset = LoadDataset(dataset);
    if ~exist([feat_path, dataset.name, '_', feat_name, 'Feature.mat'], 'file')
        feat = GetAlignFeature1(dataset, target_size, target_land_mark, opts);
        save([feat_path, dataset.name, '_', feat_name, 'Feature.mat'], 'feat', '-v7.3');
    end
end

%% train BIF models on frontal
names = {'FGNET', 'Morph1', 'Morph2', 'Yamaha', 'WebFace'};
nset = length(names);

train_set = [3,4,5];
age_data_num = zeros(1,nset);

age_limit = [1, 80];
datasets = cell(1, nset);

% config model
bProject = 0;
bSplit = 0;

% select frontal faces
left_right_rot = [-10, 10];
up_down_rot = [];
score = [500, inf];
    
for i = train_set
    datasets{i}.label_names = {'age', 'gender', 'OMRONFaceDetection'};
    datasets{i}.label_args = {[], [], {'alignment', 'score_max'}};
    datasets{i}.name = names{i};
    disp(datasets{i}.name);
    
    datasets{i} = LoadDataset(datasets{i});

    load([feat_path, datasets{i}.name, '_BIFFeature.mat']);
    
    sel = SelectResult(dataset.OMRONFaceDetection, score, left_right_rot, up_down_rot);

    idx = find(sel>0);
    age_data_num(i) = length(idx);    
    feat = feat(idx, :);
    
    datasets{i}.age_model = [];
    if bProject
        % if ~isfield(model, 'subspace_opt')
        %     subspace_opt.k = 4;
        %     subspace_opt.beta = 0.05;
        try
            load([model_path, dataset.name, '_subspace_model']);
        catch
            subspace_opt.ReducedDim = 1500;
            %     subspace_opt.Regu = 1;
            %     subspace_opt.ReguAlpha = 0.1;
            %
            %     % train subspace
            %     feature = bsxfun(@rdivide, feature, sqrt(sum(feature.^2, 2)) + eps);
            %     model.subspace_opt = subspace_opt;
            %     [model.projection, ~, model.mean] = LSDA(label_age+age_limit(2)*label_gender, subspace_opt, feature);
            % end
            [model.projection, ~, model.mean] = PCA(feat, subspace_opt);
            model.subspace_opt = subspace_opt;
            save([model_path, dataset.name, '_subspace_model'], 'model');
        end
        datasets{i}.age_model.projection = model.projection;
        datasets{i}.age_model.mean = model.mean;
        datasets{i}.age_model.subspace_opt = model.subspace_opt;
    end
    
    
    if bSplit
        try
            load([model_path, dataset.name, '_split_model_proj', num2str(bProject)]);
        catch
            model = AgeGenderEvaluationTrainSplit(dataset.age_model, feat, dataset.age(idx), dataset.gender(idx), age_limit);
            save([model_path, dataset.name, '_split_model_proj', num2str(bProject)], 'model');
        end
        datasets{i}.age_model.splitmodel = model;
    end
    
    % try
    %     load(['model\', dataset_web.name, '_sub_model']);
    % catch
    [datasets{i}.submodel, datasets{i}.splits_id] = AgeGenderEvaluationTrainSub(dataset.age_model, feat, dataset.age(idx), dataset.gender(idx), age_limit);
    %     save(['model\', dataset_web.name, '_sub_model'], 'model', 'splits');
    % end
    
end
    
%% cross set evaluation

age_performance = zeros(nset, nset, 4);

for i = 1:nset
    clear feat
    load(['feature\', datasets{i}.name, '_BIFFeature_Frontal.mat']);
    idx = find(sel>0);
    for j = train_set
        fprintf('Train on %s, Test on %s\n',  datasets{j}.name, datasets{i}.name);
        [age_performance(i,j,1), age_performance(i,j,2), age_performance(i,j,3), age_performance(i,j,4)] ...
            = AgeGenderEvaluationTest(feat, datasets{i}.age(idx), datasets{i}.gender(idx), datasets{j}.age_model);
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