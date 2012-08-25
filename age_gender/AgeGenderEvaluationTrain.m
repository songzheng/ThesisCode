function model = AgeGenderEvaluationTrain(feat, age, gender, bProject, bSplit, model_path)
age_limit = [0, 80];
model = [];
if bProject
    % if ~isfield(model, 'subspace_opt')
    %     subspace_opt.k = 4;
    %     subspace_opt.beta = 0.05;
    if ~isempty(model_path) && exist([model_path, '_subspace_model.mat'], 'file')
        load([model_path, '_subspace_model']);
    else
        subspace_opt.ReducedDim = 1500;
        %     subspace_opt.Regu = 1;
        %     subspace_opt.ReguAlpha = 0.1;
        %
        %     % train subspace
        %     feature = bsxfun(@rdivide, feature, sqrt(sum(feature.^2, 2)) + eps);
        %     model.subspace_opt = subspace_opt;
        %     [model.projection, ~, model.mean] = LSDA(label_age+age_limit(2)*label_gender, subspace_opt, feature);
        % end
        [projection, ~, mean] = PCA(feat, subspace_opt);
        if ~isempty(model_path)
            save([model_path, '_subspace_model'], 'projection', 'mean', 'subspace_opt');
        end
    end
    model.projection = projection;
    model.mean = mean;
    model.subspace_opt = subspace_opt;
end

if bSplit
    if ~isempty(model_path) && exist([model_path, '_split_model_proj', num2str(bProject), '.mat'], 'file')
        load([model_path, '_split_model_proj', num2str(bProject)]);
    else
        splitmodel = AgeGenderEvaluationTrainSplit(model, feat, age, gender, age_limit);
        if ~isempty(model_path)
            save([model_path, '_split_model_proj', num2str(bProject)], 'splitmodel');
        end
    end
    model.splitmodel = splitmodel;
end

if ~isempty(model_path) && exist([model_path, '_sub_model_proj', num2str(bProject), '_split', num2str(bSplit), '.mat'], 'file')
    load([model_path, '_sub_model_proj', num2str(bProject), '_split', num2str(bSplit)]);
else
    [submodel, splitsid] = AgeGenderEvaluationTrainSub(model, feat, age, gender, age_limit);
    if ~isempty(model_path)
        save([model_path, '_sub_model_proj', num2str(bProject), '_split', num2str(bSplit)], 'submodel', 'splitsid');
    end
end

model.submodel = submodel;
model.splits_id = splitsid;