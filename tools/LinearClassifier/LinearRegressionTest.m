function res = LinearRegressionTest(feat, model)
[n,m] = size(feat);
limit = model.limit;
center = mean(limit);
gamma = model.gamma;

res = [feat, ones(n, 1)] * model.w;
res = (res - center)/gamma + center;
res = max(min(res, limit(2)), limit(1));

