function varargout = loop_feval(varargin)
% output = loop_feval(...)
% Loop feval calls based on max number of arguments
% 
% Inputs:
% function: cellstring function(s) to be called
% options: cellstring option(s) to be included
% 'verboseOFF': prevent output display (default is 'verboseON')
% 
% Outputs:
% output: variable number of outputs based on user with each row
% corresponding to a function call
%
% Example:
%
% Created by Justin Theiss 11/2016

% init varargout
varargout = cell(size(nargout));
if nargin==0, return; end;

% set vout_n
vout_n = max(nargout, 1);

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
n = max(cellfun(@(x)size(x,1),varargin));

% get funcs 
funcs = varargin{1};
varargin(1) = [];
funcs = funcs(:);

% prepare funcs
for x = 1:numel(funcs), 
    if isa(funcs{x},'function_handle'), 
        funcs{x} = func2str(funcs{x}); 
    end
end
funcs = cat(1, funcs, repmat(funcs(end), n-numel(funcs), 1));

% prepare options
options = num2cell(nan(n, numel(varargin)));
for x = 1:numel(varargin), options(:, x) = varargin{x}; end;

% feval loop  
for f = 1:n, 
    % set output cell
    output = cell(1, vout_n);
    % allowable output number
    fout_n = nargout(funcs{f}); 
    if fout_n < 0, fout_n = nargout; end;
    % display inputs
    dispi('\n',funcs{f},'\ninputs:',verbose);
    cellfun(@(x)dispi(x, verbose), options(f,~cellfun('isempty',options(f,:))));
    dispi('',verbose);
    % run feval
    [output{1:min(vout_n,fout_n)}] = feval(funcs{f}, options{f,~cellfun('isempty',options(f,:))}); 
    % display result
    dispi('\noutputs:',verbose);
    cellfun(@(x)dispi(x, verbose), output);
    % set to varargout
    varargout = cellfun(@(x,y){cat(1,x,{y})}, varargout, output);
end
end
