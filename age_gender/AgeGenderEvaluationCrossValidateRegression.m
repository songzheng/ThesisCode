function [age_acc, gender_acc] = AgeGenderEvaluationCrossValidateRegression(feat, age, gender, view_split, ...
    bProject, lambda_age, lambda_gender, fold, tag)

train_split = cell(1, fold);
test_split = cell(1, fold);
fold_model = cell(1, fold);

for f = 1:fold
    train_split{f} = [];
    test_split{f} = [];
end

age_group = floor(age/10);

ll = unique([age_group, gender], 'rows');
for j = 1:size(ll,1)
    split_idx = find(age_group == ll(j,1) & gender == ll(j,2));
    split_idx = randsample(split_idx, length(split_idx));
    
    num_per_fold = floor(length(split_idx)/fold);
    for f = 1:fold
        tt = split_idx((f-1)*num_per_fold+1:f*num_per_fold);
        tr = setdiff(split_idx, tt);
        test_split{f} = [test_split{f}; tt];
        train_split{f} = [train_split{f}; tr];
    end
end

for f = 1:fold
    fprintf(' fold %d,', f);     
    clear feat_train
    %
    %         test_split{f} = setdiff(all_idx, train_split{f});
    
    feat_train = feat(:, train_split{f});
    age_train = age(train_split{f});
    gender_train = gender(train_split{f});
        
    model = [];
    if bProject
        subspacemodel.ReducedDim = 1500;
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
        [projection, eig_v, data_mean] = PCA(feat_train', subspacemodel);
        subspacemodel.projection = projection;
        subspacemodel.mean = data_mean';
        model.subspacemodel = subspacemodel;
    end
    
    %% train model    
    if isfield(model, 'subspacemodel')
        feat_train = EvalSubspace(feat_train, model.subspacemodel);
    end
    
    model.agemodel = LinearRegressionTrain(feat_train, age_train, lambda_age);
    feat_train = feat_train(:, gender_train ~= 0);
    gender_train = gender_train(gender_train ~= 0);
    model.gendermodel = LinearRegressionTrain(feat_train, gender_train, lambda_gender);
        
    %%
    fold_model{f} = model;
    
end
fprintf('\n');
self_performance = zeros(1,3,fold);
view_performance = zeros(max(view_split), 3);
view_count = zeros(max(view_split),1);
for f = 1:fold
    [res_age, res_gender, self_performance(:,:,f), vp] ...
        = AgeGenderEvaluationTestRegression(feat(:,test_split{f}), age(test_split{f}), gender(test_split{f}), view_split(test_split{f}), fold_model{f});

    for v = 1:size(vp,1)
        view_performance(v, :) = view_performance(v, :) + vp(v, :);
        view_count(v) = view_count(v) + 1;
    end    
end

view_performance = bsxfun(@rdivide, view_performance, view_count);


fprintf('Cross validation on %s\n\t MAE \t age acc \t gender acc \n', tag);
disp( mean(self_performance,3));
disp(view_performance);

p = mean(self_performance,3);
age_acc = p(1,1);
gender_acc = p(1,3);