function model = LinearRegressionTrain(feat, label, lambda)

[n,m] = size(feat);

limit = [min(label), max(label)];
center = mean(limit);

A = [feat, ones(n, 1)]'*[feat, ones(n, 1)];
B = [feat, ones(n, 1)]'*label;
w = (A + lambda*eye(m+1))\B;

% error correction
train_res = [feat, ones(n, 1)] * w;
gamma = exp(median(log(abs(train_res-center)./abs(label-center))));

model.w = w;
model.limit = limit;
model.center = center;
model.gamma = gamma;