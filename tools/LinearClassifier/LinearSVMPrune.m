function LinearSVMPrune(t)

global LinearSVM;

sv_idx = find(LinearSVM{t}.SV == 1);

LinearSVM{t}.Pointer = length(sv_idx);

LinearSVM{t}.Feature(:, 1:LinearSVM{t}.Pointer) = LinearSVM{t}.Feature(:, sv_idx);
LinearSVM{t}.Label(1:LinearSVM{t}.Pointer) = LinearSVM{t}.Label(sv_idx);
LinearSVM{t}.Label(LinearSVM{t}.Pointer+1:end) = 0;
% LinearSVM{t}.HingeLoss(1:LinearSVM{t}.Pointer) = LinearSVM{t}.HingeLoss(sv_idx);
% LinearSVM{t}.HingeLoss(LinearSVM{t}.Pointer+1:end) = 0;
LinearSVM{t}.SV(1:LinearSVM{t}.Pointer) = LinearSVM{t}.SV(sv_idx);
LinearSVM{t}.SV(LinearSVM{t}.Pointer+1:end) = 0;
LinearSVM{t}.Alpha(1:LinearSVM{t}.Pointer) = LinearSVM{t}.Alpha(sv_idx);
LinearSVM{t}.Alpha(LinearSVM{t}.Pointer+1:end) = 0;
LinearSVM{t}.Q(1:LinearSVM{t}.Pointer) = LinearSVM{t}.Q(sv_idx);
LinearSVM{t}.Q(LinearSVM{t}.Pointer+1:end) = 0;
LinearSVM{t}.C(1:LinearSVM{t}.Pointer) = LinearSVM{t}.C(sv_idx);
LinearSVM{t}.C(LinearSVM{t}.Pointer+1:end) = 0;