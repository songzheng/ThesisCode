function [MAE, age_acc, gender_acc] = AgeGenderEvaluationCrossValidateRegression(feat, ...
    age, gender, det,...
    lambda_age, lambda_gender, ...
    fold, suff,...
    context_mat, context_alpha,...
    tag)

fold_model = cell(1, fold);
[train_split, test_split] = SplitDataset(age, gender, det, fold, suff);

fprintf('Cross Eval on %s:\n', tag);
for f = 1:fold
    fprintf('fold %d,', f);     
    clear feat_train
    %
    %         test_split{f} = setdiff(all_idx, train_split{f});
    
    feat_train = feat(:, train_split{f});
    age_train = age(train_split{f});
    gender_train = gender(train_split{f});
        
        
    %%
    fold_model{f} = AgeGenderEvaluationTrainRegression(feat_train, ...
        age_train, gender_train, context_mat, ...
        lambda_age, lambda_gender, context_alpha);
    
end
fprintf('\n');

res_age = cell(fold, 1);
res_gender = cell(fold, 1);
for f = 1:fold
    [res_age{f}, res_gender{f}] ...
        = AgeGenderEvaluationTestRegression(feat(:,test_split{f}), fold_model{f});
end

res_age = cell2mat(res_age);
res_gender = cell2mat(res_gender);
test_split = cell2mat(test_split);

[MAE, age_acc, gender_acc] = PerformanceAnalysis(age(test_split), gender(test_split), det(test_split), ...
    res_age, res_gender);

