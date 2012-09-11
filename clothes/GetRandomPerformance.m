function rand_performance = GetRandomPerformance(label)
k = 100;
label = label(label ~= 0);
performance = zeros(1, 100);
for i = 1:1000
    score = rand(size(label));
    performance(i) = APBalanced(score, label);
end

rand_performance = mean(performance);