function run_detection(i, annot)
fclose('all');
globals;
if exist('annot','var')
    suffix = annot;
end
pascal_init;

cls = VOCopts.classes{i};
pascal(cls,2);
