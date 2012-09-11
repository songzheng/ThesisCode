function ap = APBalanced(score, gt)

[thresh_vals,si]=sort(-score);
thresh_vals = -thresh_vals;

wp = 0.1/length(find(gt>0));
wn = 0.9/length(find(gt<0));

tp=double(gt(si)>0)*wp;
fp=double(gt(si)<0)*wn;

fp=cumsum(fp(:)');
tp=cumsum(tp(:)');

rec=[0, tp/0.1, 1];
prec=[tp(1)/(fp(1)+tp(1)), tp./(fp+tp), 0.1];

rec_sampled = 0.01:0.01:0.99;
prec_sampled = zeros(1, length(rec_sampled));

for i = 1:length(rec_sampled)
    p1 = find(rec<rec_sampled(i), 1, 'last');
    v1 = prec(p1);
    x1 = abs(rec(p1) - rec_sampled(i));
    p2 = p1+1;
    v2 = prec(p2);
    x2 = abs(rec(p2) - rec_sampled(i));
    
    prec_sampled(i) = (v1*x2 + v2*x1)/(x1+x2);
end

ap = mean(prec_sampled);
% 
% mrec=[0 ; rec ; 1];
% mpre=[0 ; prec ; 0.1];
% for i=numel(mpre)-1:-1:1
%     mpre(i)=max(mpre(i),mpre(i+1));
% end
% % i=find(mrec(2:end)~=mrec(1:end-1))+1;
% i = 2:length(mrec);
% ap=sum((mrec(i)-mrec(i-1)).*mpre(i));