function [loss, scores_sv, labels_sv] = LinearSVMUpdateLoss(t)

global LinearSVM;

sv_idx = find(LinearSVM{t}.SV(1:LinearSVM{t}.Pointer) == 1);

sv_label = LinearSVM{t}.Label(sv_idx);
fprintf('Linear SVM Loss Updated: %d pos sv, %d neg sv\n',...
    length(find(sv_label == 1)), length(find(sv_label == -1)))

scores_sv = LinearSVM{t}.Feature(:, sv_idx)' * LinearSVM{t}.W;
labels_sv = LinearSVM{t}.Label(sv_idx);
loss = [0,0];

loss(1) = sum(LinearSVM{t}.C(sv_idx) .* max(0, 1 - scores_sv));
loss(2) = sum(LinearSVM{t}.W.^2);

LinearSVM{t}.Loss = loss;
fprintf('cons loss = %f, reg loss = %f\n', loss(1), loss(2));