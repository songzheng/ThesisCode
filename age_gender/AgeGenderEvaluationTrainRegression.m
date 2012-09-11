function model = AgeGenderEvaluationTrainRegression(feat, label_age, label_gender, bProject, model_path)

if ~isempty(model_path)
    model_name = [model_path, '_model_regression_proj', num2str(bProject)];
else
    model_name = [];
end

if ~isempty(model_name) && exist([model_name, '.mat'], 'file')
    load(model_name);
else
    model = [];
end

if bProject && ~isfield(model, 'subspacemodel')
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
    [projection, ~, mean] = PCA(feat', subspacemodel);
    subspacemodel.projection = projection;
    subspacemodel.mean = mean';
    model.subspacemodel = subspacemodel;
    if ~isempty(model_name)
        save(model_name, 'model');
    end
end

%% train model
if ~isfield(model, 'agemodel') || ~isfield(model, 'gendermodel')
    [dim, nsample] = size(feat);

    label_age = label_age(:);
    label_gender = label_gender(:);
    label_gender(label_age < 5) = 0;
    if isfield(model, 'subspacemodel')
        feat = EvalSubspace(feat, model.subspacemodel);
    end
    
    lambda = 1;
    model.agemodel = LinearRegressionTrain(feat, label_age, lambda);
    lambda = 10;
    feat = feat(:, label_gender ~= 0);
    model.gendermodel = LinearRegressionTrain(feat, label_gender(label_gender ~= 0), lambda);    
    
    if ~isempty(model_name)
        save(model_name, 'model');
    end
end