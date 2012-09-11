function [image, dismap] = RetrievalExample(query, data, dismap, k, feat_idx)

nquery = size(query.feature,1);
ndata = size(data.feature, 1);
nfeat = size(data.feature, 2);

if ~exist('feat_idx', 'var')
    feat_idx = 1:nfeat;
end

% compute distance
if isempty(dismap)
    dismap = EuDist2(query.feature(:, feat_idx), data.feature(:, feat_idx));
end

[~, si] = sort(dismap, 2, 'ascend');
retr_idx = si(:, 1:k);

% show example
nex = min(7, nquery);
nret = k;
idx = 1:nex;
% idx = si(220:220+nex-1);

ex_im = cell(nex, nret+1);
rel_val = zeros(nex, nret+1);
for i = 1:nex
    ex_im{i, 1} = [query.dataset_dir, '/', query.images{idx(i)}];
    for j = 1:nret
        ex_im{i, j+1} = [data.dataset_dir, '/', data.images{retr_idx(idx(i), j)}];
    end
end

image = DrawImageFrame(ex_im, []);



