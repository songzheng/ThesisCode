function [model, performance] = LearnProjection(X, K, label)
% learn projection vectors over binary classification

addpath 'D:\My Documents\My Work\SVM\LIBSVMMAT'
nfold = 10;

ava_idx = find(label ~= 0);
X = X(ava_idx, :);
K = K(ava_idx, ava_idx);
label = label(ava_idx);

assert(all(sort(unique(label)) == [-1; 1]));

[nsample, ndim] = size(X);

model.w = zeros(ndim, 1);
model.b = 0;

% cross validation
svm_c = 1;
sen = ['-t 5',' -c ',num2str(svm_c)];
performance = zeros(1, nfold);

for n = 1:nfold
    idx_train = randsample(1:nsample, round(nsample/2));
    idx_test = setdiff(1:nsample, idx_train);
    
    [~,si] = sort(label(idx_train), 'descend');
    idx_train = idx_train(si);
    
    Kt = K(idx_train, idx_train);
    svmmodel = svmtrain(label(idx_train), [(1:length(idx_train))', Kt], sen);
    w = X(idx_train(svmmodel.SVs), :)'*svmmodel.sv_coef;
    b = -svmmodel.rho;
    
    test_score = X(idx_test, :) * w + b;
    performance(n) = APBalanced(test_score, label(idx_test));
    
    model.w = model.w + w;
    model.b = model.b + b;
end
performance = mean(performance);
fprintf('Cross validation NDCG = %0.4f, positive ratio = %0.2f\n', performance, length(find(label == 1))/length(label));

model.w = model.w/nfold;
model.b = model.b/nfold;
