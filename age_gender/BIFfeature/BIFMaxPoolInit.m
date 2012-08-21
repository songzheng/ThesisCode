function opts = BIFMaxPoolInit(opts)

%%% C1 Layer Bio-inspired feature config
% opts = BIFMaxPoolInit(opts)
%     opts.patch_size: pooling grid size
%     opts.norient: gabor filter orientation #
%     opts.win_size: target image size

% table of gabor filter parameters
table_s1_size = 3:2:37;
table_s1_sigma=[1.5; 2.0; 2.8; 3.6; 4.5; 5.4; 6.3; 7.3; 8.2; 9.2; 10.2; 11.3;...
    12.3; 13.4; 14.6; 15.8; 17.0; 18.2];
table_s1_lambda=[2.3; 2.5; 3.5; 4.6; 5.6; 6.8; 7.9; 9.1; 10.3; 11.5; 12.7; 14.1;...
    15.4; 16.8; 18.2; 19.7; 21.2; 22.8];
s1_gamma = 0.3;

% config garbor filters
patch_size = opts.patch_size;
patch_step = patch_size/2;
opts.norient = 8;
opts.p = [1, opts.norient:-1:2];
norient = opts.norient;
opts.filters1 = cell(length(patch_size), norient);
opts.filters2 = cell(length(patch_size), norient);
opts.length = 0;
opts.length_nonsym = 0;
for i = 1:length(patch_size)
    idx1 = find(table_s1_size == patch_size(i)-1);
    opts.filters1(i, :) = MakeGaborFilter(table_s1_size(idx1), ...
        norient, table_s1_sigma(idx1), table_s1_lambda(idx1), s1_gamma);
    
    idx2 = find(table_s1_size == patch_size(i)+1);
    opts.filters2(i, :) = MakeGaborFilter(table_s1_size(idx2), ...
        norient, table_s1_sigma(idx2), table_s1_lambda(idx2), s1_gamma);
    
    map_size = opts.win_size - [patch_size(i),patch_size(i)];
    [grid_x, grid_y, grid_num]= GridCal(map_size, [patch_size(i),patch_size(i)],...
        [patch_step(i),patch_step(i)],'m');
    for j = 1:norient
        opts.grid{i, j} = [grid_x, grid_y, grid_x+patch_size(i)-1, grid_y+patch_size(i)-1];
        opts.grid_num{i, j} = grid_num;
    end
    
    sym_grid = [grid_num(1), ceil(grid_num(2)/2)];
    
    opts.length = opts.length + prod(sym_grid) * norient;
    opts.length_nonsym = opts.length_nonsym + prod(grid_num) * norient;
end

% require for symmetric or non-symmetric feature
opts.func_feat = @BIFFeat;
opts.func_feat_nonsym = @BIFFeatNonSymmetric;

% switch between max-pooling and std-pooling
if strcmp(opts.pooling, 'max')
    opts.poolfunc = @C1MaxPooling;
elseif strcmp(opts.pooling, 'std')
    opts.poolfunc = @C1StdPooling;
end

opts.tag = [opts.tag, num2str(opts.length), opts.pooling];

function feat = BIFFeat(im, opts)

if opts.histeq
    im = histeq(im);
end

if opts.centersurround
	im = CenterSurround(im, [6,6]);
end

