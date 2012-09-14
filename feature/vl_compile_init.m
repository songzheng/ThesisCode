cur_dir = cd;
cd(vlfeat_dir);

% compiler = 'visualc' ;
% switch lower(compiler)
%     case 'visualc'
%         fprintf('%s: assuming that Visual C++ is the active compiler\n', mfilename) ;
%         useLcc = false ;
%     case 'lcc'
%         fprintf('%s: assuming that LCC is the active compiler\n', mfilename) ;
%         warning('LCC may fail to compile VLFeat. See help vl_compile.') ;
%         useLcc = true ;
%     otherwise
%         error('Unknown compiler ''%s''.', compiler)
% end

vlDir = vl_root ;
toolboxDir = fullfile(vlDir, 'toolbox') ;

switch computer
    case 'PCWIN'
        fprintf('%s: compiling for PCWIN (32 bit)\n', mfilename);
        binwDir = fullfile(vlDir, 'bin', 'win32') ;
        impLibPath = fullfile(binwDir, 'vl.lib') ;
        libDir = fullfile(binwDir, 'vl.dll') ;
    case 'PCWIN64'
        fprintf('%s: compiling for PCWIN64 (64 bit)\n', mfilename);
        binwDir = fullfile(vlDir, 'bin', 'win64') ;
        impLibPath = fullfile(binwDir, 'vl.lib') ;
        libDir = fullfile(binwDir, 'vl.dll') ;
        
    case 'GLNXA64'
        fprintf('%s: compiling for GLNXA64 (64 bit)\n', mfilename);
        binwDir = fullfile(vlDir, 'bin', 'glnxa64') ;
        impLibPath = fullfile(binwDir, 'libvl.so') ;
        libDir = fullfile(binwDir, 'libvl.so') ;
    otherwise
        error('The architecture is not supported') ;
end


cd(cur_dir);

% Copy support files  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if ~exist(libDir)
    error('The VLFeat binary (%s) could not be found. See help vl_compile.', ...
        libDir) ;
end
if ispc
    tmp = dir(fullfile(binwDir, '*.dll')) ;
elseif isunix
    tmp = dir(fullfile(binwDir, '*.so*')) ;
end
    
supportFileNames = {tmp.name} ;
for fi = 1:length(supportFileNames)
    name = supportFileNames{fi} ;
    cp(fullfile(binwDir, name),  ...
        fullfile(cur_dir, name)   ) ;
end

% % Ensure implib for LCC ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% if useLcc
%     lccImpLibDir  = fullfile(mexwDir, 'lcc') ;
%     lccImpLibPath = fullfile(lccImpLibDir, 'VL.lib') ;
%     lccRoot       = fullfile(matlabroot, 'sys', 'lcc', 'bin') ;
%     lccImpExePath = fullfile(lccRoot, 'lcc_implib.exe') ;
%     
%     mkd(lccImpLibDir) ;
%     cp(fullfile(binwDir, 'vl.dll'), fullfile(lccImpLibDir, 'vl.dll')) ;
%     
%     cmd = ['"' lccImpExePath '"', ' -u ', '"' fullfile(lccImpLibDir, 'vl.dll') '"'] ;
%     fprintf('Running:\n> %s\n', cmd) ;
%     
%     curPath = pwd ;
%     try
%         cd(lccImpLibDir) ;
%         [d,w] = system(cmd) ;
%         if d, error(w); end
%         cd(curPath) ;
%     catch
%         cd(curPath) ;
%         error(lasterr) ;
%     end
% end
% 
% if useLcc
%     libs = lccImpLibPath ;
% else
%     libs = impLibPath ;
% end

libs = impLibPath ;
if ispc
    mexopt_file = '"./mexopts.bat"';
elseif isunix
    mexopt_file = '"./mexopts.sh"';
end