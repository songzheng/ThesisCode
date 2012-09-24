
clear;
fprintf('**************WebFace with PCA 500***************\n');
bProject = 1;
bContextConstraint = 0;
context_name = 'VideoContext';
% context_name = 'CMUPIE';
ReducedDim = 500;
feat_name = 'HOG';%RotAware
train_set = [5];

align_names = {'AlignLv0', 'AlignLv1', 'AlignLv2'};

align_name = align_names{3};

% sufficiency = [0.01:0.01:0.09, 0.1:0.1:0.9];

if bProject
    proj_suffix = ['_ProjTo', num2str(ReducedDim)];
else
    proj_suffix = [];
end

%%
addpath ../tools
addpath(genpath('../tools'));
addpath ../feature/

if ispc
    addpath ../../data/
else
    addpath /home/data/Data_SongZheng/
end

feat_path = '../../data/features/';
model_path = '../../data/models/';

target_size = [80,80];

names = {'FGNET', 'Morph1', 'Morph2', 'Yamaha', 'WebFace'};
nset = length(names);
datasets = cell(1, nset);

test_set = [];

for i = union(train_set, test_set)
    disp(names{i});
    datasets{i}.label_names = {'age', 'gender', 'OMRONFaceDetection'};
    datasets{i}.label_args = {[], [], {'alignment', 'score_max'}};
    datasets{i}.name = names{i};
    datasets{i} = LoadDataset(datasets{i});
                
end

if strcmp(feat_name, 'BIF')    
    addpath BIFfeature/
    
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
    opts = InitializeFeature('PatchHOG', 'norient', 16, 'half_sphere', 0, 'sbin', 8, 'scales', [1, 0.75, 0.5]);
elseif strcmp(feat_name, 'HOG16')
    opts = InitializeFeature('PatchHOG', 'norient', 16, 'half_sphere', 0, 'sbin', 16, 'scales', [1, 0.75, 0.5]);    
elseif strcmp(feat_name, 'LBP')
    opts = InitializeFeature('PatchLBP', 'sbin', 8, 'scales', [1, 0.75, 0.5]);
elseif strcmp(feat_name, 'LBP16')
    opts = InitializeFeature('PatchLBP', 'sbin', 16, 'scales', [1, 0.75, 0.5]);
elseif strcmp(feat_name, 'Appearance')
    opts = InitializeFeature('PatchAppearance',...
        'codebook_name', 'WebFace',...
        'codebook_size', 256,...
        'reduced_dim', 10,...
        'sbin', 16, ...
        'scales', [1, 0.75, 0.5], ...
        'dataset', datasets{train_set(1)});    
elseif strcmp(feat_name, 'AppearanceRotAware')
     opts = InitializeFeature('PatchAppearance',...
        'codebook_name', 'WebFace',...
        'codebook_size', 32,...
        'rot_aware', 1,...
        'reduced_dim', 10,...
        'sbin', 16, ...
        'scales', [1, 0.75, 0.5], ...
        'dataset', datasets{train_set(1)});    
end


for i = union(train_set, test_set)
    tag = [datasets{i}.name, '_', feat_name, 'Feature', '_', align_name];
    
    clear feat;
    if ~exist([feat_path, tag, '.mat'], 'file')
        feat = GetFaceFeature(datasets{i}, align_name, opts);
        save([feat_path, tag], 'feat', '-v7.3');
    end
    
    % config model
    if bProject && ~exist([model_path, '/', tag, '_PCAmodel.mat'], 'file')
        if ~exist('feat', 'var')
            load([feat_path, tag]);
        end
        
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
        save([model_path, '/', tag, '_PCAmodel'], 'subspacemodel');
    end
end
agegender_eval