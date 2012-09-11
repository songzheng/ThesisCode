addpath detection\

name = 'upperbody_detection';
load(['detection\', name]);

root = ['E:\Code\DressingDemo\datasets\fasionspace_whole\dresses\LUISAVIAROMA_Affiliate_Program-Complete_Catalog_'];
figure(1);
for i = 1:5000
try 
    im = imread([root, num2str(i), '.jpg']);
    boxes = DetectPartBox(im, model, name);
    fprintf('%d:%f\n', i, boxes(end));
    showskeleton(im, boxes, model);
    print(gcf, ['detect_test\', num2str(i), '.jpg'], '-djpeg');
catch
end
end