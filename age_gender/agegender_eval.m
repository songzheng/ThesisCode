%% train BIF models on frontal
% result_path = '..\..\data\Results\';
names = {'FGNET', 'Morph1', 'Morph2', 'Yamaha', 'WebFace'};
nset = length(names);

fold = 4;
age_data_num = zeros(1,nset);

age_limit = [1, 80];

% select frontal faces
left_right_rot = [];
up_down_rot = [];
score = [];

bProject = 1;
ReducedDim = 1500;
%
age_performance = zeros(nset, nset, 4);

age_number = zeros(1, nset);
    
for i = train_set
      
    disp(names{i});    
    % select all available feature
    all_sel = SelectResult(datasets{i}.OMRONFaceDetection, score, [], []);    
    all_idx = find(all_sel);
    
%     % select frontal faces
%     frontal_sel = SelectResult(datasets{i}.OMRONFaceDetection, score, left_right_rot, up_down_rot);
%     frontal_idx = find(frontal_sel);
%     age_number_frontal(i) = length(frontal_idx);
         
    tag = [datasets{i}.name, '_', feat_name, 'Feature', '_', align_name];
        
    clear feat
    load([feat_path, tag]);
    feat = feat(:, all_sel);
    
    % evaluate subspace
    if bProject
        load([model_path, tag, '_PCAmodel']);
        subspacemodel.ReducedDim = ReducedDim;
        feat = EvalSubspace(feat, subspacemodel);
    end
        
    age = datasets{i}.age(all_sel);
    gender = datasets{i}.gender(all_sel);
    view_split = ViewSplit(datasets{i});
    view_split = view_split(all_sel);
    view_split = min(view_split, 3);
    
    age = max(min(age, age_limit(2)), age_limit(1));
    gender(age < 5) = 0;    
    
    % tune lambda on half the data
    age_group = floor(age/10);
    validation_idx = [];
    ll = unique([age_group, gender], 'rows');
    for j = 1:size(ll,1)
        split_idx = find(age_group == ll(j,1) & gender == ll(j,2));
        split_idx = randsample(split_idx, round(length(split_idx)/2));
        validation_idx = [validation_idx; split_idx];
    end
        
    best_age_lambda = 0;
    best_gender_lambda = 0;
    best_age_acc = inf;
    best_gender_acc = 0;
    
    for lambda = [3e-4, 1e-4, 3e-5, 1e-5, 3e-6, 1e-6]
        fprintf('>>>>---lambda = %d ----<<<<\n', lambda);
        [age_acc, gender_acc] = AgeGenderEvaluationCrossValidateRegression(...
            feat(:, validation_idx), ...
            age(validation_idx), ...
            gender(validation_idx), ...
            view_split(validation_idx), ...
            lambda, lambda, fold, tag);
        if age_acc < best_age_acc
            best_age_acc = age_acc;
            best_age_lambda = lambda;
        end
        
        if gender_acc > best_gender_acc
            best_gender_acc = gender_acc;
            best_gender_lambda = lambda;
        end
    end
    
    fprintf('best age lambda = %f, gender lambda = %f\n', best_age_lambda, best_gender_lambda)
    [age_acc, gender_acc] = AgeGenderEvaluationCrossValidateRegression(feat,...
        age, gender, view_split, ...
        best_age_lambda, best_gender_lambda, fold, tag);
%     save([result_path, '\', tag], 'self_performance');
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