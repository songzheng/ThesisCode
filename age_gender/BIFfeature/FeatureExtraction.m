function feature = FeatureExtraction(data, opts, run_tag)
%%% feature extraction
% feature = FeatureExtraction(data, opts, run_tag)
%     data: images path
%     opts.featfunc: call back to feature extraction function
%     run_tag: feature save folder

if ~isfield(opts, 'win_size')
    opts.win_size=[40,40];
end

win_size = opts.win_size;

fprintf('>>>>--Extract Features---<<<\n');
if ~exist('run_tag', 'var') || ~exist(['feature\',run_tag,'-feature.mat'],'file')
    feature=zeros(length(data), opts.length);
    for i = 1:length(data)
        image=imread(data(i).name);
        if size(image,1)~=win_size(1) || size(image,2)~=win_size(2)
            image=imresize(image,win_size);
        end
        
        if size(image, 3) == 3
            image = rgb2gray(image);
        end
                
        feature(i,:) = opts.featfunc(image, opts);
        if mod(i,round(length(data)/20))==0
            fprintf('%%%d.',round(i*100/length(data)));
        end
    end
    fprintf('\n');
    if exist('run_tag', 'var')
        if ~exist('feature\', 'dir')
            mkdir('feature\');
        end
        save(['feature\',run_tag,'-feature.mat'],'feature','-v7.3');
    end
else
    fprintf('Loading...\n');
    load(['feature\',run_tag,'-feature.mat']);
end

