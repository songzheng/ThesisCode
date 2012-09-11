function feature = EvalSubspace(feature, model)
feature = model.projection(:, 1:model.ReducedDim)' * bsxfun(@minus, feature, model.mean) ;
feature = bsxfun(@rdivide, feature, sqrt(sum(feature.^2, 1)) + eps);