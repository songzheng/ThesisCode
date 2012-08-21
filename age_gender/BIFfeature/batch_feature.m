clear
%%
feature_name = {'BIFMaxPool'};
feat_id = 1;

% config pooling window
patch_size = [4, 8];
opts.win_size = [80,80];
opts.patch_size = patch_size;
opts.pooling = 'max';

% config imag preprocess
opts.histeq = 1;
opts.centersurround = 1;

% config feature
configfunc = str2func([feature_name{feat_id}, 'Init']);
opts.tag = feature_name{feat_id};
opts = configfunc(opts)

%% face images
faces(1).name = 'demo_show.bmp';
feature = FeatureExtraction(faces, opts);
visualizeBIF(feature, opts);