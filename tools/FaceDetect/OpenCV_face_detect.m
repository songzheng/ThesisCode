function result = OpenCV_face_detect(data, type)
dim = size(data);

switch type
    case 'detect'
        result = cell(dim);
        tag = 'd';
    case 'part'
        result = cell(dim);
        tag = 'p';
    case 'alignment'
        tag = 'a';
    otherwise
end
count = 0;
name = datestr(now, 30);
fin = fopen([name, '.input'], 'w');
for i = 1:numel(data)
    if isempty(data{i})
        fprintf(fin, '0\n');
    else
        fprintf(fin, '%s\n', data{i});
        count = count + 1;
    end
end
fclose(fin);

cmd = ['OpenCVDetect ', name, '.input ', name, '.output ', tag];
tic;
status = dos(cmd);
time = toc;
if status ~= 0
    fprintf('Execute not successful\n');
    keyboard;
end

fprintf('Detected at %f sec per image\n', time/count);

fout = fopen([name, '.output'], 'r');
if(~fout)
    fprintf('Cannot obtain output result\n');
    return;
end
for i = 1:numel(data)
    result{i} = [];
    line = fgetl(fout);
    % ensure file name match
    if(~isempty(data{i}))
        assert(strcmp(line, data{i}));
    end
    
    % obtain detections
    det_num = str2double(fgetl(fout));
    if det_num > 0
        for n = 1:det_num
            det = str2num(fgetl(fout));
            result{i} = [result{i},parse_opencv_det(det, type)];
        end
    end
end
fclose(fout);

function r = parse_opencv_det(det, type)
idx = 1;
r.corners = reshape(det(idx:idx+7), [2, 4]);
if strcmp(type, 'detect')
    return;
end

idx = 9;
parts = reshape(det(idx:end), [2, (length(det)-8)/3]);
r.parts = parts(1:2, :);
