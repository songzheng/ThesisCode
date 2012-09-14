function codebook = TrainVQCodebook(data, feat_opt, coding_opt)
nimage = length(data.image_names);

num_training_data = max(1,floor(coding_opt.codebook_size/500))*50000;
training_data = zeros(feat_opt.length, num_training_data);
training_ptr = 0;

ntrain = min(1000, nimage);
num_train_per_image = ceil(num_training_data/ntrain);

sampling = InitializeSampling('scales', [1,0.75,0.5]);

fprintf('Collecting Data...');
for i = randsample(1:nimage,ntrain)
    
    if mod(i, round(ntrain/20)) == 0
        fprintf('.');
    end
    
    im = imread([data.data_root, '\', data.image_names{i}]);
    
    if isfield(data, 'boxes') 
        if isempty(data.boxes{i})
            continue
        else
            im = im(data.boxes{i}(2,1):data.boxes{i}(2, 4), data.boxes{i}(1,1):data.boxes{i}(1,4), :);
        end
    end
       
    
    feat = ExtractFeature(im, feat_opt, sampling);
    
    for j = 1:length(feat)
        feat{j} = reshape(feat{j}, [size(feat{j},1), size(feat{j},2)*size(feat{j},3)]);
    end
    feat = cell2mat(feat);
    
    ndata = min([num_train_per_image, num_training_data - training_ptr, size(feat,2)]);
    
    training_data(:, training_ptr+1:training_ptr+ndata) = feat(:, randsample(size(feat,2), ndata));
    training_ptr = training_ptr + ndata;    
end

fprintf('\n');
num_training_data = training_ptr;
training_data = training_data(:, 1:num_training_data);

if isfield(coding_opt, 'reduced_dim')
    reduced_dim = coding_opt.reduced_dim;
    [codebook.projection, eig_value, codebook.mean] = PCA(training_data');
    codebook.mean = codebook.mean';
    codebook.projection = bsxfun(@rdivide, codebook.projection, sqrt(eig_value)');
    codebook.projection = codebook.projection(:, 1:coding_opt.reduced_dim);
    training_data = bsxfun(@minus, training_data, codebook.mean);
    training_data = codebook.projection'*training_data;
    training_data = bsxfun(@rdivide, training_data, sqrt(sum(training_data.^2,1))+eps);
else
    reduced_dim = 0;
end


vlfeat_dir = '..\tools\vlfeat\toolbox';
addpath(vlfeat_dir);
vl_setup;
fprintf('Learning Codebook...\n');
codebook.base = vl_kmeans(training_data, coding_opt.codebook_size);

if isfield(coding_opt, 'reduced_dim')
    codebook.base = bsxfun(@rdivide, codebook.base, sqrt(sum(codebook.base.^2,1))+eps);
end

codebook.nDim = feat_opt.length;
codebook.nBase = coding_opt.codebook_size;
codebook.nReducedDim = reduced_dim;

