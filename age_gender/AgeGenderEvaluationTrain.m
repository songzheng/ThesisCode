function model = AgeGenderEvaluationTrain(feat, label_age, label_gender, bProject, model_path)


if ~isempty(model_path)
    model_name = [model_path, '_model_proj', num2str(bProject), '_split', num2str(bSplit)];
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
    [projection, ~, mean] = PCA(feature, subspacemodel);
    subspacemodel.projection = projection;
    subspacemodel.mean = mean;
    subspacemodel.subspace_opt = subspace_opt;
    model.subspacemodel = subspacemodel;
    if ~isempty(model_name)
        save(model_name, 'model');
    end
end

if bSplit && ~isfield(model, 'splitmodel')
    model = AgeGenderEvaluationTrainSplit(model, feature, age, gender);
    if ~isempty(model_name)
        save(model_name, 'model');
    end
else    
    model.splitid = 1;
end

model = AgeGenderEvaluationTrainSub(model, feature, age, gender);
if ~isempty(model_name)
    save(model_name, 'model');
end