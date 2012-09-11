function model = sgd_transform(model, X, Y, opt)
t = 0;
converged = 0;
prev_loss = 1e9;
stop_count = 0;
W = opt.INCACHE*ones(length(Y),1);
if opt.smd
    step = 0.001;
    
    vt_alpha=step*ones(length(Y),1);
    vt_q = step*ones(length(model.q),1);
    pt_alpha = step*ones(length(Y),1);
    pt_q = step*ones(length(model.q),1);
    
    vt_b=step;
    pt_b=step;
end

while t < opt.max_iter && ~converged
    perm = randperm(length(Y));
    cnum = length(find(W<=opt.INCACHE));
    numupdated = 0;
    
    
    for this_id = 1:length(Y)
        i = perm(this_id);
        
        if W(i) > opt.INCACHE
            W(i)=W(i)-1;
            continue;
        end
        
        T = min(opt.max_iter/2.0, t+ 10000.0);
        
        rateX = cnum * opt.C / T;
        t = t + 1;
        
        if mod(t,round(opt.max_iter/100)) == 0
            [loss,loss_part] = compute_loss(X, Y, model, opt);
            
            delta = 1.0 - (abs(prev_loss - loss) / loss);
            % if delta >= opt.DELTA_STOP && t >= opt.MIN_ITER
            if delta >= opt.DELTA_STOP && t >= opt.MIN_ITER
                stop_count=stop_count+1;
                if (stop_count > opt.STOP_COUNT)
                    converged = 1;
                end
            elseif stop_count > 0
                stop_count = 0;
            end
            prev_loss = loss;
            if (converged)
                break;
            end
            save model_temp.mat model;            
            fprintf('%2.0f%% -- delta=%.5f, loss hing = %f, loss regu = %f\n',...
                100*double(t)/double(opt.max_iter), max(delta,0.0), sum(loss_part([1,2])),sum(loss_part(3:end)));
        end
        
        V = ex_score(X,i,model);        
        
        if (Y(i) * V < 1.0) % SV update
            numupdated = numupdated+1;
            if opt.smd
                                
            else
                for k = 1:length(model)
                    if Y(i)>0
                        mult = opt.J* rateX * X.blocks(k).learnmult;
                    else
                        mult = -1* rateX * X.blocks(k).learnmult;
                    end
                    model{k} = model{k} + mult*X.blocks(k).data(i,:)';
                end
            end
        else % non-SV update
            if (W(i) == opt.INCACHE)
                %                 W(i) = opt.MINWAIT + (1.0*rand()/(RAND_MAX+1.0)*50);
                W(i) = opt.MINWAIT + floor(1.0*rand()*50);
            else
                W(i)=W(i)+1;
            end
        end
        
        if mod(t,opt.REGFREQ) == 0
            
            % apply lowerbounds
            for k = 1:length(model)
                model{k} = max(model{k}, X.blocks(k).lowerbound);
            end
            rateR = 1.0 / T;
            
            if opt.smd
                
            else
                
                % regularize w0                
                for k = 1:length(model)
                    if  X.blocks(k).regmult == 0
                        continue;
                    end
                    mult = rateR * X.blocks(k).regmult * X.blocks(k).learnmult;
                    for kk = 1:opt.REGFREQ
                        model{k} = model{k} - mult*X.blocks(k).M*model{k};
                    end
                end
            end
        end
        
    end
    
end

end

function val= ex_score(X, ind, model)    
val = zeros(length(ind),1);
for k = 1:length(model)
    val = val + X.blocks(k).data(ind,:) * model{k};
end
end


function [loss,loss_part]=compute_loss(X, Y, model, opt)
% [pos_hinge, neg_hinge, [block_reg]]
loss_part = zeros(2+length(model),1);

% hinge loss
loss_hinge = max(0, 1 - Y.*ex_score(X, 1:length(Y), model));
loss_part(1) = opt.J * sum(loss_hinge(Y == 1));
loss_part(2) = sum(loss_hinge(Y == -1));

% regualization term;
for k = 1:length(model)
    loss_part(k+2) = X.blocks(k).regmult*(model{k}'*X.blocks(k).M*model{k});
end
loss = sum(loss_part);
end



