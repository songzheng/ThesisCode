function [label, acc] = LinearClassificationTest(label_gt, feature, model)

score = bsxfun(@plus, feature * model.weights, model.bias);
score = score * model.project;

[~, label] = max(score, [], 2);
label = model.class_label(label);
label = label(:);

acc = length(find(label == label_gt))/length(label_gt);