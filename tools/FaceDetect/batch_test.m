% data = {'IMG_7789.jpg'};
% data = [];
% files = dir('test\*.jpg');
% for i = 1:length(files)
%     data{i} = ['test\', files(i).name];
% end
root = 'D:\My Documents\My Work\Face\AgeDemo\matlab_eval\Yamaha';
data = dir([root, '\*.jpg']);
images = {};
for i = 1:length(data)
    images{i} = [root, '/', data(i).name];
end

result = OMRON_face_detect(images, 'part');
% result = OpenCV_face_detect(images, 'part');

save Yamaha_det result images
% result = OpenCV_face_detect(data, 'part');
ViewFaceDetection(images, result);