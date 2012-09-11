function feature = ProjectFeature(feat_raw, dataset)
if isempty(feat_raw)
    feature = [];
    return;
end

feature = zeros(size(feat_raw,1), dataset.projection.length);
for i = 1:numel(dataset.projection.vector)
    fprintf('.');
    
    if ~dataset.projection.map(i)
        continue;
    end
    
    idx = dataset.projection.feat_idx_split{i};
    tmp_feat = zeros(size(feat_raw,1), length(idx));
    for p = 1:length(dataset.projection.vector{i})
        v = dataset.projection.vector{i}{p};
        tmp_feat(:, p) = feat_raw(:, v.idx) * v.w + v.b;
        %         feature(:, cnt) = 1./(1+exp(-1.5*feature(:, cnt)));
        
        tmp_feat(:, p) = (tmp_feat(:, p) - v.score_min)/v.score_scale;
        tmp_feat(:, p) = max(min(tmp_feat(:, p), 1),0);
    end
    tmp_feat = bsxfun(@rdivide, tmp_feat, sqrt(sum(tmp_feat.^2, 2)));
    feature(:, idx) = tmp_feat;
end
fprintf('\n');