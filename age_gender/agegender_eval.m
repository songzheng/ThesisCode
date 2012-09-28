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

%
age_performance = zeros(nset, nset, 4);
age_number = zeros(1, nset);  
    

for i = train_set
    fprintf('Using training set...\n');
    
    %% load data
    disp(names{i});    
    
%     % select frontal faces
%     frontal_sel = SelectResult(datasets{i}.OMRONFaceDetection, score, left_right_rot, up_down_rot);
%     frontal_idx = find(frontal_sel);
%     age_number_frontal(i) = length(frontal_idx);
         
        
    [feat, age, gender, det] = LoadFeature(datasets{i}, feat_opt);

    % load context
    if bContextConstraint
        load([feat_opt.feat_path, context_name, '_Constraint', feat_opt.suffix, feat_opt.conf_suffix]);
    else
        context_mat = [];
    end
    
    
    %% tuning on cross validation
    
    % tune age and gender lambda on half the data
    fprintf('>>>>----tune using cross validation----<<<<\n');
    try
        load([feat_opt.model_path, '/', datasets{i}.name, '_BestLambda', feat_opt.suffix, feat_opt.conf_suffix]);
    catch
        best_age_lambda = 0;
        best_gender_lambda = 0;
        best_age_acc = 0;
        best_MAE = inf;
        best_gender_acc = 0;

        for lambda = [3e-4, 1e-4, 3e-5, 1e-5, 3e-6, 1e-6]
            fprintf('>>>>---lambda = %d ----<<<<\n', lambda);
            [MAE, age_acc, gender_acc] = AgeGenderEvaluationCrossValidateRegression(...
                feat, ...
                age, ...
                gender, ...
                det, ...
                lambda, lambda, ...
                fold, [], ...
                [],[],...
                [feat_opt.suffix,feat_opt.conf_suffix]);
            if MAE < best_MAE
                best_MAE = MAE;
                best_age_acc = age_acc;
                best_age_lambda = lambda;
            end

            if gender_acc > best_gender_acc
                best_gender_acc = gender_acc;
                best_gender_lambda = lambda;
            end
        end
        
        save([feat_opt.model_path, '/', datasets{i}.name, '_BestLambda', feat_opt.suffix, feat_opt.conf_suffix],...
            'best_age_lambda', 'best_gender_lambda', 'best_MAE','best_age_acc', 'best_gender_acc');
    end
    
    fprintf('best age lambda = %f, gender lambda = %f\n', best_age_lambda, best_gender_lambda);
    fprintf('MAE\tage acc\tgender acc\n');
    fprintf('%f\t%f\t%f\n', best_MAE, best_age_acc, best_gender_acc);
    
    
    sufficiency = [0.02:0.02:0.08, 0.1:0.2:0.9];
    performance = [];
    
    for s = sufficiency
        fprintf('>>>>----evaluate on set %s with %s sufficiency---<<<<\n', datasets{i}.name, s);
        
        [MAE, age_acc, gender_acc] = AgeGenderEvaluationCrossValidateRegression(...
            feat, ...
            age, ...
            gender, ...
            det, ...
            best_age_lambda, best_gender_lambda, ...
            fold, s, ...          
            [],[],...
            [feat_opt.suffix,feat_opt.conf_suffix]);
        
        performance(end+1, :) = [MAE, age_acc, gender_acc];
    end
    
    fprintf('>>>>----summary----<<<<\n')
    disp([sufficiency', performance]);
    
    if bContextConstraint
        
        performance_context = [];
        for s = sufficiency
            fprintf('>>>>----evaluate on set %s with %s sufficiency and context---<<<<\n', datasets{i}.name, s);
            best_context_MAE = inf;
            best_context_age_acc = 0;
            best_context_gender_acc = 0;
            best_context_alpha = 0;
            
            for alpha = [0.5:0.05:0.95, 1./(0.5:0.05:0.95)];
                fprintf('****Evaluate with Context alpha = %f****\n', alpha)
                
                
                [MAE, age_acc, gender_acc] = AgeGenderEvaluationCrossValidateRegression(...
                    feat, ...
                    age, ...
                    gender, ...
                    det, ...
                    best_age_lambda, best_gender_lambda, ...
                    fold, s, ...
                    context_mat,alpha,...
                    [feat_opt.suffix,feat_opt.conf_suffix]);
                
                if MAE < best_context_MAE
                    best_context_alpha = alpha;
                end
                
                best_context_MAE = min(best_context_MAE, MAE);
                best_context_age_acc = max(best_context_age_acc, age_acc);
                best_context_gender_acc = max(best_context_gender_acc, gender_acc);
                
            end
            performance_context(end+1, :) = [best_context_MAE, best_context_age_acc, best_context_gender_acc];
        end
        
        fprintf('>>>>----summary----<<<<\n')
        disp([sufficiency', performance_context]);
    end
    
    %% train and eval on test set
    
    if isempty(test_set)
        continue;
    end
        
%     try
%         load([feat_opt.model_path, '/', datasets{i}.name, '_Model', feat_opt.suffix, feat_opt.conf_suffix]);
%     catch
        fprintf('>>>>----train models on whole dataset----<<<<\n');
        model = AgeGenderEvaluationTrainRegression(feat,...
            age, gender, [],...
            best_age_lambda, best_gender_lambda, []);
%         save([feat_opt.model_path, '/', datasets{i}.name, '_Model', feat_opt.suffix, feat_opt.conf_suffix], 'model');
%     end
    datasets{i}.agegender_model = model;
    
    for j = test_set
        clear feat_test
        [feat_test, age_test, gender_test, det_test] = LoadFeature(datasets{j}, feat_opt);

        fprintf('>>>>----evaluate on set %s---<<<<\n', datasets{j}.name);
        [age_res,gender_res] ...
            = AgeGenderEvaluationTestRegression(feat, datasets{i}.agegender_model);
        [age_res_test,gender_res_test] ...
            = AgeGenderEvaluationTestRegression(feat_test, datasets{i}.agegender_model);
%         age_res_test = CalibrateDistribution(age_res_test, age_res);
%         gender_res_test = CalibrateDistribution(gender_res_test, gender_res);
        
        PerformanceAnalysis(age_test ,gender_test, det_test, age_res_test, gender_res_test);
%             adjust alpha 
    end
end
    
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