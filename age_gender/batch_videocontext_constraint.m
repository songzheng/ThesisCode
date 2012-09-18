clear
addpath ..\tools
addpath(genpath('..\tools'));
addpath ..\feature\
addpath ..\..\data

feat_path = '..\..\data\features\';
model_path = '..\..\data\models\';

dataset.name = 'VideoContext';
dataset.data_root = 'G:\VideoFaceTracker\res';
dataset.label_names = {'sequence_frames', 'sequence_ids', 'sequence_num'};
dataset.label_args = {[], [], []};

dataset = LoadDataset(dataset);


score = [700, inf];
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
opts = InitializeFeature('PatchHOG', 'norient', 16, 'half_sphere', 0, 'sbin', 8, 'scales', [1, 0.75, 0.5]);
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
context_mat = zeros(fdim);

for i = 1:length(dataset.image_names)
    load([dataset.data_root, '/', dataset.image_names{i}, '/OMRONFaceDet']);
    if ~exist('OMRONFaceDet', 'var') || isempty(OMRONFaceDet)
        continue;
    end
    
    sel = SelectResult(OMRONFaceDet, score, lr_rot, []);
    OMRONFaceDet = OMRONFaceDet(sel);
    seq = dir([dataset.data_root, '/', dataset.image_names{i}, '/*.jpg']);
    
    seq = seq(sel);
    
    names = reshape([seq.name], [15, length(seq)]);
    names = names(1:8, :);
    names = names';
    [group_names, ~, group]  = unique(names, 'rows');
    ngroup = length(group_names);
        
    group_frames = hist(group, 1:ngroup);    
    
    for g = 1:ngroup
        if group_frames(g) < 2
            continue;
        end
        
        n = length(find(group == g));
        
        count_context = count_context + 1;
        
        if count_context < start_context
            continue;
        end
        
        if mod(count_context, 1000) == 0
            fprintf('%d\n', count_context);
            save([feat_path, '/', dataset.name, '_Constraint_HOG_', align_name], 'context_mat', '-v7.3');
        end        
        
        context.data_root = [dataset.data_root, '\', dataset.image_names{i}, '\'];
        context.OMRONFaceDetection = OMRONFaceDet(group == g);
        context.image_names = {seq(group == g).name};
        context_feat = GetFaceFeature(context,align_name, opts);
        
        [n1,n2] = meshgrid(1:n);
        n1 = n1(:);
        n2 = n2(:);
        
        n = [n1(n1>n2), n2(n1>n2)];
        
        context_feat = context_feat(:, n(:,1)) - context_feat(:, n(:,2));
        
        context_mat = context_mat + context_feat * context_feat'/size(n,1);
    end
    
end

save([feat_path, '/', dataset.name, '_Constraint_HOG_', align_name], 'context_mat', '-v7.3');