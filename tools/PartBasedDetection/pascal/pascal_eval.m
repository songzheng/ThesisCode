function ap = pascal_eval(cls, boxes, testset, year, eval_suffix)

% ap = pascal_eval(cls, boxes, testset, suffix)
% Score bounding boxes using the PASCAL development kit.

globals;
if exist('testset','var')
    VOCtest = testset;
end

if exist('year','var') && ~isempty(year)
    VOCyear = year;
else
    year = VOCyear;
end

if exist('eval_suffix','var') && ~isempty(eval_suffix)
    suffix = eval_suffix;
else
    eval_suffix = suffix;
end

pascal_init;
try
    load([cachedir cls '_pr_' VOCopts.testset '_' year '_' suffix], 'recall', 'prec', 'ap');
catch
    ids = textread(sprintf(VOCopts.imgsetpath, VOCopts.testset), '%s');
    
    % write out detections in PASCAL format and score
    fid = fopen(sprintf(VOCopts.detrespath, 'comp3', cls), 'w');
    for i = 1:length(ids);
        bbox = boxes{i};
        for j = 1:size(bbox,1)
            fprintf(fid, '%s %f %d %d %d %d\n', ids{i}, bbox(j,end), bbox(j,1:4));
        end
    end
    fclose(fid);
    
    if ~exist([cachedir suffix], 'dir')
        mkdir([cachedir suffix]);
    end
    fid = fopen([cachedir,suffix, '\comp3_det_',VOCopts.testset,'_', cls, '.txt'], 'w');
    for i = 1:length(ids);
        bbox = boxes{i};
        for j = 1:size(bbox,1)
            fprintf(fid, '%s %f %d %d %d %d\n', ids{i}, bbox(j,end), bbox(j,1:4));
        end
    end
    fclose(fid);
    
    if ~bEval
        ap = [];
        return;
    end
    
    if str2num(VOCyear) == 2006
        [recall, prec, ap] = VOCpr(VOCopts, 'comp3', cls, true);
    elseif str2num(VOCyear) < 2008
        [recall, prec, ap] = VOCevaldet_2007(VOCopts, 'comp3', cls, true);
    elseif str2num(VOCyear) >= 2008 && str2num(VOCyear)<=2010
        [recall, prec, ap] = VOCevaldet(VOCopts, 'comp3', cls, true);
    else
        error('Failed to evaluate dataset');
    end
    
    % if str2num(VOCyear) < 2008
    % force plot limits
    ylim([0 1]);
    xlim([0 1]);
    
    % save results
    save([cachedir cls '_pr_' VOCopts.testset '_' year '_' suffix], 'recall', 'prec', 'ap');
    print(gcf, '-djpeg', '-r0', [cachedir cls '_pr_' VOCopts.testset '_' suffix '.jpg']);
end
