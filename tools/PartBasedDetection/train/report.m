function report(title, score, order)

% report(dir, suffix)
% Report AP scores for all models.
% If table=1 we output an HTML table.
% If table=2 we output a latex table.

score = round(score * 1000)/1000;
score = score*100;
% % HTML table
% if nargin >= 2 && table == 1
%   fprintf('<table border="0" cellspacing="10"><tr>\n');
%   fprintf('<td>dir=%s, suffix=%s</td>\n', dir, suffix);
%   for i=1:length(VOCopts.classes)
%     fprintf('<td><b>%s</b></td>\n', VOCopts.classes{i});
%   end
%   fprintf('</tr><tr><td></td>\n');
%   for i=1:length(VOCopts.classes)
%     fprintf('<td>%.3f</td>\n', score(i));
%   end
%   fprintf('</tr></table>\n');
% end
classes1={...
    'office'
    'pet'
    'baby'
    ''
    ''
    ''
    'police'
    ''
    ''
    ''
    ''
    ''
    ''
    ''
    ''
    'fitness'
    'instrument'
    ''
    ''
    ''};

classes2={...
    'worker',...
    'breeder',...
    'sitter',...
    'barber',...
    'driver',...
    'chef',...
    'officer',...
    'doctor',...
    'educator',...
    'farmer',...
    'patrolman',...
    'judge',...
    'lawyer',...
    'mailman',...
    'nurse',...
    'trainer',...
    'player',...
    'receptionist',...
    'soldier',...
    'waiter/ess'};
% latex table
% if nargin > 2 && table == 2
% header
fprintf('\\setlength{\\tabcolsep}{0.05cm}\n')
column_num = 0;
for n = 1:length(order)
    column_num = max(column_num, length(order{n}));
end
fprintf('\\begin{tabular}{|c||');
for i=1:column_num
    fprintf('c');
end
fprintf('|');
fprintf('}\n');
fprintf('\\hline\n');
fprintf('\\hspace {2.0cm}\n ')
for n = 1:length(order)
    cls = order{n};
    % category names
    for c = cls
        fprintf('&');
        fprintf('%s',classes1{c});
    end
    for i = length(cls)+1:column_num
        fprintf('&');
    end
    fprintf('\t\\\\\n');
    for c = cls
        fprintf('&');
        fprintf('%s',classes2{c});
    end
    
    for i = length(cls)+1:column_num
        fprintf('&');
    end
    fprintf('\t\\\\\n');
    fprintf('\\hline\n');

    
    for m = 1:length(title)
        t = strrep(title{m}, '_', '\_');
        fprintf('%s', t);
        for c = cls
            fprintf('&');
            fprintf('\t%.1f',score(m,c));
        end
        
        for i = length(cls)+1:column_num
            fprintf('&');
        end
        fprintf('\\\\\n');
    end
    fprintf('\\hline\\hline\n');
end
% end table
fprintf('\\end{tabular}\n');
