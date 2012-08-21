function model = LinearClassificationTrain(feature, label, K)
if ~exist('K', 'var')
    K = feature * feature';
end
model = svmtrain(label, [(1:length(label))',K], '-s 0 -t 4');
model.sv_matrix = feature;
