function suc = LinearSVMAddTrain(t, data, c)

% add constraints
% w^t * x > c - \xi for c > 0
% w^t * x < c + \xi for c < 0

global LinearSVM;

max_sample = size(LinearSVM{t}.Feature, 2);
ndata = size(data, 2);

if LinearSVM{t}.Pointer + ndata > max_sample
    fprintf('Max sample of thread %d obtained', t);
    suc = 0;
else
    suc = 1;
end

label = sign(c);

% if label == 1
%     C = LinearSVM{t}.C;
% else
%     C = LinearSVM{t}.C * LinearSVM{t}.J;
% end    

num_add = min(max_sample - LinearSVM{t}.Pointer, ndata);

% print progress
prog = round(max_sample/100);
if floor(LinearSVM{t}.Pointer/prog) - floor((LinearSVM{t}.Pointer+num_add)/prog) < 0
    fprintf('.');
end

idx_add = LinearSVM{t}.Pointer+1:LinearSVM{t}.Pointer+num_add;

% convert to standard svm constraint
% w^t * x > c - \xi => w^t *(x/c) > 1 - \xi', \xi' = \xi/c for c > 0
% w^t * x < c + \xi => w^t *(x/c) > 1 - \xi', \xi' = \xi/|c| for c < 0

if LinearSVM{t}.bAddBias
    LinearSVM{t}.C(idx_add) = LinearSVM{t}.C0 * abs(c(1:num_add));
    LinearSVM{t}.Feature(:, idx_add) = bsxfun(@rdivide, [data(:, 1:num_add); ones(1, num_add)], c(1:num_add));
else
    LinearSVM{t}.C(idx_add) = LinearSVM{t}.C0 * abs(c(1:num_add));
    LinearSVM{t}.Feature(:, idx_add) = bsxfun(@rdivide, data(:, 1:num_add), c(1:num_add));
end
    
LinearSVM{t}.Q(idx_add) = sum(LinearSVM{t}.Feature(:, idx_add).^2);
LinearSVM{t}.Label(idx_add) = label(1:num_add);
LinearSVM{t}.SV(idx_add) = 1;
% if ~exist('score', 'var')
%     score = zeros(num_add, 1);
% end
% LinearSVM{t}.HingeLoss(idx_add) = max(0, 1-label*score);
LinearSVM{t}.Pointer = LinearSVM{t}.Pointer + num_add;