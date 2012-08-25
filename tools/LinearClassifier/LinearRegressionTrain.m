function model = LinearRegressionTrain(feat, label, lambda)

[n,m] = size(feat);

limit = [min(label), max(label)];
center = mean(limit);

A = zeros(m+1);
A(1:m, 1:m) = feat'*feat;
A(1:m, m+1) = feat' * ones(n, 1);
A(m+1, 1:m) = A(1:m, m+1)';
A(m+1, m+1) = n;

B = zeros(m+1, 1);
B(1:m) = feat'*label;
B(m+1) = sum(label);
	
w = (A + lambda*eye(m+1))\B;
clear A B

% error correction
train_res = feat * w(1:m) + w(m+1);
gamma = exp(median(log(abs(train_res-center)./abs(label-center))));

model.w = w;
model.limit = limit;
model.center = center;
model.gamma = gamma;