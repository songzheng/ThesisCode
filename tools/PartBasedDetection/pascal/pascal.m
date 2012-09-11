function [ap1, ap2] = pascal(cls, n, dotrainval, testyear)

% ap = pascal(cls, n, note)
% Train and score a model with 2*n components.
% note allows you to save a note with the trained model
% example: note = 'testing FRHOG (FRobnicated HOG) features'
% testyear allows you to test on a year other than VOCyear (set in globals.m)

globals;
pascal_init;

if ~exist('dotrainval','var')
  dotrainval = false;
end

if ~exist('testyear','var')
  % which year to test on -- a string, e.g., '2007'.
  testyear = VOCyear;
end

if ~exist('cleantmpdir','var')
    cleantmpdir = 1;
end

% record a log of the training procedure
diary([cachedir cls '.log']);

% set the note to the training time if none is given
note = datestr(datevec(now()), 'HH-MM-SS');

% train
fprintf('***********************************\n');
fprintf('In Training: Object Class %s\n', cls);
fprintf('***********************************\n');
model = pascal_train(cls, n, note);
% lower threshold to get high recall
model.thresh = min(-1.1, model.thresh);

fprintf('***********************************\n');
fprintf('In Testing and Eval: Object Class %s\n', cls);
fprintf('***********************************\n');
boxes1 = pascal_test(cls, model);
ap1 = pascal_eval(cls, boxes1);

ap2 = 0;
% fprintf('***********************************\n');
% fprintf('In Boundingbox Pred and Eval: Object Class %s\n', cls);
% fprintf('***********************************\n');
% ap2 = bboxpred_rescore(cls,[],[],'minl2');

% compute detections on the trainval dataset (used for context rescoring)
if dotrainval
  trainval(cls);
end

% remove dat file if configured to do so
if cleantmpdir
    delete([tmpdir cls '.dat']);
end
