
%% patch HOG
addpath baseline
opt = InitializeFeature('PatchHOG', 'sbin', 16, 'norient', 9, 'half_sphere', 1);

im = imread('..\test_data\test.jpg');
im = rgb2gray(im);
% func(im, [], opt);
[feat_all, grids] = ExtractFeature(im, opt);

% feat_all = feat_all(:,:,1:9) + feat_all(:, :, 10:18);
% im = rgb2gray(im);

% baseline
im = imread('..\test_data\test.jpg');
feat_base = features_hog(double(im), 8);
feat_base = feat_base(:, :, 1:9) + feat_base(:, :, 10:18) + feat_base(:, :, 19:27);
figure(1);
clf;
subplot(1,2,1);
imshow(FeatureVisualizeDenseHOG(permute(feat_all, [2,3,1]), [], 20));
subplot(1,2,2);
imshow(FeatureVisualizeDenseHOG(feat_base, [], 20))

%% patch HOG speed test
% HOG  0.0202 (2 thread with open MP)  0.0313 (1 thread) vs UoC HOG  0.0228s

addpath baseline
opt = InitializeFeature('PatchHOG', 'sbin', 16, 'norient', 9, 'half_sphere', 1);

im = imread('..\test_data\test.jpg');
im = rgb2gray(im);
tic;
for i = 1:500
    [feat_all, grids] = ExtractFeature(im, opt);
end
disp(toc/500);

im = imread('..\test_data\test.jpg');
tic;
for i = 1:500
    feat_base = features_hog(double(im), 8);
end
disp(toc/500);
%% patch appearance VQ test
opt = InitializeFeature('PixelGray4x4DCT');
im = imread('..\test_data\test.jpg');
[feat_all, grids] = ExtractFeature(im, opt);


%% dsift
addpath 'D:\My Documents\My Work\Util\vlfeat-0.9.14\toolbox'
vl_setup;
im = imread('..\..\test\test.jpg');
im = rgb2gray(im);
tic;
for i = 1:100
    [coord, feature] = vl_dsift(single(im), 'Size', 4, 'Step', 4);
end
disp(toc/100);
opt = FeatureInit('HOG', 8, 8);
opt.cell_size = [4,4];
im = imread('..\..\test\test.jpg');
im = rgb2gray(im);
tic;
for i = 1:100
    [feat, point] = ExtractPatchFeature(im, [], opt);
end

disp(toc/100);


%%
addpath baseline
addpath 'D:\My Documents\My Work\Util\vlfeat-0.9.13\toolbox'
load dsift_fk_ver21
vl_setup;

im = imread('..\test_data\test.jpg');
[~, feature] = vl_dsift(single(rgb2gray(im)));
feature = feature(:, 1:10000);
feature = single(feature);
feature = bsxfun(@rdivide, feature, sqrt(sum(feature.^2))+eps);
feature = (feature'*eigenvector(:, 1:80))';

codebook.mu = GMM.Mu;
[codebook.nDim, codebook.nBase] = size(codebook.mu);
codebook.priors = GMM.Priors;
codebook.sigma = GMM.Sigma;

codebook.sqrtPrior = sqrt(codebook.priors);
codebook.sqrt2Prior = sqrt(2*codebook.priors);
codebook.invSigma = 1./codebook.sigma;
codebook.sqrtInvSigma = 1./sqrt(codebook.sigma);
codebook.sumLogSigma = sum(log(codebook.sigma)) + codebook.nDim * log(2*pi);

coding_opt.name = 'CodingFisherVector';
coding_opt.fv_codebook = codebook;

% coding(feature, coding_opt);
feature = single(feature);
feat_all = codingmex(feature, coding_opt);

% 0.4943s for 1 thread, 0.2820s for 2 thread using OpenMP
tic;
for i = 1:100
    feat_all = codingmex(feature, coding_opt);
end
disp(toc/100);

%%
feature = double(feature);
prob_base = fisher_vector_coding(1, feature, GMM);
prob_base = prob_base';
[prob_base, idx_base] = sort(prob_base, 1, 'descend');
idx_base = idx_base - 1;

feat_base = [];
for i = 1:10
    feat_tmp = fisher_vector_coding(3, feature(:,i), GMM);
    ii = [];
    for j = 1:7
        ii = [ii, idx(j, i)*2*codebook.nDim+1:(idx(j, i)+1)*2*codebook.nDim];
    end
    feat_base = [feat_base, feat_tmp(ii)];
end
% 0.4826s for 1 thread,  0.2934 for 2 thread
tic;
for i = 1:100
    ftmp = fisher_vector_coding(3, feature, GMM);
end
disp(toc/100);

%%
% LBP  0.0212s vs LBP ver1  0.0157s
im = imread('..\..\test\test.jpg');
im = rgb2gray(im);
tic;
for i = 1:500
    [feat_all, coordinate] = patch_feature_LBP(im, [], opt);
    feat_all = bsxfun(@rdivide, feat_all, sqrt(sum(feat_all.^2)));
end
disp(toc/500);

im = imread('..\..\test\test.jpg');
im = rgb2gray(im);
tic;
for i = 1:500
    feat_base = features_lbp(double(im), 8);
end
disp(toc/500);