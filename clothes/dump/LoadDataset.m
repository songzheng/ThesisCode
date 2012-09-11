function dataset = LoadDataset(dataset)
addpath feature
addpath detection
addpath 'D:\My Documents\My Work\Util\vlfeat-0.9.8\toolbox'

addpath 'D:\My Documents\My Work\Occupation Classification\Human Role Classification\classification\spams-matlab\'
current_dir = pwd;
cd 'D:\My Documents\My Work\Occupation Classification\Human Role Classification\classification\spams-matlab\'
start_spams;
cd(current_dir);

vl_setup;
close all
plot_performance = 0;
dataset_dir = dataset.dataset_dir;
name = dataset.name;
bNormalize = dataset.bNormalize;
bProject = dataset.bProject;
bEncode = dataset.bEncode;
label_eval = dataset.label_eval;
if ~isfield(dataset, 'batch_index')
    batch_index = 1;
else
    batch_index = dataset.batch_index;
end

%% 
fprintf('Loading Information of Dataset %s...\n', name);
try
    dataset_info = load([dataset_dir, name, '_infor']);
catch
    error('Dataset not exist');
end

% image path
if isfield(dataset_info, 'all_img_index')
    dataset.images = dataset_info.all_img_index;
else
    error('dataset original image not found');
end
nimage = length(dataset.images);

% label
if isfield(dataset_info, 'all_label')
    labels = dataset_info.all_label;
    dataset.labels = labels;
    bEval = 1;
else
    bEval = 0;
    fprintf('Dataset label not found\n');
end

%% detection information
detection_info = load(dataset.name_det);
dataset.part_names = detection_info.part_names;
dataset.detection_model = detection_info.model;
dataset.part_idx = detection_info.part_idx;

if isempty(detection_info.model)
    error('Detection model is not found');
end

if isfield(dataset_info, 'all_img_box')
    bDetect = false;
    dataset.image_boxes = dataset_info.all_img_box;
else
    bDetect = true;
    fprintf('Dataset image detection not found\n');
end

% perform detection first
if bDetect
    fprintf('Detecting boxes\n');
    all_img_box = cell(nimage, 1);
    for i = 1:nimage
        if mod(i, 100) == 0
            fprintf('.');
        end
        path = [dataset_dir, '/', dataset.images{i}];
        im = imread(path);
        all_img_box{i} = DetectPartBox(im, dataset.detection_model, dataset.name_det);
%         if all_img_box{i}(end) < -0.5
%             continue;
%         end
%         showboxes(im, all_img_box{i})
        pause
    end
    save([dataset_dir, name, '_infor'], 'all_img_box', '-append');
    fprintf('\n');
    dataset.image_boxes = all_img_box;
end

%% feature config
try
    feat_opt = load([dataset_dir, 'feat_opt.mat'],...
        'Priors_skin','Mu_skin','Sigma_skin',...
        'Priors_nonskin','Mu_nonskin','Sigma_nonskin',...
        'all_center', 'win_size', 'feat_funcs', 'feature_names');
catch
    error('Feature Configuration not Exist');
end

dataset.feat_opt = feat_opt;
dataset.feature_names = feat_opt.feature_names;


im = imread([dataset_dir, '/', dataset.images{1}]);
box = dataset.image_boxes{1};
[feat_ex, feat_idx_split] = ExtractFeatureRaw(im, box, feat_opt);
ndim = length(feat_ex);
dataset.feat_idx_split = feat_idx_split;

%% split batch
memory_limit = 3;
batch_size = floor(memory_limit*2^30/8/ndim);
batch_num = ceil(nimage/batch_size);
batch_index = batch_index(batch_index<=batch_num & batch_index >0);
dataset.batch_index = batch_index;

if isempty(batch_index)
    suffix = '';
    dataset.image_idx = [];
else
    if batch_index == 1
        suffix = '';
    else
        suffix = ['_', num2str(batch_index)];
    end
    image_idx = (batch_index-1)*batch_size+1:min(batch_index*batch_size, nimage);
    dataset.image_idx = image_idx;
