function [label_res, acc] = LinearMultiClassSVMTest(label, feature, model)

scores = bsxfun(@plus, feature' * model.w, model.b);

[~, label_res] = max(scores, [], 2);
label_res = model.class_labels(label_res);
label_res = label_res(:);

acc = length(find(label == label_res)) / length(label);