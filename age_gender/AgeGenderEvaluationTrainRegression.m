function model = AgeGenderEvaluationTrainRegression(feat_train, ...
    age_train, gender_train, context_mat, ...
    lambda_age, lambda_gender, context_alpha,...
    weight_train)

model = [];

if ~exist('weight_train', 'var')
    weight_train = [];
end

% train model
if ~isempty(context_mat)
    model.agemodel = LinearRegressionTrainWithContext(feat_train, age_train, lambda_age, context_mat, context_alpha, weight_train);
else
    model.agemodel = LinearRegressionTrain(feat_train, age_train, lambda_age, weight_train);
end
feat_train = feat_train(:, gender_train ~= 0);
gender_train = gender_train(gender_train ~= 0);
if ~isempty(weight_train)
    weight_train = weight_train(gender_train ~= 0);
end
if ~isempty(context_mat)
    model.gendermodel = LinearRegressionTrainWithContext(feat_train, gender_train, lambda_gender, context_mat, context_alpha, weight_train);
else
    model.gendermodel = LinearRegressionTrain(feat_train, gender_train, lambda_gender, weight_train);
end