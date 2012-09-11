function feat = FuncCH(image, opt)

option=struct(...
    'win_size',[],...
    'all_center',[],...
    'cell_size',[16,16],...
    'cell_stride',[8,8],...
    'hist_dim', 3, ...
    'hist_bin',8,...
    'gamma', 2.5, ...
    'fea_size',0,...
    'unique_tag', 'ColorHist8080',...
    'tag', '', ...
    'nbins',30 ...
    );

option.all_center=opt.all_center;

image=double(image)/255;
abmin = -73;
abmax = 95;
lab = RGB2Lab(image.^option.gamma);
lab(:,:,1) = lab(:,:,1) ./ 100;
lab(:,:,2) = (lab(:,:,2) - abmin) ./ (abmax-abmin);
lab(:,:,3) = (lab(:,:,3) - abmin) ./ (abmax-abmin);
lab(:,:,2) = max(0,min(1,lab(:,:,2)));
lab(:,:,3) = max(0,min(1,lab(:,:,3)));

all_center =option.all_center;
[ llc_codes]= assignTextons_soft(lab,all_center);

dSize = size(cell2mat(all_center),1);
feat=llc_pooling(llc_codes,dSize);
end

function [ llc_codes]= assignTextons_soft(fim,textons)
d = size(fim,3);
n = size(fim,1)*size(fim,2);
data = zeros(d,n);

for i = 1:d,
    t = fim(:,:,i);
    data(i,:)=t(:);
end
textons=textons{1};
d2 = EuDist2(data',textons,0);

d2=d2';
% mean_dist= mean(d2(:));
mean_dist= 0.2;
llc_codes = exp(-4*d2/mean_dist);

[val, indx] = sort(llc_codes,'descend');
base_index= [1: size(llc_codes,1): numel(llc_codes)];
base_index=base_index-1;

Knn=2;
temp = zeros(size(llc_codes));
for i=1:Knn
    temp_index= indx(i,:);
    temp(temp_index+base_index )= llc_codes(temp_index+base_index);
end
llc_codes= temp;
end