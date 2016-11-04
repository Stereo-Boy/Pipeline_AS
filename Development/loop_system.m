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
% Created by Justin Theiss 11/2016

status = {}; result = {};
if nargin==0, return; end;

% find non-cell varargins
noncells = ~cellfun('isclass',varargin,'cell'); 
varargin(noncells) = num2cell(varargin(noncells));

% get max size of varargin
n = max(cellfun(@(x)numel(x),varargin));

% for each varargin, preprare for system call
for x = 1:nargin,
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
for f = 1:n, [status{f},result{f}] =system(options{f}); end;
return;

function arg = setup_arg(arg)
% setup arguments for system call

% set number to string
if ~ischar(arg), 
    arg = num2str(arg);
end
% if file//dir, set ""
if exist(arg, 'file')||exist(arg, 'dir'),
    arg = ['"' arg '"'];
end
return;