function label_split = LabelSplitGender(label_age, label_gender)
nsample = length(label_age);

label_split = zeros(nsample, 1);

% child
label_split(label_age < 5) = 1;

% gender
label_split(label_age >= 5 & label_gender == 1) = 2;
label_split(label_age >= 5 & label_gender == 2) = 3;


% generate sub-class split

% split_info = cell(1, nsplit_age);
% label_split = zeros(nsample, 1);
% 
% age_hist = hist(label_age, age_limit(1):age_limit(2));
% age_cumhist = cumsum(age_hist);
% n = nsample/nsplit_age;
% 
% 
% model.nsplit_age = nsplit_age;
% model.bsplit_gender = bsplit_gender;
% model.split_info = split_info;
% split_info{1}.age_limit(1) = age_limit(1);
% split_info{nsplit_age}.age_limit(2) = age_limit(2);
% 
% for i = 1:nsplit_age-1
%     age_split = find(age_cumhist > i*n, 1, 'first');
%     split_info{i}.age_limit(2) = age_split-1;
%     split_info{i+1}.age_limit(1) = age_split;
%     
%     label_split(label_age >= split_info{i}.age_limit(1) & label_age <= split_info{i}.age_limit(2)) = i;
% end
% 
% label_split(label_age >= split_info{nsplit_age}.age_limit(1) & label_age <= split_info{nsplit_age}.age_limit(2)) = nsplit_age;
% 
% if bsplit_gender
%     % children class
%     label_split(label_gender == 0) = label_split(label_gender == 0) + 2*nsplit_age;
%     % female class
%     label_split(label_gender == 2) = label_split(label_gender == 2) + 1*nsplit_age;
% end