function output = get_dir(fld, expr, n)
% output = get_dir(fld, expr, n)
% Get n number of files/folders from fullfile(fld, expr) using dir
%
% Inputs:
% fld: string path to directory to search within (default is pwd)
% expr: string expression to search within fld using dir (default is '').
% if expr ends with a file separator (i.e. '/' or '\'), only directories 
% will be returned.
% n: number index of files/folders to return (default is [], all). if n is
% a single number, output will be a string rather than cellstr
%
% Outputs:
% output: cell array of fullpath files/folders returned from call to dir 
%
% Example:
% save('test.txt'); save('test2.txt'); mkdir('testfld');
% output = get_dir(pwd, 'test*.txt', 1)
% 
% output = 
% 
% /Users/test.txt
% 
% output = get_dir(pwd, 'test*.txt', 2)
% 
% output = 
% 
% /Users/test2.txt
% 
% output = get_dir(pwd, 'test*.txt', 1:2)
%
% output = 
% 
%     '/Users/test.txt'    '/Users/text2.txt'
% 
% output = get_dir(pwd, 'test*/')
%
% output = 
%
%     '/Users/testfld'
%     
% Note: get_dir automatically removes '.', '..', and '~' files/directories.
%
% Created by Justin Theiss 11/2016

% init vars
if ~exist('fld','var')||isempty(fld), fld = pwd; end;
if ~exist('expr','var')||isempty(expr), expr = ''; end;
if ~exist('n','var')||isempty(n), n = []; end;

% get dir of fld/expr
d = dir(fullfile(fld, expr));

% if expr ends with file sep, only return isdir
if strcmp(expr(end),filesep),
    d = d([d.isdir]);
end

% remove ., .., ~ files
d = d(~strncmp({d.name},'.',1));
d = d(~strncmp({d.name},'~',1));

% set to output
output = fullfile(fld, {d.name});

% output number of files/folders
if ~isempty(n), output = output(n); end;
if numel(n)==1, output = output{1}; end;