function feature = NormalizeFeature(feature, dataset)

if isempty(feature)
    return;
end

feature = bsxfun(@minus, feature, dataset.normalization.mean);
feature = bsxfun(@rdivide, feature, dataset.normalization.std + eps);
for i = 1:numel(dataset.feat_idx_split)
    idx = dataset.feat_idx_split{i};
    feature(:, idx) = bsxfun(@rdivide, feature(:, idx), sqrt(sum(feature(:, idx).^2, 2))+eps);
end