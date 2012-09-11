function [model, sv] = LinearMultiClassSVMTrain(label, feature, model)
[dim, nsample] = size(feature);

model.class_labels = setdiff(unique(label), 0);
model.w = zeros(dim, length(model.class_labels));
model.b = zeros(1, length(model.class_labels));
model.score_max = zeros(1, length(model.class_labels));
model.score_min = zeros(1, length(model.class_labels));

label_id = 1;
sv = [];

for l = model.class_labels(:)'
    label_binary = zeros(nsample, 1);
    
    label_binary(label == l) = 1;
    label_binary(label ~= l & label ~= 0) = -1;
    
    [model_binary, ~, sv_l] = LinearBinarySVMTrain(label_binary, feature, []);    
    [scores, acc] = LinearBinarySVMTest(label_binary, feature, model_binary);
        
    model.w(:, label_id) = model_binary.w;
    model.b(label_id) = model_binary.b;
    model.score_max(label_id) = max(scores);
    model.score_min(label_id) = min(scores);
    sv = union(sv, sv_l);
    
    label_id = label_id + 1;
end
