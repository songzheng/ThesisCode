function model = AgeGenderEvaluationTrainSplit(model, feature, label_age, label_gender)
[dim, nsample] = size(feature);

if ~isfield(model, 'func_split')
    model.func_split = @LabelSplitGender;
end

label_age = label_age(:);
label_gender = label_gender(:);
label_split = model.func_split(label_age, label_gender);

if ~exist('model', 'var')
    model = [];
end

if isfield(model, 'subspacemodel')
    feature = EvalSubspace(feature, model.subspacemodel);
end

model.splitmodel = LinearMultiClassSVMTrain(label_split, feature, []);
model.splitid = model.splitmodel.class_labels;