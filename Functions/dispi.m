function dispi(varargin)
% Format-proof dispi function with verbose option
% This function just disp anything (strings, cells, structs, etc.) 
% You can also just provide all the message parts separated by commas rather
% than producing a string between brackets.
% If dispi is provided with an argument 'verboseOFF' then it just skips that function.
% 'verboseON' is simply ignored.
% 
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

% remove verboseON
varargin(strcmpi(varargin,'verboseON')) = [];

% for each argument, display
string = [];
for i = 1:numel(varargin)
    % create string using disp
    string = [string, local_disp(varargin{i})];
end
% add return carriage for fprintf
string = [string,'\n'];

% display string (using fprintf to allow for returns etc.)
fprintf(string);
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
