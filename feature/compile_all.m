function compile_all
if ~exist('vlfeat_dir', 'var')
    vlfeat_dir = 'D:\My Documents\My Work\Util\vlfeat-0.9.14\toolbox';
end
vl_compile_init

cur_dir = cd;
common_tag = {
'-DTHREAD_MAX=2', ...    
'-DMATLAB_COMPILE',...
['-I' toolboxDir],   ...
['-I' vlDir],        ...
'-I"..\header"',  ...
'-O',                ...
'-outdir', cur_dir};

%% pixel features
file_name = 'pixel_feature';
file_path = [file_name, '.cpp'];
vl_compile_file;

%% patch features
file_name = 'patch_feature';
file_path = [file_name, '.cpp'];
vl_compile_file;

%% coding

file_name = 'coding';
file_path = [file_name, '.cpp'];
vl_compile_file;

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