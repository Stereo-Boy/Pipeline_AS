function warning_error(varargin)
% warning_error(...)
% Display warning or error with inputs.
%
% Inputs:
% string or number inputs to be concatenated (can include special chars)
% 'errorON': throw an error with string message (default 'errorOFF')
% 'verboseOFF': do not throw warning (default 'verboseON')
%
% Example 1: throw an error to stop function
% warning_error('This is the ',2,'nd error!','errorON')
% 
% Error using warning_error (line 37)
% This is the 2nd error!
%
% Example 2: throw a multiline warning without error
% warning_error('A \n ',2,' line warning','errorOFF')
% 
% Warning: A
% 2 line warning 
% > In warning_error at 54 
%
% Example 3: ignore error and warning
% warning_error('this will not display','errorOFF','verboseOFF')
%
% Created by Justin Theiss 11/2016

% if no inputs, return
if nargin==0, return; end;

% get warning state and set to on
S = warning; back_state = warning('query','backtrace');
warning('on'); warning('backtrace','off');

% check for 'errorON'
if ~any(strcmpi(varargin,'errorON')), % errorOFF (default)
    err = 'errorOFF';
    varargin(strcmpi(varargin,'errorOFF')) = [];
else % errorON
    err = 'errorON';
    varargin(strcmpi(varargin,'errorON')) = [];
end
% check for 'verboseOFF'
if ~any(strcmpi(varargin,'verboseOFF')), % verboseON (default)
    verbose = 'verboseON';
    varargin(strcmpi(varargin,'verboseON')) = [];
else % verboseOFF
    verbose = 'verboseOFF';
    varargin(strcmpi(varargin,'verboseOFF')) = [];
end

% concatenate inputs
string = [];
for i = 1:numel(varargin),
    string = [string,num2str(varargin{i})];
end

% error
if strcmp(err,'errorON'),
    % create MException to be thrown as if from caller
    ME = MException('',sprintf(string));
    throwAsCaller(ME);
% warning
elseif strcmp(verbose,'verboseON')
    % get db stack omitting this function
    stack = dbstack(1); disp({stack.name})
    % interleave names and lines
    name_line = cell(1,numel(stack)*2);
    name_line(1:2:end) = {stack.name};
    name_line(2:2:end) = {stack.line};
    % warning
    backstr = sprintf('In %s at %d\n', name_line{:});
    warning([sprintf([string,'\n\n']),backstr]);
end

% reset warning state
warning(S); warning(back_state);
return;
    