function dispi(varargin)
% Format-proof dispi function with verbose option
% This function just disp anything, even numbers. 
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
string=[];
for i=1:numel(varargin)
    % concatenate string
    string=[string,num2str(varargin{i})];
end
% add return carriage for fprintf
string=[string,'\n'];

% display string (using fprintf to allow for returns etc.)
fprintf(string);
return;