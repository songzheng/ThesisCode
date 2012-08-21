function result = GetOMRONFaceDetection(dataset, type, sel)

if ~exist('type', 'var') || isempty(type)
    type = 'alignment';
end
if ~exist('sel', 'var') || isempty(type)
    sel = 'all';
end

data = dataset.image_names;
data_root = dataset.data_root;
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
        fprintf(fin, '%s/%s\n', data_root, data{i});
        count = count + 1;
    end
end
fclose(fin);

cmd = ['"', fileparts(mfilename('fullpath')) '/' 'OMRONDetect" ', name, '.input ', name, '.output ', tag];
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
    line = fgetl(fout);
    % ensure file name match
    if(~isempty(data{i}))
        assert(strcmp(line, [data_root, '/', data{i}]));
    end
    
    % obtain detections
    tmp = [];
    det_num = str2double(fgetl(fout));
    for n = 1:det_num
        line = fgetl(fout);
        line(line == ';') = ',';
        det = str2num(line);
        tmp = [tmp,parse_omron_det(det)];
    end
    
    if det_num == 0
        continue;
    end
    
    switch sel
        case 'all'
            result{i} = tmp;
        case 'center_most'
            imsize = size(imread([data_root, '/', data{i}]));
            center = imsize([2,1])/2;
            center = center(:);
            det_center = zeros([2, length(tmp)]);
            for j = 1:length(tmp)
                det_center(:, j) = mean(tmp(j).det, 2);
            end
            
            dis = bsxfun(@minus, det_center, center);
            dis = sum(dis.^2);
            [~, res_idx] = min(dis);
            result(i) = tmp(res_idx);
        case 'score_max'
            [~, res_idx] = max([tmp.det_conf]);
            result(i) = tmp(res_idx);
            
        otherwise
            error('Unsupport detection screen');
    end
            
end
fclose(fout);
result = result(:);
delete([name, '.input']);
delete([name, '.output']);

function res = parse_omron_det(input)

% Definition of feature pt indices
% 	FEATURE_NO_POINT = -1,
% 	FEATURE_LEFT_EYE = 0,				
% 	FEATURE_RIGHT_EYE,					
% 	FEATURE_MOUTH,				
% 	FEATURE_LEFT_EYE_IN,				
% 	FEATURE_LEFT_EYE_OUT,				
% 	FEATURE_RIGHT_EYE_IN,				
% 	FEATURE_RIGHT_EYE_OUT,				
% 	FEATURE_MOUTH_LEFT,					
% 	FEATURE_MOUTH_RIGHT,				
% 	FEATURE_LEFT_EYE_PUPIL,				
% 	FEATURE_RIGHT_EYE_PUPIL,			
% 	FEATURE_KIND_MAX	

res.det = [];
res.det_conf = [];
res.rotation = [];
res.rotation_conf = [];
res.part_conf = [];
res.part_conf = [];
res.contour = [];
res.contour_conf = [];

PART_MAX = 11;
CONTOUR_MAX = 87;

[det, input] = ReadRes(input);
assert(det.n == 8);
res.det = reshape(det.res(:), [2, 4]);
res.det_conf = det.conf;

if isempty(input)
    return;
end

[rot, input] = ReadRes(input);
assert(rot.n == 3);
res.rotation = rot.res;
res.rotation_conf = rot.conf;

if isempty(input)
    return;
end

[part, input] = ReadRes(input);
assert(part.n == PART_MAX*2);
res.part = reshape(part.res(:), [2, PART_MAX]);
res.part_conf = part.conf;

if isempty(input)
    return;
end

[contour, input] = ReadRes(input);
assert(contour.n == CONTOUR_MAX*2);
res.contour = reshape(contour.res(:), [2, CONTOUR_MAX]);
res.contour_conf = contour.conf;

if isempty(input)
    return;
end
