function codebook = EncodeTrain(feat, coding_opts)

switch coding_opts.train_method
    case 'Kmeans'
        basis = vl_kmeans(feat, coding_opts.codebook_size);
        basis = bsxfun(@rdivide, basis, sqrt(sum(basis.^2)));
        
    case 'PCA'
        codebook.mean = mean(feat, 2);
        basis = PCA(feat');
        basis = basis(:, 1:min(coding_opts.codebook_size, size(basis,2)));
        
    case 'L2Rec'
        train_idx = 1:size(feat, 2);
        weight = zeros(1, size(feat, 2));
        sel = zeros(1, size(feat, 2));
        
        dict_size = min(round(length(train_idx)/2),2000);
        iter_num = ceil(size(feat,2)*5/dict_size);
        
        for i = 1:iter_num
            dict_idx = randsample(train_idx, dict_size);
            sample_idx = setdiff(train_idx, dict_idx);
            V = feat(:, sample_idx);
            X = feat(:, dict_idx);
            XtV = X'*V;
            XtX = X'*X;
            
            lambda = 0.1*norm(XtX);
            B = (XtX+lambda*eye(size(X,2)))\XtV;
            
            weight(dict_idx) = weight(dict_idx) + sum(B.^2, 2)';
            sel(dict_idx) = sel(dict_idx) + 1;
        end
        
        weight = weight./(sel + eps);
        
        [sc, si] = sort(weight, 'descend');
        basis = feat(:, si(1:coding_opts.codebook_size));
        
    case 'L12Rec'        
        % config spams
        
        spams_para = [];
        spams_para.regul ='l1l2';
        % spams_para.pos = true;
        spams_para.numThreads = 2;
        spams_para.verbose = true;
        
        
        dict_idx = randsample(size(feat, 2), min(round(size(feat, 2)/2),1000));
        sample_idx = setdiff(1:size(feat, 2), dict_idx);
%         
        V = feat(:, sample_idx);
        X = feat(:, dict_idx);

%         V = fea(:, train_idx);
%         X = fea(:, train_idx);
        
        % precomputed data            
        XtV = X'*V;
        XtX = X'*X;        
        B0 = zeros(size(XtV));
        LC = norm(XtX);
                
        lambdas = exp(-1:0.1:0.2);
        basis_num = zeros(1, length(lambdas));
        for i = 1:length(lambdas)
            lambda = lambdas(i);                     
            % start optimization           
            B = Reconstruct(X, V, XtX, XtV, B0, LC, lambda, spams_para);
            norm_B = sqrt(sum(B.^2, 2));
            basis_num(i) = length(find(norm_B > 1e-6));
            if basis_num(i) == 0
                break;
            end
        end
        
        [val, bidx] = min(abs(coding_opts.codebook_size - basis_num));
        B = Reconstruct(X, V, XtX, XtV, B0, LC, lambdas(bidx), spams_para);
        norm_B = sqrt(sum(B.^2, 2));
        basis_idx{i} = find(norm_B > 1e-6);
        fprintf('lambda = %f, basis # = %d\n', lambda, nbasis);
        basis = X(:, basis_idx{i});
        
    otherwise
        error('No supporting method');
end
codebook.basis = basis;

function B = Reconstruct(X, V, XtX, XtV, B0, LC, lambda, spams_para)

obj_val_pre = inf;
bConverge = false;
spams_para.lambda = lambda/LC;
B = mexProximalFlat(B0, spams_para);
B_pre = B;
Z = B;
gamma_pre = 1;
while(~bConverge)
    [B, val_regularizer] = mexProximalFlat(Z - 1/LC * (XtX*Z - XtV), spams_para);
    
    obj_val = 1/2*sum(sum((V - X*B).^2)) + lambda * sum(val_regularizer);
    
    if ~isinf(obj_val_pre) && abs(obj_val - obj_val_pre)/obj_val_pre < 1e-6
        bConverge = true;
    end    
    
    % FISTA
    gamma = (1 + sqrt(1+4*gamma_pre^2))/2;
    Z = B + (gamma_pre-1)/gamma*(B - B_pre);
    % ISTA
    %     Z = B;
    
    %
    obj_val_pre = obj_val;
    gamma_pre = gamma;
    B_pre = B;
end