end

%% feature extraction
fprintf('Loading Raw Feature of Dataset %s batch %d...\n', name, batch_index);
if ~isempty(batch_index)
    try
        load([dataset_dir, name, '_raw', suffix], 'feat_raw');
    catch
        fprintf('Extracting features\n');
        
        feat_raw = zeros(length(image_idx), ndim);
        for i = 1:length(image_idx)
            if mod(i, 100) == 0
                fprintf('.');
            end
            path = [dataset_dir, '/', dataset.images{image_idx(i)}];
            box = dataset.image_boxes{image_idx(i)};
            im = imread(path);
            %         showboxes(im, box(1,:));
            feat_raw(i, :) = ExtractFeatureRaw(im, box, feat_opt);
        end
        fprintf('\n');
        save([dataset_dir, name, '_raw', suffix], 'feat_raw', 'image_idx', '-v7.3');
    end
else
    feat_raw = [];
end

%% normalization
if bNormalize
    fprintf('Feature Normalization of Dataset %s...\n', name);
    
    if ~isfield(dataset, 'normalization') || isempty(dataset.normalization)    
        % train normalization before projection
        try
            load([dataset_dir, name, '_normalization', suffix]);
        catch
            normalization.mean = mean(feat_raw, 1);
            normalization.std = std(feat_raw, 1) + eps;
            save([dataset_dir, name, '_normalization', suffix], 'normalization');
        end
        dataset.normalization = normalization;
    end
    
    % apply normalization
    feat_raw = NormalizeFeature(feat_raw, dataset);
end

