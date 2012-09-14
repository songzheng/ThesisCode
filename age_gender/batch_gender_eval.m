%% train BIF models on frontal
result_path = '..\..\data\Results\';
names = {'FGNET', 'Morph1', 'Morph2', 'Yamaha', 'WebFace'};
nset = length(names);

fold = 10;
age_data_num = zeros(1,nset);

age_limit = [1, 80];

% config model
bProject = 0;
bSplit = 0;

% select frontal faces
left_right_rot = [];
up_down_rot = [];
score = [];

%
age_performance = zeros(nset, nset, 4);

age_number = zeros(1, nset);
    
for i = train_set
      
    disp(names{i});
    self_performance = [];
    
    view_split = ViewSplit(datasets{i});
%     if ~strcmp(names{i}, 'WebFace')
        view_split = min(view_split, 3);
%     end
    
    
%     if strcmp(names{i}, 'WebFace')
%         score = [500, inf];
%     end
    
    % select all available feature
    all_sel = SelectResult(datasets{i}.OMRONFaceDetection, score, [], []);    
    all_idx = find(all_sel);
    
%     % select frontal faces
%     frontal_sel = SelectResult(datasets{i}.OMRONFaceDetection, score, left_right_rot, up_down_rot);
%     frontal_idx = find(frontal_sel);
%     age_number_frontal(i) = length(frontal_idx);
        
    
    tag = [datasets{i}.name, '_', feat_name, 'Feature', '_', align_name];
    
    train_split = cell(1, fold);
    test_split = cell(1, fold);
    fold_model = cell(1, fold);
    
    for f = 1:fold       
        fprintf('fold %d,', f);                
                
        age = datasets{i}.age;
        gender = datasets{i}.gender;
        
        age = max(min(age, age_limit(2)), age_limit(1));
        gender(age < 5) = 0;        
                
        train_split{f} = [];
        ll = unique([age, gender, view_split], 'rows');
        for j = 1:size(ll,1)
            split_idx = find(age == ll(j,1) & gender == ll(j,2) & view_split == ll(j,3) & all_sel);
            split_idx = randsample(split_idx, round(length(split_idx)*0.75));
            
            train_split{f} = [train_split{f}; split_idx];
        end
        
        test_split{f} = setdiff(all_idx, train_split{f});
        
        clear feat
        load([feat_path, tag]);
                   
        feat = feat(:, train_split{f});
        age = age(train_split{f});
        gender = gender(train_split{f});
        
        model_path = [];
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

            age = age(:);
            gender = gender(:);
            gender(age < 5) = 0;
            if isfield(model, 'subspacemodel')
                feat = EvalSubspace(feat, model.subspacemodel);
            end

            lambda = 1;
            model.agemodel = LinearRegressionTrain(feat, age, lambda);
            lambda = 10;
            feat = feat(:, gender ~= 0);
            model.gendermodel = LinearRegressionTrain(feat, gender(gender ~= 0), lambda);    

            if ~isempty(model_name)
                save(model_name, 'model');
            end
        end
        
        %%
        fold_model{f} = model;
        
    end
    fprintf('\n');
    
    clear feat
    load([feat_path, tag]);
    
    age = datasets{i}.age;
    gender = datasets{i}.gender;
    
    age = max(min(age, age_limit(2)), age_limit(1));
    gender(age < 5) = 0;
    for f = 1:fold    
        [res_age, res_gender, self_performance(:,:,f)] ...
            = AgeGenderEvaluationTestRegression(feat(:,test_split{f}), age(test_split{f}), gender(test_split{f}), view_split(test_split{f}), fold_model{f});      
   end
    
    
    fprintf('Train on %s, Test on %s\n\t split acc \t MAE \t age acc \t gender acc \n',...
        datasets{i}.name, datasets{i}.name);
    disp( mean(self_performance,3));
    
    save([result_path, '\', tag], 'self_performance');
%     % train overall model
%     feat = feat(all_idx, :);
%     datasets{i}.age_model = AgeGenderEvaluationTrain(feat, age(all_idx), gender(all_idx),...
%             bProject, bSplit, [model_path, tag]);
end
    
%% cross set evaluation

% for i = 1:nset
%     disp(names{i});
%     if isempty(setdiff(train_set, i))
%         continue;
%     end
%     
%         
%     sel = SelectResult(datasets{i}.OMRONFaceDetection, score, [], []);
%     all_idx = find(sel>0);
%     age_number(i) = length(all_idx);
%     
%     clear feat
%     tag = [datasets{i}.name, '_', feat_name, 'Feature', '_', align_name];
%     load([feat_path, tag]);
%     age = datasets{i}.age;
%     gender = datasets{i}.gender;
%     for j = setdiff(train_set, i);
%         [~,~,p] ...
%             = AgeGenderEvaluationTest(feat(all_idx, :), age(all_idx), gender(all_idx), datasets{j}.age_model);
%           
%         age_performance(i,j,:) = reshape(p, [1,1,4]);
%         fprintf('Train on %s, Test on %s\n\t MAE=%f, ACC = %f\n',...
%             datasets{j}.name, datasets{i}.name,...
%             age_performance(i,j,2),age_performance(i,j,3));
%     end
% end
% 
% %% report performance
% fprintf('---------------------------------------------\n');
% age_performance_MAE = age_performance(:,:,2);
% age_performance_ACC = age_performance(:,:,3);
% 
% age_performance_MAE_self = zeros(1, nset);
% age_performance_MAE_cross = zeros(1, nset);
% age_performance_MAE_drop = zeros(1, nset);
% age_performance_ACC_self = zeros(1, nset);
% age_performance_ACC_cross = zeros(1, nset);
% age_performance_ACC_drop = zeros(1, nset);
% for i = 1:nset
%     age_performance_MAE_self(i) = age_performance_MAE(i,i);
%     age_performance_ACC_self(i) = age_performance_ACC(i,i);
%     age_performance_MAE_cross(i) = age_number(setdiff(1:nset, i)) ...
%         * age_performance_MAE(setdiff(1:nset, i), i)...
%         /sum(age_number(setdiff(1:nset, i)));
%     age_performance_MAE_drop(i) = age_performance_MAE_cross(i) - age_performance_MAE(i,i);
%     
%     age_performance_ACC_cross(i) = age_number(setdiff(1:nset, i)) ...
%         * age_performance_ACC(setdiff(1:nset, i), i)...
%         /sum(age_number(setdiff(1:nset, i)));
%     age_performance_ACC_drop(i) = -(age_performance_ACC_cross(i) - age_performance_ACC(i,i));
% end
% 
% disp(names);
% disp(age_performance_MAE_self);
% disp(age_performance_MAE_cross);
% disp(age_performance_MAE_drop);
% disp(age_performance_ACC_self);
% disp(age_performance_ACC_cross);
% disp(age_performance_ACC_drop);
% 
% fprintf('---------------------------------------------\n');