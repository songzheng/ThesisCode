addpath ..\..\Tools\Matlab\
addpath(genpath('..\..\Tools\Matlab\'));
addpath ..\..\..\data\

addpath ..\BIFFeature

dataset.label_names = {'age', 'gender', 'OMRONFaceDetection'};
dataset.label_args = {[], [], {'alignment', 'score_max'}};

for name = {'FGNET'}
    dataset.name = name{1};
    dataset = LoadDataset(dataset);
end

