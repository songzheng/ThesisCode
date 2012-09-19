function [test_res_age, test_res_gender, performance, view_performance] = AgeGenderEvaluationTestRegression(feature, label_age, label_gender, label_view, model)
label_age = label_age(:);
label_gender = label_gender(:);
label_gender(label_age < 5) = 0;
[dim, ntest] = size(feature);

if isfield(model, 'subspacemodel')
    feature = EvalSubspace(feature, model.subspacemodel);
end

test_res_age = LinearRegressionTest(feature, model.agemodel);
test_res_gender = LinearRegressionTest(feature, model.gendermodel);
test_res_gender(test_res_gender < 1.5) = 1;
test_res_gender(test_res_gender >= 1.5) = 2;

%% age
MAE = mean(abs(test_res_age - label_age));
acc_age = length(find(abs(test_res_age - label_age)<=5))/length(test_res_age);

%% gender
acc_gender = length(find(test_res_gender == label_gender & label_gender~=0))/length(find(label_gender~=0));

%% view
MAE_view = zeros(max(label_view), 1);
acc_age_view = zeros(max(label_view), 1);
acc_gender_view = zeros(max(label_view), 1);
for v = 1:max(label_view)
    view_idx = find(label_view==v);
    nview = length(view_idx);
    
    view_age = test_res_age(view_idx);
    view_gender = test_res_gender(view_idx);
    
    view_age_gt = label_age(view_idx);
    view_gender_gt = label_gender(view_idx);
    
    MAE_view(v) = mean(abs(view_age - view_age_gt));
    acc_age_view(v) = length(find(abs(view_age - view_age_gt)<=5))/nview;
    acc_gender_view(v) = length(find(view_gender == view_gender_gt & view_gender_gt~=0))/length(find(view_gender_gt~=0));
end

performance = [MAE, acc_age, acc_gender];
view_performance = [MAE_view, acc_age_view, acc_gender_view];