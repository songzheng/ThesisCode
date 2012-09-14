clear;
addpath ..\tools
addpath(genpath('..\tools'));
addpath ..\feature\
addpath ..\..\data

name = 'WebFace';

disp(name);
dataset.label_names = {'age', 'gender', 'OMRONFaceDetection'};
dataset.label_args = {[], [], {'alignment', 'score_max'}};
dataset.name = name;
dataset = LoadDataset(dataset);
dataset.boxes = {dataset.OMRONFaceDetection.det};

opt = InitializeFeature('PatchAppearance',...
    'codebook_name', 'WebFace',...
    'codebook_size', 100,...
    'reduced_dim', 10,...
    'dataset', dataset);