%% learning based encoding
if bEncode
    fprintf('Encoding Feature of Dataset %s batch %d...\n', name, batch_index);
    
    if ~isfield(dataset.encoding, 'codebook') || isempty(dataset.encoding.codebook)
        codebook_size = dataset.encoding.codebook_size;
        train_method = dataset.encoding.train_method;
        
        try
            load([dataset_dir, name, '_encoding', suffix, '_', train_method, num2str(codebook_size)]);
        catch
            
            feat_idx_split_coded = cell(size(feat_idx_split));
            codebook = cell(size(feat_idx_split));
            
            feat_cnt = 1;
            
            for i = 1:numel(feat_idx_split)
                fprintf('.');
                codebook{i} = EncodeTrain(feat_raw(:, feat_idx_split{i})', dataset.encoding);
                feat_idx_split_coded{i} = feat_cnt:feat_cnt+size(codebook{i}.basis, 2)-1;
                feat_cnt = feat_cnt + size(codebook{i}.basis, 2);
            end
            
            save([dataset_dir, name, '_encoding', suffix, '_', train_method, num2str(codebook_size                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             )], 'codebook', 'feat_idx_split_coded');
        end
        fprintf('\n');
        
        dataset.encoding.codebook = codebook;
        dataset.encoding.feat_idx_split = feat_idx_split_coded;
    end
    feat_idx_split = dataset.encoding.feat_idx_split;
    feat_raw = EncodeFeature(feat_raw, dataset);
end

%% attribute encoding
if bProject    
    load attribute_list
    fprintf('Feature Projection of Dataset %s...\n', name);
    
    if ~isfield(dataset, 'projection')
        
        if ~bEval
            error('Data attribute label information missing');
        end
        
        dataset.projection.vector = [];
        dataset.projection.feat_idx_split = [];
        
        try
            load([dataset_dir, name, '_projection']);
        catch
            
            % train projection and select projection map
            
            total_performance = [];
            
            projection = cell(length(label_eval),length(dataset.part_names));
            performance = cell(length(label_eval),length(dataset.part_names));
            for p = 1:length(dataset.part_idx)
                idx = feat_idx_split(:, dataset.part_idx{p});
                idx = cell2mat(idx(:)');
                
                fprintf('Part %s, Attribute:\n', dataset.part_names{p});
                K = feat_raw(:, idx)*feat_raw(:, idx)';               
                                
                for l = 1:length(label_eval)
                    label = labels(:, label_eval{l});
                    [label, label_set] = ExpandLabel(label);
                    
                    ans_list = [];
                    fprintf('Attribute Projection Learning:');
                    for ll = 1:length(label_eval{l})
                        fprintf('%s', attribute_list{label_eval{l}(ll)});
                        ans_list = [ans_list, attribute_ans_list{label_eval{l}(ll)}(label_set{ll})];
                    end
                    fprintf('\n');
                    
                    % dump for showing examples
                    %         for a = label_set{1}'
                    %              img_idx = find(labels(:, l) == a);
                    %              img_idx = randsample(img_idx, min(24, length(img_idx)));
                    %              if length(img_idx) < 24
                    %                  img_idx = [img_idx(:); ones(24-length(img_idx),1)];
                    %              end
                    %              cd(dataset_dir);
                    %              addpath ..
                    %              figure;
                    %              DrawImageFrame(dataset.images(reshape(img_idx,[3,8])));
                    %              title(attribute_ans_list{l}{a});
                    %              cd ..
                    %         end
                    %
                    
                    %         feature = zeros(nimage, size(labels,2));
                    
                    projection{l,p} = cell(size(label,2),1);
                    performance{l,p} = zeros(size(label,2),1);
                    
                    
                    for j = 1:size(label, 2)
                        fprintf('%s,', ans_list{j});
                        [projection{l,p}{j}, performance{l,p}(j)] = LearnProjection(feat_raw(:, idx), K, label(:, j));
                        
                        score = feat_raw(:, idx) * projection{l,p}{j}.w ...
                            + projection{l,p}{j}.b;
                        projection{l,p}{j}.score_min = min(score);
                        projection{l,p}{j}.score_scale = max(score) - min(score);
                        projection{l,p}{j}.idx = idx;
                    end
                    fprintf('\n');
                end
            end
            
            save([dataset_dir, name, '_projection'], 'projection', 'performance');
        end
        
        dataset.projection.vector = projection;
        dataset.projection.map = ones(size(projection));
        dataset.projection.feat_idx_split = cell(size(dataset.projection.vector));
        cnt = 1;
        for i = 1:numel(dataset.projection.vector)
            dataset.projection.feat_idx_split{i} = cnt:cnt+length(dataset.projection.vector{i})-1;
            cnt = cnt + length(dataset.projection.vector{i});
        end
        dataset.projection.length = cnt - 1;
        
        % list performance for each label
        %         for j = 1:size(label, 2)
        %             rand_performance = GetRandomPerformance(label(:, j));
        %             performance_difference = performance(:,j)-rand_performance;
        %
        %             % find relative projections
        %             th = max(performance_difference)*0.8;
        %             pidx = find(performance_difference > th);
        %
        %             part_idx = ceil(pidx/size(feat_idx_split,1));
        %             pidx = pidx + count_proj;
        %
        %             for p = 1:length(pidx)
        %                 dataset.projection_map{l, part_idx(p)} = [dataset.projection_map{l, part_idx(p)};pidx(p)];
        %             end
        %
        %             count_proj = count_proj + size(projection, 1);
        %
        %             if plot_performance
        %                 fprintf('\tLabel %s: best %+.1f%%, worst %+.1f%%\n',...
        %                     attribute_ans_list{l}{j},...
        %                     max(performance_difference(:))*100,...
        %                     min(performance_difference(:))*100);
        %             end
        %         end
        
        
        
        % plot performance compare
%         figure;
%         imagesc(total_performance);
%         imLabel(dataset.part_names, 'left', 0, {'Interpreter', 'none'});
%         imLabel(ans_list, 'bottom', 90, {'Interpreter', 'none'});
%         title('Projection Evaluation');
    end
    % apply project
    feat_raw = ProjectFeature(feat_raw, dataset);
%     dataset.feature = feature;
%     dataset.feature = feat_raw;
end

dataset.feature = feat_raw;


