function model = gd(Y,C,K,B,lambda,model,opt)
t = 0;
converged = 0;
prev_loss =1e9;
loss =0;
stop_count =0 ;
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
    
    
    for this_id=1:length(Y)
        i = perm(this_id);
        
        if W(i) > opt.INCACHE
            W(i)=W(i)-1;
            continue;
        end
            
        T = min(opt.max_iter/2.0, t+ 10000.0);
        
        fff = 0.002;
        rateX = cnum * fff / T;
        t=t+1;
        if mod(t,5000) == 0
            [loss,loss_part] = compute_loss(Y,C,K,B,model,lambda,opt);

            delta = 1.0 - (abs(prev_loss - loss) / loss);
%             if delta >= opt.DELTA_STOP && t >= opt.MIN_ITER
            if (loss_part(1)<= 2||delta >= opt.DELTA_STOP)  && t >= opt.MIN_ITER
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
            
            fprintf('%2.0f%% -- delta=%.5f, loss hing = %f, loss regu = %f\n',100*double(t)/double(opt.max_iter), max(delta,0.0), double(loss_part(1)),double(loss_part(2)));
        end
        V = ex_score(K(:,i),C(:,i),B,model);
        

        
        if (Y(i) * V < 1.0) % SV update
            numupdated = numupdated+1;
            if opt.smd
                if Y(i)>0
                    mult = opt.J*opt.learnmult;
                else
                    mult = -1*opt.learnmult;
                end       
                
                model.alpha = model.alpha+mult*K(:,i).*pt_alpha;
                model.q = model.q+mult*pt_q.*C(:,i)*(model.ori_B'*K(:,i));
                model.b = mult*pt_b+model.b;
                
            else
                if Y(i)>0
                    mult = opt.J* rateX * opt.learnmult;
                else
                    mult = -1* rateX * opt.learnmult;
                end
                model.alpha = model.alpha+mult*K(:,i);
                model.b = mult+model.b;
                model.q = model.q+mult*C(:,i)*(model.ori_B'*K(:,i));
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
            model.alpha = max(model.alpha, opt.lb);
            model.q = max(model.q, opt.lb);
            rateR = 1.0 / T;
            
            if opt.smd
                mu =0.1;
                
                vt_aH_temp = opt.smd_lambda*K*vt_alpha/length(Y);
                gt_alpha = K*model.alpha/length(Y);
                vt_alpha = opt.smd_lambda*vt_alpha-pt_alpha.*(gt_alpha+vt_aH_temp);
                pt_alpha = pt_alpha.*max(0.5,1-mu*gt_alpha.*vt_alpha);
                model.alpha = model.alpha - pt_alpha.*gt_alpha;
                if ~isempty(find(model.alpha==Inf))
                    model.alpha;
                end
                vt_qH_temp = opt.smd_lambda*model.ctx*vt_q;
                gt_q = model.ctx*model.q;
                vt_q = opt.smd_lambda*vt_q-pt_q.*(gt_q+vt_qH_temp);
                pt_q = pt_q.*max(0.5,1-mu*gt_q.*vt_q);
                model.q = model.q - pt_q.*gt_q;
                
                vt_b=opt.smd_lambda*vt_b-pt_b;
                pt_b = pt_b*max(0.5,1-mu*vt_b);
                
            else
                
                % regularize w0

                mult = rateR * opt.regmult * opt.learnmult;
                %                         mult = power((1-mult), opt.REGFREQ);
                %                         model.alpha = mult * model.alpha;
                % regularize context q
                mult = rateR * opt.regmult* opt.learnmult;
                %             for n=1:opt.REGFREQ/4
                model.alpha = model.alpha- 10*mult*K*model.alpha/length(Y);
                model.q = model.q-10*mult*model.ctx*model.q;
                %             end
            end
        end
        
    end
    
end

end

function val= ex_score(k,C,B,model)
% val = (kron(C',B)*model.q+model.alpha)'*k+model.b;
val = model.alpha'*k + model.q'*C*(model.ori_B'*k)+ model.b;
end



function [loss,loss_part]=compute_loss(Y,C,K,B,model,lambda,opt)
loss = 0;
loss_part = zeros(2,1);
% P_M = zeros(length(Y),length(model.q));
out = zeros(length(Y),1);
for i=1:size(K,1)
%     tt = kron(C(:,i)',B);
%     out(i) = 1 - Y(i) .* ((tt*model.q+model.alpha)'*K(:,i)+model.b);
    out(i) = 1 - Y(i) .* ex_score(K(:,i),C(:,i),B,model);
%     P_M = P_M+tt;
end
% J =20;
mult = ones(length(Y),1);
mult(Y>0)= opt.J;
% hinge loss
loss = loss + sum(mult.*max(0,out)) / 2;
loss_part(1) = sum(mult.*max(0,out)) / 2;
% regualization term;
% P_M=P_M./length(Y);
% pq_alpha = P_M*model.q+model.alpha;

% loss = loss+pq_alpha'*K*pq_alpha;
% temp = model.ori_B*sum(C)/length(Y);
% loss = loss+model.alpha'*K*model.alpha+model.q'*temp'*K*temp*model.q;
loss_part(2) = model.alpha'*K*model.alpha/length(Y)+model.q'*model.ctx*model.q;
loss = loss+loss_part(2);

end



