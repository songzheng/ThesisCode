function [model, Performance] = AgeEvaluationTrain(feature, label, age_limit)

label = max(min(label, age_limit(2)), age_limit(1));
label = label(:);
div = age_limit(1):10:age_limit(2);
div(end) = age_limit(2);
res_center = mean(age_limit);

%% self cross validation
nfold = 10;
train_ratio = 0.5;

MAEs = zeros(1, nfold);
MAEs_interval = zeros(length(div)-1, nfold);
Accs = zeros(2, nfold);

nsample = size(feature,1);

feature = [feature, ones(nsample,1)];

lambda = 1;
dim = size(feature,2);


for f = 1:nfold
    
    train_idx = [];
    test_idx = [];
    
    for i = 1:length(div)-1
        div_idx = find(label >= div(i) & label <= div(i+1));        
        train_idx1 = randsample(div_idx, round(length(div_idx)*train_ratio));
        test_idx1 = setdiff(div_idx, train_idx1);
        train_idx = [train_idx; train_idx1];
        test_idx = [test_idx; test_idx1];
    end
    
    A = feature(train_idx, :)'*feature(train_idx, :);
    B = feature(train_idx, :)'*label(train_idx);
    w = (A + lambda*eye(dim))\B;
    
    % error correction
    train_res = feature(train_idx, :) * w;
    gamma = exp(median(log(abs(train_res-res_center)./abs(label(train_idx)-res_center))));
    
    test_res = (feature(test_idx, :) * w - res_center)/gamma + res_center;
    test_res = max(min(test_res, age_limit(2)), age_limit(1));
    MAEs(f) = mean(abs(test_res - label(test_idx)));
    
    for i = 1:length(div)-1
        div_idx = find(label(test_idx) >= div(i) & label(test_idx) <= div(i+1));
        if ~isempty(div_idx)
            MAEs_interval(i,f) = mean(abs(test_res(div_idx) - label(test_idx(div_idx))));
        end
    end
    
    Accs(1, f) = length(find(abs(test_res - label(test_idx))<=10))/length(test_res);
    Accs(2, f) = length(find(abs(test_res - label(test_idx))<=5))/length(test_res);
end

Performance = [MAEs;Accs; MAEs_interval];
% report
fprintf('Eval fold = %d, train_ratio = %d:\n', nfold, train_ratio);
fprintf('MAE = %f(%f), Acc in 10 years = %f(%f), Acc in 5 years = %f(%f)\n',...
    mean(MAEs), std(MAEs), mean(Accs(1, :)), std(Accs(1, :)),mean(Accs(2, :)), std(Accs(2, :)));

MAEs_interval = mean(MAEs_interval,2);
for i = 1:length(div)-1
    fprintf('Age %d to %d: MAE = %f\n', div(i), div(i+1), MAEs_interval(i));
end

Performance = mean(Performance, 2);

%% output model using all training sample

A = feature'*feature;
B = feature'*label;
w = (A + lambda*eye(dim))\B;

% error correction
train_res = feature * w;
gamma = exp(median(log(abs(train_res-res_center)./abs(label-res_center))));
model = [w; gamma; age_limit(1); age_limit(2)];
