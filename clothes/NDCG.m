function ndcg = NDCG(score, label, k)

score = score(label ~= 0);
label = label(label ~= 0);

if ~exist('k', 'var')
    k = length(find(label == 1));
end

% retrieval weight
weight = (1:k)./[1, log2(2:k)];

wp = length(find(label == -1))/length(find(label == 1));

% ideal dcg
idcg = sum(weight(1:min(k, length(find(label == 1)))));

% dcg
[score, si] = sort(score, 'descend');
label = label(si(1:k));
dcg = sum(weight(label == 1));

ndcg = dcg/idcg;
