function [labels_new, label_set] = ExpandLabel(labels)
nlabel = zeros(1, size(labels, 2));
label_set = cell(1, size(labels, 2));

for n = 1:size(labels, 2)
    l = unique(labels(:, n));
    nlabel(n) = length(l) - 1;
    label_set{n} = setdiff(l, 0);
end

labels_new = zeros(size(labels, 1), sum(nlabel));

idx = 1;
for i = 1:size(labels, 2);
    for j = 1:nlabel(i)
        labels_new(labels(:, i) == label_set{i}(j) , idx) = 1;
        labels_new(labels(:, i) ~= label_set{i}(j) , idx) = -1;
        labels_new(labels(:, i) == 0 , idx) = 0;
        idx = idx + 1;
    end
end