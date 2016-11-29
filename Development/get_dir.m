function output = get_dir(fld, expr, n)
% output = get_dir(fld, expr, n)
% Get n number of files/folders from fullfile(fld, expr) using dir
%
% Inputs:
% fld: string path to directory to search within (default is pwd)
% expr: string expression to search within fld using dir (default is '')
% n: number index of files/folders to return (default is [], all)
%
% Outputs:
% output: cell array of fullpath files/folders returned from call to dir 
%
% Example:
% save('test.txt'); save('test2.txt');
% output = get_dir(pwd, 'test*.txt', 1)
% 
% output = 
% 
%     '/Users/test.txt'
% 
% output = get_dir(pwd, 'test*.txt', 2)
% 
% output = 
% 
%     '/Users/test2.txt'
% 
% output = get_dir(pwd, 'test*.txt', 1:2)
%
% output = 
% 
%     '/Users/test.txt'    '/Users/text2.txt'
%     
% Created by Justin Theiss 11/2016

% init vars
if ~exist('fld','var')||isempty(fld), fld = pwd; end;
if ~exist('expr','var')||isempty(expr), expr = ''; end;
if ~exist('n','var')||isempty(n), n = []; end;

% get dir of fld/expr
d = dir(fullfile(fld, expr));
output = fullfile(fld, {d.name});

% output number of files/folders
if ~isempty(n), output = output(n); end;