s1_1 = S1ConvFilter1(im, opts.filters1);
s1_2 = S1ConvFilter2(im, opts.filters2);
c1 = opts.poolfunc(s1_1, s1_2, opts);
c1 = C1Symmetric(c1, opts);
c1 = C1Normalize(c1);
feat = [];
for i = 1:size(c1,1)
    for j = 1:size(c1, 2)
        feat = [feat, c1{i,j}(:)'];
    end
end

function feat = BIFFeatNonSymmetric(im, opts)
if opts.histeq
    im = histeq(im);
end

if opts.centersurround
	im = CenterSurround(im, [6,6]);
end
s1_1 = S1ConvFilter1(im, opts.filters1);
s1_2 = S1ConvFilter2(im, opts.filters2);
c1 = opts.poolfunc(s1_1, s1_2, opts);
c1 = C1Normalize(c1);

feat = [];
for i = 1:size(c1,1)
    for j = 1:size(c1, 2)
        feat = [feat, c1{i,j}(:)'];
    end
end

function feat = S1ConvFilter1(im, filter)
feat = fconv(im, filter(:), 1, numel(filter));
for i = 1:numel(filter)
    feat{i} = feat{i}(2:end-1, 2:end-1);
end
feat = reshape(feat, size(filter));


function feat = S1ConvFilter2(im, filter)
feat = fconv(im, filter(:), 1, numel(filter));
feat = reshape(feat, size(filter));

function c1 = C1StdPooling(s1_1, s1_2, opts)
c1 = cell(size(s1_1));
grid = opts.grid;
grid_num = opts.grid_num;
for i = 1:numel(s1_1)
    map1 = s1_1{i};
    map2 = s1_2{i};
    g = grid{i};
    map = max(map1, map2);
    f = zeros(1,length(g));
    for j = 1:length(g)
        tmp = map(g(j,1):g(j,3), g(j,2):g(j,4));
        f(j) = std(tmp(:));
    end
    c1{i} = reshape(f, grid_num{i});
end

function c1 = C1MaxPooling(s1_1, s1_2, opts)
c1 = cell(size(s1_1));
grid = opts.grid;
grid_num = opts.grid_num;
for i = 1:numel(s1_1)
    map1 = s1_1{i};
    map2 = s1_2{i};
    g = grid{i};
    f1 = zeros(1,length(g));
    for j = 1:length(g)
        f1(j) = max(max(map1(g(j,1):g(j,3), g(j,2):g(j,4))));
    end
    f2 = zeros(1,length(g));
    for j = 1:length(g)
        f2(j) = max(max(map2(g(j,1):g(j,3), g(j,2):g(j,4))));
    end
    c1{i} = reshape( max(f1, f2), grid_num{i});
    c1{i} = max(c1{i}, 0);
end

function c1 = C1Normalize(c1)
for i = 1:size(c1,1)
    norm = 0;
    for j = 1:size(c1,2)
        norm = norm + sum(sum(c1{i, j}.^2));
    end
    
    norm = sqrt(norm) + eps;    
    for j = 1:size(c1,2)
        c1{i,j} = c1{i,j}/norm;
    end
end

function c1 = C1Symmetric(c1, opts)
for i = 1:size(c1,1)           
    tmp = zeros([size(c1{i, 1}), size(c1,2)]);
    
    for j = 1:size(c1, 2)
        tmp(:,:,j) = c1{i, j};
    end    
    
    width = ceil(size(c1{i, 1}, 2)/2);
    tmp = (tmp + flipfeat(tmp, opts.p))/2;
    tmp = tmp(:, 1:width, :);
    
    for j = 1:size(c1, 2)
        c1{i, j} = tmp(:,:,j);
    end    
end


function filter = MakeGaborFilter(fsize, norient, sigma, lambda, gamma)
% --------------------------------------------------------
% G(x,y)=exp(-(X^2+gamma^2*Y^2)/2/sigma^2)
%       *cos(2*pi/lambda*X)
% X=x*cos(theta)+y*sin(theta)
% Y=-x*sin(theta)+y*cos(theta)
% --------------------------------------------------------
filter = cell(1, norient);
for i = 1:norient
    theta = (i-1)*pi/norient;
    x=-floor(fsize/2):floor(fsize/2);
    y=-floor(fsize/2):floor(fsize/2);
    [grid_y,grid_x]=meshgrid(y,x);
    grid_x2=grid_x*cos(theta)+grid_y*sin(theta);
    grid_y2=-grid_x*sin(theta)+grid_y*cos(theta);
    filter{i}=exp(-(grid_x2.^2+gamma^2*grid_y2.^2)/2/sigma^2)...
        .*cos(2*pi/lambda*grid_x2);
    
    filter{i} = filter{i} - mean(mean(filter{i}));
    filter{i} = filter{i} ./ sqrt(sum(sum(filter{i}.^2)));
end