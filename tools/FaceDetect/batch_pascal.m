% data = {'IMG_7789.jpg'};

load poselet_test

data = cell(1, length(test));

for i = 1:length(test)
    data{i} = test(i).im;
end

result = OMRON_face_detect(data, 'part');
save result_poselet result

% result = OpenCV_face_detect(data, 'part');
ViewFaceDetection(data, result);