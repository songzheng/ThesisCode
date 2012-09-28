
fprintf('**************CMUPIE Context***************\n');

feat_name = 'HOG'%RotAware
feat_suffix = ['_', feat_name, 'Feature'];

align_names = {'AlignLv0', 'AlignLv1', 'AlignLv2'};
align_name = align_names{3}

bProject = 1
ReducedDim = 3000
if bProject
    proj_suffix = ['_ProjTo', num2str(ReducedDim)];
else
    proj_suffix = [];
end

num_view = 1
if num_view > 1
    view_suffix = ['_', num2str(num_view), 'Views'];
else
    view_suffix = [];
end

feat_suffix = [feat_suffix, '_', align_name]
opt_suffix = [proj_suffix, view_suffix]


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

%% 
script_select_feature
%%

dataset.name = 'CMUPIE';
dataset.label_names = {'person_id', 'OMRONFaceDetection'};
dataset.label_args = {[], []};

dataset = LoadDataset(dataset);

score = [];
lr_rot = [-60, 60];
% lr_rot = [-40, 40];

% count = 0;
% 
% for i = 1:length(dataset.image_names)
%     clear OMRONFaceDet
%     load([dataset.data_root, '\', dataset.image_names{i}, '\OMRONFaceDet']);
%     if ~exist('OMRONFaceDet', 'var') || isempty(OMRONFaceDet)
%         continue;
%     end
%     sel = SelectResult(OMRONFaceDet, score, lr_rot, []);
%     count = count + sum(sel);
% end

func = str2func(['GetFeature', align_name]);

% example det
npoints = 87;
det.det = [1,1,80,80;1,80,1,80] - 1;
det.part = [20,60;20,20] - 1;
det.contour = [ones(1, npoints); ones(1,npoints)];
det.rotation = [0,0,0];
f = func(zeros([80,80], 'uint8'), det, opts);

fdim = length(f);
if bProject
    % use projection learned from web face
    tag = ['WebFace', feat_suffix];
    load([model_path, '/', tag, '_PCAmodel']);
    subspacemodel.ReducedDim = ReducedDim;
    context_mat = zeros(ReducedDim*num_view);
else
    context_mat = zeros(fdim*num_view);
end

% persons
[persons, ignore, person_idx] = unique(dataset.person_id);
total_contraints = 0;
for i = 1:length(persons)
    fprintf('Context from person %s\n', persons{i});
    idx = find(person_idx == i);    
    OMRONFaceDet = dataset.OMRONFaceDetection(idx);    
    sel = SelectResult(OMRONFaceDet, score, lr_rot, []);
    
    OMRONFaceDet = OMRONFaceDet(sel);
    idx = idx(sel);
        
    [view_split, view_conf] = ViewSplit(OMRONFaceDet, num_view);    
    
    n = length(idx);
        
    context.data_root = dataset.data_root;
    context.OMRONFaceDetection = OMRONFaceDet;
    context.image_names = dataset.image_names(idx);
    clear context_feat
    context_feat = GetFaceFeature(context,align_name, opts);
    
    if bProject
        context_feat = EvalSubspace(context_feat, subspacemodel);
    end
    
    context_feat = GenerateMultiViewFeature(context_feat, view_conf);
        
    
    [n1,n2] = meshgrid(1:n);
    n1 = n1(:);
    n2 = n2(:);
    
    if num_view > 1
        valid_pairs = (n1 > n2) & (view_split(n1) ~= view_split(n2));
    else
        valid_pairs = (n1 > n2);
    end
        
    pairs = [n1(valid_pairs), n2(valid_pairs)];
        
    context_feat = context_feat(:, pairs(:,1)) - context_feat(:, pairs(:,2));        
    context_mat = context_mat + context_feat * context_feat';
    
    total_contraints = total_contraints+size(pairs,1);
end

context_mat = context_mat/total_contraints;

save([feat_path, '/', dataset.name, '_Constraint', feat_suffix, opt_suffix], 'context_mat', '-v7.3');