function feature = EncodeFeature(feat_raw, dataset)
if isempty(feat_raw)
    feature = [];
    return;
end

coding_func = str2func([dataset.encoding.coding_method, '_coding']);
dim = max(cell2mat(dataset.encoding.feat_idx_split(:)'));
feature = zeros(size(feat_raw,1), dim);

for i = 1:numel(dataset.feat_idx_split)
    idx = dataset.feat_idx_split{i};
    idx_coded = dataset.encoding.feat_idx_split{i};
    feature(:, idx_coded) = coding_func(feat_raw(:, idx)', dataset.encoding.codebook{i})';
end

function fea_coded = Project_coding(fea, codebook)
if isfield(codebook, 'mean')
    fea = bsxfun(@minus, fea, codebook.mean);
end   

fea_coded = codebook.basis'*fea;
fea_coded = bsxfun(@rdivide, fea_coded, sqrt(sum(fea_coded.^2, 1)) + eps);


function fea_coded = RBF_coding(fea, codebook)
Dist = EuDist2(fea', codebook.basis');
gamma = mean(Dist(:))*2;
fea_coded = exp(-Dist/gamma)';
fea_coded = bsxfun(@rdivide, fea_coded, sqrt(sum(fea_coded.^2, 1)) + eps);


function fea_coded = L2Rec_coding(fea, codebook)  
XtX = codebook.basis'*codebook.basis;
lambda = 0.1*norm(XtX);
fea_coded = (XtX + lambda*eye(size(XtX)))\(codebook.basis'*fea);
fea_coded = bsxfun(@rdivide, fea_coded, sqrt(sum(fea_coded.^2, 1)) + eps);
