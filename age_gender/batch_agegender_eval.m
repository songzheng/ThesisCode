
fprintf('**************WebFace Views with Context***************\n');
train_set = [5]
test_set = [];

bContextConstraint = 0
% context_name = 'VideoContext'
context_name = 'CMUPIE'

feat_opt.name = 'HOG';%RotAware
feat_opt.suffix = [];

align_names = {'AlignLv0', 'AlignLv1', 'AlignLv2'};
feat_opt.align_name = align_names{id};
feat_opt.suffix = ['_', feat_opt.name, 'Feature', '_', feat_opt.align_name];


feat_opt.bProject = 1;
feat_opt.ReducedDim = 3000;
if feat_opt.bProject
    feat_opt.conf_suffix = ['_ProjTo', num2str(feat_opt.ReducedDim)];
else
    feat_opt.conf_suffix = [];
end

feat_opt.num_view = 1;
if feat_opt.num_view > 1
    feat_opt.conf_suffix = [feat_opt.conf_suffix, '_', num2str(num_view), 'Views'];
end

feat_opt

%%
addpath ../tools
addpath(genpath('../tools'));
addpath ../feature/

if ispc
    addpath ../../data/
else
    addpath /home/data/Data_SongZheng/
end

feat_opt.feat_path = '../../data/features/';
feat_opt.model_path = '../../data/models/';


%% select feature
script_select_feature

%% load dataset

names = {'FGNET', 'Morph1', 'Morph2', 'Yamaha', 'WebFace'};
nset = length(names);
datasets = cell(1, nset);

fprintf('Loading Dataset...\n')
for i = union(train_set, test_set)
    disp(names{i});
    datasets{i}.label_names = {'age', 'gender', 'OMRONFaceDetection'};
    datasets{i}.label_args = {[], [], {'alignment', 'score_max'}};
    datasets{i}.name = names{i};
    datasets{i} = LoadDataset(datasets{i});          
    
    tag = [datasets{i}.name, feat_opt.suffix];
    
    clear feat;
    if ~exist([feat_opt.feat_path, tag, '.mat'], 'file')
        feat = GetFaceFeature(datasets{i}, align_name, opts);
        save([feat_opt.feat_path, tag], 'feat', '-v7.3');
    end
    
end


%% train pca model

% config model
if feat_opt.bProject && ~exist([feat_opt.model_path, '/PCAmodel', feat_opt.suffix, '.mat'], 'file')
    fprintf('Training PCA Model...\n')
    % using web face to train pca model
    load([feat_opt.feat_path, 'WebFace', feat_opt.suffix]);

    all_sel = SelectResult(datasets{i}.OMRONFaceDetection, [], [], []);
    feat = feat(:, all_sel);

    % LSDA subspace model
    %     subspace_opt.Regu = 1;
    %     subspace_opt.ReguAlpha = 0.1;
    %     subspace_opt.k = 4;
    %     subspace_opt.beta = 0.05;
    %
    %     % train subspace
    %     feature = bsxfun(@rdivide, feature, sqrt(sum(feature.^2, 2)) + eps);
    %     model.subspace_opt = subspace_opt;
    %     [model.projection, ~, model.mean] = LSDA(label_age+age_limit(2)*label_gender, subspace_opt, feature);
    % end

    % PCA subspace model
    [projection, eig_v, data_mean] = PCA(feat');
    subspacemodel.projection = projection;
    subspacemodel.mean = data_mean';
    save([feat_opt.model_path, '/PCAmodel', feat_opt.suffix, '.mat'], 'subspacemodel');
end

%% start
agegender_eval