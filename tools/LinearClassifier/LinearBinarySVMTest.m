function [score, acc] = LinearBinarySVMTest(label, feature, model)
score = feature' * model.w + model.b;

acc = 0;
if ~isempty(label)
    label_test = zeros(length(label), 1);
    label_test(score >= 0) = 1;
    label_test(score < 0) = -1;
    acc = length(find(label_test == label))/length(label);
end
