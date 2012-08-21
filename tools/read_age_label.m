addpath xml2struct

age_tasks = xml2struct('tasks.xml');
age_tasks = age_tasks.Tasks.Task;

root = 'age_data_clean';
for i = 1:length(age_tasks)
    
    labeler = regexp (age_tasks{i}.State.Text, ',', 'split');
    if ~strcmp(labeler{1}, 'Finished')
        fprintf('%s is not finished\n', age_tasks{i}.ID.Text);
        continue;
    end
    fprintf('%s - %s\n', age_tasks{i}.ID.Text, labeler{2});
    
    if ~exist([root, '\', age_tasks{i}.ID.Text, '\'], 'dir')
        mkdir([root, '\', age_tasks{i}.ID.Text, '\']);
    end
    
    labels = xml2struct([age_tasks{i}.Dir.Text, '\', labeler{2}, '.anno']);
    labels = labels.ImageAnnotationTaskMultipleChoice;
    assert(str2double(labels.NumberOfImage.Text) == str2double(labels.PointerOfAnnotation.Text));
    
    annot = cell2mat(labels.Annotations.Annotation);
    annot = str2double({annot.Text});
    
    images = cell2mat(labels.ImageFiles.ImageFile);
    images = {images.Text};
    
    for idx = find(annot == 0)
        copyfile([age_tasks{i}.Dir.Text, '\', images{idx}], [root, '\', age_tasks{i}.ID.Text, '\', images{idx}]);
    end
end


num_age = zeros(1, 80);
for i = 1:80
    num_age(i) = length(dir([root, '\', age_tasks{i}.ID.Text, '\*.jpg']));
end

bar(num_age);