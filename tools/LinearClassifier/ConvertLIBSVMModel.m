function linear_model = ConvertLIBSVMModel(model, train_data)

if model.Parameters(1) == 0
    if model.Parameters(2) == 4
        SVs = train_data(full(model.SVs), :);
    else
        SVs = full(model.SVs);
    end
    coef = model.sv_coef;
    dim = size(SVs,2);
    nclass = model.nr_class;
    
    weights = cell(nclass, nclass);
    idx2 = cumsum(model.nSV);
    idx1 = [1; 1+idx2(1:end-1)];
    
    
    for i = 1:nclass
        for j = 1:i-1
            if(i == j)
                continue;
            end
            
            if j<i
                ii = i-1;
                jj = j;
            else
                ii = i;
                jj = j-1;
            end
            
            weights{i,j} = SVs(idx1(i):idx2(i), :)' * coef(idx1(i):idx2(i), jj) + ...
                SVs(idx1(j):idx2(j), :)' * coef(idx1(j):idx2(j), ii);
        end
    end
    
    [gridx, gridy] = meshgrid(1:nclass);
    idx = find(gridx<gridy);
    weights = weights(idx);
    weights = cell2mat(weights');
    bias = -model.rho';
    linear_model.weights = weights;
    linear_model.bias = bias;
    
    project = zeros(length(bias), nclass);
    idx = 1;
    for i = 1:nclass
        for j = i+1:nclass
            project(idx, i) = 1;
            project(idx, j) = -1;
            idx = idx+1;
        end
    end
    
    linear_model.project = project;
elseif model.Parameters(1) == 3

    bias = -model.rho';
    linear_model.weights = full(model.SVs)' * model.sv_coef;
    linear_model.bias = bias;
    
end
    