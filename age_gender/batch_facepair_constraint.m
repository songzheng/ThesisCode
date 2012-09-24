clear
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

dataset.name = 'CMUPIE';
dataset.label_names = {'person_id', 'OMRONFaceDetection'};
dataset.label_args = {[], []};

dataset = LoadDataset(dataset);

score = [];
lr_rot = [-40, 40];

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

count_context = 0;
start_context = 1;
feat_name = 'HOG';
opts = InitializeFeature('PatchHOG', 'norient', 16, 'half_sphere', 0, 'sbin', 8, 'scales', [1, 0.75, 0.5]);
bProject = 0;
ReducedDim = 1500;
if bProject
    proj_suffix = ['_ProjTo', num2str(ReducedDim)];
else
    proj_suffix = [];
end

align_name = 'AlignLv2';
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
    tag = ['WebFace_', feat_name, 'Feature', '_', align_name];
    load([model_path, '/', tag, '_PCAmodel']);
    subspacemodel.ReducedDim = ReducedDim;
    context_mat = zeros(ReducedDim);
else
    context_mat = zeros(fdim);
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
        
    n = length(idx);
        
    context.data_root = dataset.data_root;
    context.OMRONFaceDetection = OMRONFaceDet;
    context.image_names = dataset.image_names(idx);
    clear context_feat
    context_feat = GetFaceFeature(context,align_name, opts);
        
    
    if bProject
        context_feat = EvalSubspace(context_feat, subspacemodel);
    end
    
    [n1,n2] = meshgrid(1:n);
    n1 = n1(:);
    n2 = n2(:);
        
    n = [n1(n1>n2), n2(n1>n2)];
        
    context_feat = context_feat(:, n(:,1)) - context_feat(:, n(:,2));        
    context_mat = context_mat + context_feat * context_feat';
    
    total_contraints = total_contraints+size(context_feat,2);
end

context_mat = context_mat/total_contraints;

save([feat_path, '/', dataset.name, '_Constraint_', feat_name, '_', align_name, proj_suffix], 'context_mat', '-v7.3');