function splitmodel = AgeGenderEvaluationTrainSplit(model, feature, label_age, label_gender, age_limit)
addpath ..\LinearClassifier
nsample = size(feature,1);
dim = size(feature,2);

label_age = label_age(:);
label_gender = label_gender(:);
label_age = max(min(label_age, age_limit(2)), age_limit(1));

label_split = LabelSplitGender(label_age, label_gender);

if ~exist('model', 'var')
    model = [];
end

if isfield(model, 'subspace_opt')
    feature_proj = bsxfun(@minus, feature, model.mean) * model.projection;
    feature_proj = bsxfun(@rdivide, feature_proj, sqrt(sum(feature_proj.^2, 2)) + eps);
    clear feature
    splitmodel = LinearMultiClassSVMTrain(label_split, feature_proj, []);
else
    splitmodel = LinearMultiClassSVMTrain(label_split, feature, []);
end

splitmodel.func_split = @LabelSplitGender;