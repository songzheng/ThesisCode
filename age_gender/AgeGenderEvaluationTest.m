function [acc_split, MAE, acc_age, acc_gender] = AgeGenderEvaluationTest(feature, label_age, label_gender, model)
label_age = label_age(:);
label_gender = label_gender(:);
label_gender(label_age < 5) = 0;
ntest = size(feature, 1);

if isfield(model, 'subspace_opt')
    feature = bsxfun(@minus, feature, model.mean) * model.projection;
    feature = bsxfun(@rdivide, feature, sqrt(sum(feature.^2, 2)) + eps);
end

if isfield(model, 'splitmodel')
    label_split = LabelSplitGender(label_age, label_gender);
    [test_split, acc] = LinearMultiClassSVMTest(label_split, feature, model.splitmodel);
    acc_split = acc(1);
else
    test_split = ones(ntest,1);
    acc_split = 1;
end

test_res = zeros(ntest, 1);

for i = model.splits_id
    div_idx = find(test_split == i);
    if ~isempty(div_idx)
        test_res(div_idx) = LinearRegressionTest(feature(div_idx, :), model.submodel{i});
    end
end

%% age
MAE = mean(abs(test_res - label_age));
acc_age = length(find(abs(test_res - label_age)<=5))/length(test_res);

%% gender
test_res_gender = LabelSplitGetGender(test_split);
acc_gender = length(find(test_res_gender == label_gender & label_gender~=0))/length(find(label_gender~=0));