load attribute_list

dataset_dir = 'datasets/';
subset = 'lowerbody'; %'upperbody';%'lowerbody';
label_eval = label_lower;

%% load dataset
datasets = {};

dataset = [];
dataset.dataset_dir = dataset_dir;
dataset.name = ['amazon_', subset];
dataset.name_det = [subset, '_detection'];
dataset.bNormalize = 1;
dataset.bProject = 1;
dataset.bEncode = 0;
% dataset.encoding.train_method = 'L12Rec';
% dataset.encoding.coding_method = 'L2Rec';
% dataset.encoding.codebook_size = 50;
dataset.label_eval = label_eval;
datasets{1} = LoadDataset(dataset);

dataset.name = ['flickr_', subset];
dataset.normalization = [];
dataset.projection = datasets{1}.projection;
% dataset.encoding = datasets{1}.encoding;
datasets{2} = LoadDataset(dataset);

%% test 
k = 50;
train_set = 1;
bUseProjection = 0;
label_eval = cell2mat(label_eval);
for test_set = 1:2
    fprintf('Testing on %s\n', datasets{test_set}.name);
    dismap = EuDist2(datasets{test_set}.feature, datasets{train_set}.feature);
    mean_ndcg_20 = zeros(1,length(label_eval));
    mean_ndcg_100 = zeros(1,length(label_eval));
    
    for l = 1:length(label_eval)
        label_train = datasets{train_set}.labels(:, label_eval(l));
        label_test = datasets{test_set}.labels(:, label_eval(l));
        relmap = LabelRelevenceMap(label_test, label_train);
        mean_ndcg_20(l) = RetrievalEvaluation(datasets{test_set}, datasets{train_set}, dismap, relmap, 20);
        fprintf('Attribute |%s|: mean NDCG@20 = |%0.3f|\n', attribute_list{label_eval(l)}, mean_ndcg_20(l));
        mean_ndcg_100(l) = RetrievalEvaluation(datasets{test_set}, datasets{train_set}, dismap, relmap, 100);
        fprintf('Attribute |%s|: mean NDCG@100 = |%0.3f|\n', attribute_list{label_eval(l)}, mean_ndcg_100(l));
        %     pause;
    end
    fprintf('Attribute |average|: mean NDCG@20 = |%0.3f|, NDCG@100 = |%0.3f|\n', mean(mean_ndcg_20), mean(mean_ndcg_100));
end

