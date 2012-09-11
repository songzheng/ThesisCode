function model = LinearRegressionTrain(feature, label, lambda)

[dim,nsample] = size(feature);

limit = [min(label), max(label)];
center = mean(limit);

A = zeros(dim+1);
A(1:dim, 1:dim) = feature * feature';
A(1:dim, dim+1) = feature * ones(nsample, 1);
A(dim+1, 1:dim) = A(1:dim, dim+1)';
A(dim+1, dim+1) = nsample;

B = zeros(dim+1, 1);
B(1:dim) = feature*label;
B(dim+1) = sum(label);
	
w = (A + lambda*eye(dim+1))\B;
clear A B

% % error correction
% train_res = feature' * w(1:dim) + w(dim+1);
% gamma = exp(median(log(abs(train_res-center)./abs(label-center))));

model.w = w;
model.limit = limit;
model.center = center;
model.gamma = 1.0;