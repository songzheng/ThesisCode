function res = LinearRegressionTest(feat, model)
[n,m] = size(feat);
limit = model.limit;
center = mean(limit);
gamma = model.gamma;

res = feat * model.w(1:end-1) + model.w(end);
res = (res - center)/gamma + center;
res = max(min(res, limit(2)), limit(1));

