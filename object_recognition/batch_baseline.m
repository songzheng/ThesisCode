addpath ..\..\Tools\Matlab\
addpath(genpath('..\..\Tools\Matlab\'));
addpath ..\..\..\data\
addpath ..\3rdParty\
addpath 'E:\Thesis\code\GitHub\lv-nus-feature\feature\mex'

dataset.label_names = {'object_class'};
dataset.label_args = {[]};

dataset.name = 'Caltech101';

dataset = LoadDataset(dataset);