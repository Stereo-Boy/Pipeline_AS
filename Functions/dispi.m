function dispi(varargin)
% Format-proof dispi function with verbose option
% This function just disp anything (strings, cells, structs, etc.) 
%
% You can also just provide all the message parts separated by commas rather
% than producing a string between brackets.
%
% If dispi is provided with an argument 'verboseOFF' then it just skips that function.
% 'verboseON' is simply ignored.
%
% If argument 'line length' is provided and followed by a value, it will
% display only this amount of characters on each line (default is [], which
% will not split lines)
%
% Example 1: 
% dispi('Sometimes it''s nice to separate\n',4,'\ndifferent\nlines!');
%
% Sometimes it's nice to separate
% 4
% different
% lines!
%
% Example 2:
% dispi('Sometimes I don''t want to display anything','verboseOFF');
%
% Example 3:
% dispi(repmat('this',1,25), 'line length', 25)
% 
% thisthisthisthisthisthist
% histhisthisthisthisthisth
% isthisthisthisthisthisthi
% sthisthisthisthisthisthis
% 
% Created by Adrien Chopin, nov 2016

% check for verboseOFF
if any(strcmpi(varargin,'verboseOFF')), return; end;
% check for line length
if any(strcmpi(varargin,'line length')), 
    idx = find(strcmpi(varargin,'line length')); 
    lineLength = varargin{idx+1}; varargin(idx:idx+1)=[];
else % default no line length
    lineLength = []; 
end

% remove verboseON
varargin(strcmpi(varargin,'verboseON')) = [];

% for each argument, display
string = [];
for i = 1:numel(varargin)
    % create string using disp
    string = [string, local_disp(varargin{i})];
end
% replace % with %% to avoid errors
string = strrep(string, '%', '%%');

% if no line length, fprintf
if isempty(lineLength),
    fprintf([string, '\n']);
else % display string using cleanDisp
    cleanDisp(string,lineLength)
end
end

function str = local_disp(var)
% use disp function to get string of var

% get string using disp
str = evalc('disp(var)');
% if not char, remove beginning spaces (e.g., cell arrays)
if ~ischar(var), str = regexprep(str,{'^\s+','\n\s+'},{'','\n'}); end;
% remove end returns
str = regexprep(str,'\n$','');
end

function cleanDisp(text,len)
%disp a text cleanly on the command window with return to line at the end
%of the screen (len characters)

for x = 1:len:numel(text),
    % print text of length len line by line
    fprintf([text(x:min(x+len-1, end)), '\n']);
end
end
