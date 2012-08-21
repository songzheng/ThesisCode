ages = 1:80;
FileName = 'info.xml';
Root = cd;

for i = 1:length(ages)
    path = [Root, '\', num2str(ages(i))];
    fid = fopen([path, '\', FileName], 'w');
    fprintf(fid, '<Task>\n');
    fprintf(fid, '\t<Question>Is the person around %d years old?</Question>\n', ages(i));
    fprintf(fid, ['\t<Choices>\n'...
			'\t\t<Choice>Yes</Choice>\n',...
			'\t\t<Choice>No</Choice>\n',...
			'\t\t<Choice>Unclear</Choice>\n',...
            '\t</Choices>\n']);
    fprintf(fid, '</Task>\n');
    
    fclose(fid);
end

fid = fopen('Tasks.xml', 'w');
fprintf(fid, '<Tasks>\n');
for i = 1:length(ages)
    fprintf(fid, '\t<Task>\n');
    path = [Root, '\', num2str(ages(i))];
    fprintf(fid, '\t\t<Dir>%s</Dir>\n', path);
    fprintf(fid, '\t\t<ID>Age_%d</ID>\n', i);
    fprintf(fid, '\t\t<State>NotStart</State>\n');
    fprintf(fid, '\t</Task>\n');
end
fprintf(fid, '</Tasks>\n');
fclose(fid);