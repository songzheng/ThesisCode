function Performance = AgeEvaluationTest(feature, label, model)

w = model(1:end-3);
gamma = model(end-2);
age_limit = model(end-1:end);
res_center = mean(age_limit);

label = max(min(label, age_limit(2)), age_limit(1));
label = label(:);
div = age_limit(1):10:age_limit(2);
div(end) = age_limit(2);

MAEs = zeros(1, 1);
MAEs_interval = zeros(length(div)-1, 1);
Accs = zeros(2, 1);

nsample = size(feature,1);

feature = [feature, ones(nsample,1)];


test_res = (feature * w - res_center)/gamma + res_center;
test_res = max(min(test_res, age_limit(2)), age_limit(1));
MAEs = mean(abs(test_res - label));

for i = 1:length(div)-1
    div_idx = find(label >= div(i) & label <= div(i+1));
    MAEs_interval(i) = mean(abs(test_res(div_idx) - label(div_idx)));
end

Accs(1) = length(find(abs(test_res - label)<=10))/length(test_res);
Accs(2) = length(find(abs(test_res - label)<=5))/length(test_res);
Performance = [MAEs;Accs; MAEs_interval];

% report
fprintf('MAE = %f(%f), Acc in 10 years = %f(%f), Acc in 5 years = %f(%f)\n',...
    mean(MAEs), std(MAEs), mean(Accs(1, :)), std(Accs(1, :)),mean(Accs(2, :)), std(Accs(2, :)));

for i = 1:length(div)-1
    fprintf('Age %d to %d: MAE = %f\n', div(i), div(i+1), MAEs_interval(i));
end