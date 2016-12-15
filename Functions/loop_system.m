function [status, result] = loop_system(varargin)
% [status, result] = loop_system(...)
% Loop system calls based on max number of arguments
%
% Inputs:
% function: cellstring function(s) to be called
% options: cellstring option(s) to be included
%
% Outputs:
% status: cell array of statuses based on each system output
% result: cell array of results based on each system output
%
% Example:
% [status, result] = loop_system('echo',{1;'this'},'verboseON')
% echo 1
% 1
% 
% echo this
% this
%
% status = 
% 
%     [0]    [0]
% 
% 
% result = 
% 
%     [1x2 char]    [1x5 char]
%     
% Created by Justin Theiss 11/2016

status = {}; result = {};
if nargin==0, return; end;

% get verbose
if any(strncmp(varargin,'verbose',7)),
    verbose = varargin{strncmp(varargin,'verbose',7)};
    varargin(strcmp(varargin,verbose)) = [];
else % default on
    verbose = 'verboseON';
end

% find non-cell varargins
noncells = ~cellfun('isclass',varargin,'cell');
varargin(noncells) = num2cell(varargin(noncells));

% get max size of varargin
n = max(cellfun(@(x)numel(x),varargin));

% for each varargin, preprare for system call
for x = 1:numel(varargin),
    % ensure each varargin is vertically oriented
    if size(varargin{x},2) > 1,
        varargin{x} = varargin{x}';
    end
    % prepare each varargin for system call
    varargin{x} = cellfun(@(x){setup_arg(x)},varargin{x});
    % repmat last item to appropriate number
    varargin{x} = cat(1,varargin{x},repmat(varargin{x}(end),n - numel(varargin{x}),1));
end

% concatenate across columns
varargin = cat(2,varargin{:});
options = cell(1,n);
for x = 1:n,
    options{x} = sprintf('%s ',varargin{x,:});
    options{x}(end) = [];
end

% system call loop
for f = 1:n,
    dispi(options{f}, verbose);
    [status{f},result{f}] = system(options{f});
    dispi(result{f}, verbose);
end;
end

function arg = setup_arg(arg)
% setup arguments for system call

% set number to string
if ~ischar(arg),
    arg = num2str(arg);
end
% if file/dir, set ""
if ~isempty(fileparts(arg)),
    arg = ['"' arg '"'];
end
end
