function model = SVMDualCoordinateDescentInit(label, feature, model)
[num, dim] = size(feature);
% auxilary data
model.Q = sum(feature.^2, 2) + 1/model.lambda;
% parameters
model.C = zeros(num,1);
model.C(label == 1) = 1/length(find(label == 1)) * model.rho * model.C_const;
model.C(label == -1) = 1/length(find(label == -1)) * (1-model.rho) * model.C_const;

% model
model.alpha = zeros(num,1);
model.w = zeros(dim, 1);
model.b = 0;
model.loss = [0,0];