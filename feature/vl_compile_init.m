cur_dir = cd;
cd(vlfeat_dir);

compiler = 'visualc' ;
switch lower(compiler)
    case 'visualc'
        fprintf('%s: assuming that Visual C++ is the active compiler\n', mfilename) ;
        useLcc = false ;
    case 'lcc'
        fprintf('%s: assuming that LCC is the active compiler\n', mfilename) ;
        warning('LCC may fail to compile VLFeat. See help vl_compile.') ;
        useLcc = true ;
    otherwise
        error('Unknown compiler ''%s''.', compiler)
end

vlDir = vl_root ;
toolboxDir = fullfile(vlDir, 'toolbox') ;

switch computer
    case 'PCWIN'
        fprintf('%s: compiling for PCWIN (32 bit)\n', mfilename);
        binwDir = fullfile(vlDir, 'bin', 'win32') ;
    case 'PCWIN64'
        fprintf('%s: compiling for PCWIN64 (64 bit)\n', mfilename);
        binwDir = fullfile(vlDir, 'bin', 'win64') ;
    otherwise
        error('The architecture is neither PCWIN nor PCWIN64. See help vl_compile.') ;
end

impLibPath = fullfile(binwDir, 'vl.lib') ;
libDir = fullfile(binwDir, 'vl.dll') ;

cd(cur_dir);

% Copy support files  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if ~exist(fullfile(binwDir, 'vl.dll'))
    error('The VLFeat DLL (%s) could not be found. See help vl_compile.', ...
        fullfile(binwDir, 'vl.dll')) ;
end
tmp = dir(fullfile(binwDir, '*.dll')) ;
supportFileNames = {tmp.name} ;
for fi = 1:length(supportFileNames)
    name = supportFileNames{fi} ;
    cp(fullfile(binwDir, name),  ...
        fullfile(cur_dir, name)   ) ;
end

% Ensure implib for LCC ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if useLcc
    lccImpLibDir  = fullfile(mexwDir, 'lcc') ;
    lccImpLibPath = fullfile(lccImpLibDir, 'VL.lib') ;
    lccRoot       = fullfile(matlabroot, 'sys', 'lcc', 'bin') ;
    lccImpExePath = fullfile(lccRoot, 'lcc_implib.exe') ;
    
    mkd(lccImpLibDir) ;
    cp(fullfile(binwDir, 'vl.dll'), fullfile(lccImpLibDir, 'vl.dll')) ;
    
    cmd = ['"' lccImpExePath '"', ' -u ', '"' fullfile(lccImpLibDir, 'vl.dll') '"'] ;
    fprintf('Running:\n> %s\n', cmd) ;
    
    curPath = pwd ;
    try
        cd(lccImpLibDir) ;
        [d,w] = system(cmd) ;
        if d, error(w); end
        cd(curPath) ;
    catch
        cd(curPath) ;
        error(lasterr) ;
    end
end

if useLcc
    libs = lccImpLibPath ;
else
    libs = impLibPath ;
end