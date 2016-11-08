function warning_error(varargin)
% warning_error(...)
% Display warning or error with inputs.
%
% Inputs:
% string or number inputs to be concatenated (can include special chars)
% 'forceError': throw an error with string message (default 'noError')
% 'verboseOFF': do not throw warning (default 'verboseON')
%
% Example 1: throw an error to stop function
% warning_error('This is the ',2,'nd error!','forceError')
% 
% Error using warning_error (line 37)
% This is the 2nd error!
%
% Example 2: throw a multiline warning without error
% warning_error('A \n ',2,' line warning','noError')
% 
% Warning: A
% 2 line warning 
% > In warning_error at 54 
%
% Example 3: ignore error and warning
% warning_error('this will not display','noError','verboseOFF')
%
% Created by Justin Theiss 11/2016

% if no inputs, return
if nargin==0, return; end;

% get warning state and set to on
S = warning;
warning('on');

% check for 'forceError'
if ~any(strcmpi(varargin,'forceError')), % noError (default)
    err = 'noError';
    varargin(strcmpi(varargin,'noError')) = [];
else % forceError
    err = 'forceError';
    varargin(strcmpi(varargin,'forceError')) = [];
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
if strcmp(err,'forceError'),
    error(sprintf(string));
% warning
elseif strcmp(verbose,'verboseON'),
    warning(sprintf(string));
end

% reset warning state
warning(S);
return;
    