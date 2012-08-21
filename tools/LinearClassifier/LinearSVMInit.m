function LinearSVMInit(thread, dim, max_memory, W, C0, bAddBias)
global LinearSVM;

if ~exist('C0', 'var') || isempty(C0)
    C0 = 0.002;
end
if ~exist('max_memory', 'var') || isempty(max_memory)   
    max_memory = 3;
end

max_sample = floor(max_memory * 2^30 / 8 / dim);

if ~exist('bAddBias', 'var')
    bAddBias = true;
end
if isempty(LinearSVM)
    LinearSVM = {};
end

fprintf('Thread %d Linear SVM Mining Data', thread);
t = thread;
LinearSVM{t}.bAddBias = bAddBias;
if bAddBias
    LinearSVM{t}.Feature = zeros(dim+1, max_sample);
    LinearSVM{t}.W = zeros(dim+1, 1);
else
    LinearSVM{t}.Feature = zeros(dim, max_sample);
    LinearSVM{t}.W = zeros(dim, 1);
end

LinearSVM{t}.Q = zeros(max_sample, 1);
LinearSVM{t}.Label = zeros(max_sample, 1);
LinearSVM{t}.C = zeros(max_sample, 1);
LinearSVM{t}.SV = zeros(max_sample, 1);
LinearSVM{t}.Alpha = zeros(max_sample, 1);
% LinearSVM{t}.HingeLoss = zeros(max_sample, 1);
LinearSVM{t}.ActiveCache = int32(zeros(max_sample, 1));

LinearSVM{t}.Pointer = 0;
LinearSVM{t}.PrimalIter = 0;
LinearSVM{t}.C0 = C0;
LinearSVM{t}.Loss = zeros(1, 3);
LinearSVM{t}.DualLoss = zeros(1, 2);


if exist('W', 'var') && (length(W) == length(LinearSVM{t}.W))
    LinearSVM{t}.W = W;
end
