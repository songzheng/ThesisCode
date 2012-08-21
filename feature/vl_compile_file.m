
fprintf('MEX %s\n', file_name);
cmd = [common_tag, file_path] ;
if useLcc
    cmd{end+1} = lccImpLibPath ;
else
    cmd{end+1} = impLibPath ;
end
mex(cmd{:}) ;