function [model, loss, sv, alpha] = LinearBinarySVMTrain(label, feature, model)
[dim, nsample] = size(feature);
if ~isfield(model, 'rho')
	model.rho = 0.5;
end

if ~isfield(model, 'lambda')
	model.lambda = 1;
end

if ~isfield(model, 'C_const')
	model.C_const = nsample*model.lambda;
end

model = SVMDualCoordinateDescentInit(label, feature, model);

iter = 1;
last_object_value = sum(model.loss);
% figure;
% plot(0, 0, '.');
% hold on;
fprintf('Linear SVM training, dim=%d, data#=%d...', size(feature,1), size(feature,2));

while iter < 10000
	SVMDualCoordinateDescent(label, feature, model);
	object_value = sum(model.loss);
    
%     plot(iter, object_value, '.');
%     plot(iter, model.b, '.r');
%     drawnow;
    
	if abs(object_value - last_object_value)/object_value < 1e-3
		break;
	end
	
	last_object_value = object_value;
	
	if mod(iter, 50) == 0
		fprintf('.');
	end
	iter = iter + 1;
end
fprintf('\n');    

sv_pos = find(model.alpha > 0 & label == 1);
sv_neg = find(model.alpha > 0 & label == -1);

sv = [sv_pos; sv_neg];

score_pos = feature(:, sv_pos)' * model.w + model.b;
score_neg = feature(:, sv_neg)' * model.w + model.b;

loss_pos = sum(max(1 - score_pos, 0).*model.C(sv_pos));
loss_neg = sum(max(1 + score_neg, 0).*model.C(sv_neg));
loss_reg = model.w'*model.w/2 + model.b^2/2*model.lambda;

alpha = model.alpha(sv);

loss = [loss_pos, loss_neg, loss_reg];

