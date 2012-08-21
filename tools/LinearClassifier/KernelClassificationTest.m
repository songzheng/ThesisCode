function res = LinearClassificationTest(feature, model, K)
model = rmfield(model, 'sv');
model = rmfield(model, 'sv_matrix');
if ~exist('K', 'var')
    K = feature * model.sv_matrix';
end
res = svmpredict(zeros(size(K,1),1), [(1:size(K,1))', K], model);