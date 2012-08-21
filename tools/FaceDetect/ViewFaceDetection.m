function ViewFaceDetection(data, result)
figure(10);
for i = 1:length(data)
    clf;
    im = imread(data{i});
    imshow(im);
    hold on;
    for n = 1:length(result{i})
        line(result{i}(n).det(1, [1,2,4,3,1]),...
            result{i}(n).det(2, [1,2,4,3,1]));
        if isfield(result{i}(n), 'part')
            scatter(result{i}(n).part(1, :), result{i}(n).part(2, :), '.');
        end
        if isfield(result{i}(n), 'contour')
            scatter(result{i}(n).contour(1, :), result{i}(n).contour(2, :), '.');
        end
    end
    pause;
end
close(10);