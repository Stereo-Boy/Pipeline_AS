function dispi(varargin)
% Format-proof dispi function with verbose option
% This function just disp anything (strings, cells, structs, etc.) 
% You can also just provide all the message parts separated by commas rather
% than producing a string between brackets.
% If dispi is provided with an argument 'verboseOFF' then it just skips that function.
% 'verboseON' is simply ignored.
% If argument 'line length' is provided and followed by a value, it will
% display only this value amount of characters on each line (default)
% Example:
% 
% dispi('Sometimes it''s nice to separate\n',4,'\ndifferent\nlines!');
%
% Sometimes it's nice to separate
% 4
% different
% lines!
%
% dispi('Sometimes I don''t want to display anything','verboseOFF');
%
% Created by Adrien Chopin, nov 2016

% check for verboseOFF
if any(strcmpi(varargin,'verboseOFF')), return; end;
if any(strcmpi(varargin,'line length')), idx = find(strcmpi(varargin,'line length')); lineLength= varargin{idx+1}; varargin(idx:idx+1)=[];
else lineLength=151; end

% remove verboseON
varargin(strcmpi(varargin,'verboseON')) = [];

% for each argument, display
string = [];
for i = 1:numel(varargin)
    % create string using disp
    string = [string, local_disp(varargin{i})];
end
% add return carriage for fprintf
%string = [string,'\n'];

% display string (using fprintf to allow for returns etc.)
%fprintf(string);
cleanDisp(string,lineLength)
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

char2disp=length(text);
while char2disp>0
    if char2disp>len
        char2disp=char2disp-len;
        fprintf(text(1:len)); fprintf('\n');
        text(1:len)=[];
    else
        fprintf(text); fprintf('\n');
        char2disp=0;
    end
end

end
