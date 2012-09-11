function [test_res_age, test_res_gender, performance] = AgeGenderEvaluationTest(feature, label_age, label_gender, label_view, model)
label_age = label_age(:);
label_gender = label_gender(:);
label_gender(label_age < 5) = 0;
[dim, ntest] = size(feature);

if isfield(model, 'subspacemodel')
    feature = EvalSubspace(feature, model.subspacemodel);
end

if isfield(model, 'splitmodel')
    label_split = model.func_split(label_age, label_gender);
    [test_split, acc] = LinearMultiClassSVMTest(label_split, feature, model.splitmodel);
    acc_split = acc(1);
else
    label_split = ones(ntest,1);
    test_split = ones(ntest,1);
    acc_split = 1;
end

test_res_age = zeros(ntest, 1);

for i = model.splitid(:)'
    div_idx = find(test_split == i);
    if ~isempty(div_idx)
        test_res_age(div_idx) = LinearRegressionTest(feature(:, div_idx), model.submodel{i});
    end
end

%% age
MAE = mean(abs(test_res_age - label_age));
acc_age = length(find(abs(test_res_age - label_age)<=5))/length(test_res_age);

%% gender
test_res_gender = LabelSplitGetGender(test_split);
acc_gender = length(find(test_res_gender == label_gender & label_gender~=0))/length(find(label_gender~=0));

%% view
acc_split_view = zeros(max(label_view), 1);
MAE_view = zeros(max(label_view), 1);
acc_age_view = zeros(max(label_view), 1);
acc_gender_view = zeros(max(label_view), 1);
for v = 1:max(label_view)
    view_idx = find(label_view==v);
    nview = length(view_idx);
    
    view_split = test_split(view_idx);
    view_age = test_res_age(view_idx);
    view_gender = test_res_gender(view_idx);
    view_split_gt = label_split(view_idx);
    view_age_gt = label_age(view_idx);
    view_gender_gt = label_gender(view_idx);
    
    acc_split_view(v) = length(find(view_split == view_split_gt))/nview;
    MAE_view(v) = mean(abs(view_age - view_age_gt));
    acc_age_view(v) = length(find(abs(view_age - view_age_gt)<=5))/nview;
    acc_gender_view(v) = length(find(view_gender == view_gender_gt & view_gender_gt~=0))/length(find(view_gender_gt~=0));
end

performance = [acc_split, MAE, acc_age, acc_gender;acc_split_view, MAE_view, acc_age_view, acc_gender_view];