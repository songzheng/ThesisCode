clear;
addpath feature
addpath detection

load attribute_list
dataset_dir = 'datasets/';
subset = 'lowerbody';
label_eval = label_lower;

%% load fashionspace dataset
dataset = [];
dataset.dataset_dir = dataset_dir;
dataset.name = ['amazon_', subset];
dataset.name_det = [subset, '_detection'];
dataset.bEncode = 0;
dataset.batch_index = 0;
dataset.bNormalize = 1;
dataset.bProject = 1;
dataset.label_eval = label_eval;
dataset = LoadDataset(dataset);

dataset.name = ['fashionspace_', subset];

feat_total = [];
for batch = 1:3
    dataset.batch_index = batch;
    dataset = LoadDataset(dataset);
    feat_total = [feat_total; dataset.feature];
    dataset.feature = [];
end
dataset.feature = feat_total;

%% load fashionspace test
dataset2 = [];
dataset2.dataset_dir = dataset_dir;
dataset2.name = ['flickr_', subset];
dataset2.name_det = [subset, '_detection'];
dataset2.bEncode = 0;
dataset2.batch_index = 0;
dataset2.bNormalize = 1;
dataset2.bProject = 0;
dataset2.label_eval = label_eval;
dataset2 = LoadDataset(dataset2);

dataset2.bProject = 1;
dataset2.projection = dataset.projection;

dataset2.name = ['fashionspace_test_', subset];
dataset2.batch_index = 1;
dataset2 = LoadDataset(dataset2);

%% retrieval example
dismap = EuDist2(dataset2.feature, dataset.feature);
image = RetrievalExample(dataset2, dataset, dismap, 20);
imwrite(image, [subset, '.jpg']);