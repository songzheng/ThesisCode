function [submodel, unique_splits] = AgeGenderEvaluationTrainSub(model, feature, label_age, label_gender, age_limit)
%% preparation
nsample = size(feature,1);
dim = size(feature,2);

label_age = label_age(:);
label_gender = label_gender(:);
label_age = max(min(label_age, age_limit(2)), age_limit(1));
label_age = label_age(:);

if ~exist('model', 'var')
    model = [];
end

if isfield(model, 'splitmodel')
    label_split = model.splitmodel.func_split(label_age, label_gender);
else
    label_split = ones(nsample,1);
end




%% self cross validation
% nfold = 10;
% train_ratio = 0.5;
% 
% MAE = zeros(1, nfold);
% acc_age = zeros(1, nfold);
% acc_split = zeros(1, nfold);
% acc_gender = zeros(1, nfold);
% 
% lambda = 1;
% unique_splits = unique(label_split);
% unique_splits = unique_splits(:)';
% model.unique_splits = unique_splits;
% 
% if isfield(model, 'subspace_opt')
%     feature_proj = bsxfun(@minus, feature, model.mean) * model.projection;
%     feature_proj = bsxfun(@rdivide, feature_proj, sqrt(sum(feature_proj.^2, 2)) + eps);
%     K = feature_proj * feature_proj';
%     model.feat = feature_proj;
% else
%     K = feature * feature';
%     model.feat = feature;
% end
% 
% for f = 1:nfold    
%     train_idx = [];
%     test_idx = [];   
%         
%     % train split model
%     for i = unique_splits
%         div_idx = find(label_split == i);        
%         train_idx1 = randsample(div_idx, round(length(div_idx)*train_ratio));
%         test_idx1 = setdiff(div_idx, train_idx1);
%         train_idx{i} = train_idx1(:)';
%         test_idx{i} = test_idx1(:)';        
%     end
%     
%     train_total = cell2mat(train_idx);
% 
%     model.split = svmtrain(label_split(train_total), [(1:length(train_total))', K(train_total, train_total)], sen);
%     model.split_sv = train_total;
%     
%     % train sub model
%     model.sub = [];
%     for i = unique_splits            
%         if isfield(model, 'subspace_opt')
%             feature_train = feature_proj(train_idx{i}, :);
%         else
%             feature_train = feature(train_idx{i}, :);
%         end
%         
%         model.sub{i} = LinearRegressionTrain(feature_train, label_age(train_idx{i}), lambda);
% %         model.sub{i} = LinearClassificationTrain([], label_age(train_idx{i}), K(train_idx{i}, train_idx{i}));
%         model.sub{i}.sv = train_idx{i};
%     end
%     
%     % test on split   
%     test_total = cell2mat(test_idx);
%     [acc_split(f), MAE(f), acc_age(f), acc_gender(f)] = ...
%         AgeGenderEvaluationTest(feature(test_total, :), ...
%         label_age(test_total), label_gender(test_total), ...
%         model);
% end
% 
% Performance = [acc_split; MAE;acc_age;acc_gender];
% % report
% fprintf('Eval fold = %d, train_ratio = %d:\n', nfold, train_ratio);
% fprintf('Acc of Split = %f(%f), MAE = %f(%f), Acc in 5 years = %f(%f), Acc of gender = %f(%f)\n',...
%     mean(acc_split), std(acc_split), mean(MAE), std(MAE), mean(acc_age), std(acc_age), mean(acc_gender), std(acc_gender));
% 
% Performance = mean(Performance, 2);

%% train overall model

% train sub model
unique_splits = unique(label_split);
unique_splits = unique_splits(:)';
submodel = [];
train_idx = [];

if isfield(model, 'subspace_opt')
    feature = bsxfun(@minus, feature, model.mean) * model.projection;
    feature = bsxfun(@rdivide, feature, sqrt(sum(feature.^2, 2)) + eps);
end

% train split model
lambda = 1;
if length(unique_splits) == 1
    submodel{unique_splits} = LinearRegressionTrain(feature, label_age, lambda);
else    
    for i = unique_splits
        div_idx = find(label_split == i);
        train_idx{i} = div_idx(:)';
        
        feature_train = feature(train_idx{i}, :);
        submodel{i} = LinearRegressionTrain(feature_train, label_age(train_idx{i}), lambda);
    end
end
