function compile_all
if ~exist('vlfeat_dir', 'var')
    vlfeat_dir = '..\tools\vlfeat\toolbox';
end
vl_compile_init

cur_dir = cd;
common_tag = {
'-DTHREAD_MAX=2', ...    
'-DOPEN_MP',...
'-DMATLAB_COMPILE',...
'-DWIN32',...
'-f', '".\mexopts.bat"',...
['-I' toolboxDir],   ...
['-I' vlDir],        ...
'-I"..\header"',  ...
'-O',...
'-outdir', cur_dir};

%% obj
compile_file('image', common_tag, 1);
compile_file('pixel_feature', common_tag, 1);
compile_file('coding', common_tag, 1);
compile_file('pooling', common_tag, 1);
compile_file('patch_feature', common_tag, 1);
 
%% mex

compile_file('pixel_feature_mex', common_tag, 0, {libs, 'image', 'pixel_feature'});
compile_file('coding_mex', common_tag, 0, {libs, 'image','coding'});
compile_file('patch_feature_mex', common_tag, 0, {libs, 'image', 'coding', 'pixel_feature', 'pooling', 'patch_feature'});

function compile_file(file, tag, gen_obj, libs)
if ~exist('libs', 'var')
    libs = {};
end

file_path = [file, '.cpp'];
fprintf('MEX %s\n', file);
if gen_obj
    tag = [tag, {'-c'}];
end   

for i = 1:length(libs)
    [~,~,ext] = fileparts(libs{i});
    if isempty(ext)
        libs{i} = [libs{i}, '.obj'];
    end
end

cmd = [tag, file_path, libs];
mex(cmd{:});

% --------------------------------------------------------------------
function cp(src,dst)
% --------------------------------------------------------------------
if ~exist(dst,'file')
    fprintf('Copying ''%s'' to ''%s''.\n', src,dst) ;
    copyfile(src,dst) ;
end

% --------------------------------------------------------------------
function mkd(dst)
% --------------------------------------------------------------------
if ~exist(dst, 'dir')
    fprintf('Creating directory ''%s''.', dst) ;
    mkdir(dst) ;
end

function tag = get_compile_tag(opt)
tag = [];
tag{1} = '-output';
tag{2} = ['"', opt.source, '_', opt.name, '"'];
tag{3} = '-DMATLAB_COMPILE';

if isfield(opt, 'pixel_name')
    tag{end+1} = ['-DPIXEL_FEATURE_NAME=', opt.pixel_name];
end

if isfield(opt, 'patch_name')
    tag{end+1} = ['-DPATCH_FEATURE_NAME=', opt.patch_name];
end

if isfield(opt, 'coding_name')
    tag{end+1} = ['-DCODING_NAME=', opt.coding_name];
end