function boxes1 = pascal_test(cls, model, testset, year)

% boxes1 = pascal_test(cls, model, testset, year, suffix)
% Compute bounding boxes in a test set.
% boxes1 are detection windows and scores.

% Now we also save the locations of each filter for rescoring
% parts1 gives the locations for the detections in boxes1
% (these are saved in the cache file, but not returned by the function)

globals;

if exist('year','var')
    VOCyear = year;
else
    year = VOCyear;
end

if exist('testset','var')
    VOCtest = testset;
end

pascal_init;

ids = textread(sprintf(VOCopts.imgsetpath, VOCopts.testset), '%s');

% run detector in each image
try
    load([cachedir cls '_boxes_' VOCopts.testset  '_' year '_' suffix]);
catch
    % parfor gets confused if we use VOCopts
    opts = VOCopts;
    fprintf('%s: testing: %s VOC%s, total %d\n', cls, VOCopts.testset, year, ...
        length(ids));
    if bUseGPU
        model = init_gpu_filters(model, cls, ids, opts);
    end
    
    for i = 1:length(ids)
        if mod(i,round(length(ids)/100))==0
            fprintf('.');
        end
        if strcmp('inriaperson', cls)
            % INRIA uses a mixutre of PNGs and JPGs, so we need to use the annotation
            % to locate the image.  The annotation is not generally available for PASCAL
            % test data (e.g., 2009 test), so this method can fail for PASCAL.
            rec = PASreadrecord(sprintf(opts.annopath, ids{i}));
            im = imread([opts.datadir rec.imgname]);
        else
            im = imread(sprintf(opts.imgpath, ids{i}));
        end
%         tic;
        [dets, boxes] = imgdetect(im, model, model.thresh);
%         toc;
        if ~isempty(boxes)
            boxes = reduceboxes(model, boxes);
            [dets boxes] = clipboxes(im, dets, boxes);
            I = nms(dets, 0.5);
            boxes1{i} = dets(I,[1:4 end]);
            parts1{i} = boxes(I,:);
        else
            boxes1{i} = [];
            parts1{i} = [];
        end
        %showboxes(im, boxes1{i});
    end
    save([cachedir cls '_boxes_' VOCopts.testset '_' year '_' suffix], ...
        'boxes1', 'parts1','-v7.3');
    if bUseGPU
        destroy_gpu_filters(model);
    end
end

