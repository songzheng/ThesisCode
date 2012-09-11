function [mean_ndcg, dismap] = RetrievalEvaluation(query, data, dismap, relmap, k, feat_idx)

nquery = size(query.feature,1);
ndata = size(data.feature, 1);
nfeat = size(data.feature, 2);

if ~exist('feat_idx', 'var')
    feat_idx = 1:nfeat;
end

wt = 1./[1, log2(2:k)];

% compute ideal dcg
% an ideal rank of dataset
idcg = inf(nquery, 1);
idea_relmap = sort(relmap, 2, 'descend');
for i = 1:nquery
    idea_retr_rel = idea_relmap(i, :);
    ava_idx = find(idea_retr_rel>=0);
    if length(ava_idx) < k
        continue;
    end
    idcg(i) = sum(idea_retr_rel(ava_idx(1:k)).*wt);
end
% compute dcg
if isempty(dismap)
    dismap = EuDist2(query.feature(:, feat_idx), data.feature(:, feat_idx));
    dismap = dismap/length(feat_idx);
end

dcg = inf(nquery, 1);
[~, si] = sort(dismap, 2, 'ascend');

for i = 1:nquery
    retr_rel = relmap(i, si(i, :));
    ava_idx = find(retr_rel>=0);
    if length(ava_idx) < k
        continue;
    end
    dcg(i) = sum(retr_rel(ava_idx(1:k)).*wt);
end

% get random performance
% dcg_random = zeros(nquery, 1);
% for t = 1:20
%     for i = 1:nquery
%         retr_rel = relmap(i, randsample(ndata, k));
%         dcg_random(i) = dcg_random(i) + sum(retr_rel.*wt);
%     end
% end
% dcg_random = dcg_random/100;
% ndcg_random = dcg_random./(idcg+eps);
% mean_ndcg_random = mean(ndcg_random);

% compute ndcg
idcg = idcg(~isinf(dcg));
dcg = dcg(~isinf(dcg));
ndcg = dcg./(idcg+eps);
mean_ndcg = mean(ndcg);

% show example
% [~, si] = sort(ndcg, 'descend');
% nex = 7;
% nret = 10;
% idx = si(1:floor(nquery/nex):end);
% idx = idx(1:nex);
% idx = randsample(nquery, nex);
% % idx = si(220:220+nex-1);
% 
% ex_im = cell(nex, nret+1);
% rel_val = zeros(nex, nret+1);
% for i = 1:nex
%     ex_im{i, 1} = [query.datadir, '/', query.images{idx(i)}];
%     rel_val(i, 1) = ndcg(idx(i));
%     for j = 1:nret
%         rel_val(i, j+1) = retr_relmap(idx(i), j);
%         ex_im{i, j+1} = [data.datadir, '/', data.images{retr_idx(idx(i), j)}];
%     end
% end
% 
% DrawImageFrame(ex_im, [], rel_val);



