function [tf, n] = check_exist(varargin)
% [tf, n] = check_exist(folder, expr, n, 'verboseOFF', 'errorON')
% Check if file/folder exists or has number of files equal to n.
% Furthermore, if folder does not exist, create folder.
%
% Optional Inputs:
% folder: folder to check if exists (or contains files)
% expr: expression to search for files (e.g., 'epi*.nii*'), if expr ends
% with a file separator (i.e. '/' or '\'), only directories will be
% compared
% n: number of expected files
%
% Outputs:
% tf: boolean result of check
% n: number of found files
% 
% Example 1: check if 'test' folder exists in pwd, if not create (without warning)
% [tf, n] = check_exist(fullfile(pwd,'test'),'verboseOFF')
%
% tf =
% 
%      0
%  
% n =
% 
%      1
%
% Example 2: check if 'test*.nii' files exist in pwd, if not throw error
% [tf, n] = check_exist(pwd,'test*.nii','errorON')
% 
% Error using warning_error (line 60)
% /Users/justintheiss/Documents/Stereopsis_project/MV40/retino/06_mrVista_session/test*.nii
% files found: 0
% 
% Error in check_exist (line 75)
%     warning_error(result,verbose,err);
%     
% Example 3: assert that 0 'test*.nii' files exist in pwd, if not warn
% [tf, n] = check_exist(pwd,'test*.nii',0,'verboseON')
%
% /Users/test*.nii
% files found: 0, expected: 0
% 
% tf =
% 
%      1
% 
% 
% n =
% 
%      0
%
% Note: file expressions should be specific, i.e. there are hidden files
% that may be included in a comparison (e.g., .DS_Store).
% 
% Created by Justin Theiss 11/2016

% init outputs
tf = false; n = 0;

% if no inputs, return
if nargin==0, return; end;

% get verbose inputs
verbose = varargin(strncmpi(varargin,'verbose',7));
if isempty(verbose), verbose = 'verboseON'; else verbose = verbose{1}; end;
varargin(strcmp(varargin,verbose)) = [];

% get error inputs
err = varargin(strncmpi(varargin,'error',5));
if isempty(err), err = 'errorOFF'; else err = err{1}; end;
varargin(strcmp(varargin,err)) = [];

% if all varargins empty after error/verbose, return
if all(cellfun('isempty',varargin)), return; end;

% for each varargin, switch type
for i = 1:numel(varargin),
    % if numeric, set to ck
    if isnumeric(varargin{i}),
        ck = varargin{i};
    % fld doesnt exist, set to fld
    elseif ~exist('fld','var'), 
        fld = varargin{i};
    else % otherwise set to expr
        expr = varargin{i};
    end
end

% init unset vars
if ~exist('fld','var'), fld = ''; end;
if ~exist('expr','var'), expr = ''; end;
if ~exist('ck','var'), ck = ''; end;

% dir files
d = dir(fullfile(fld,expr));

% if expr ends with file sep or fld contains *, directories
if any(strfind(fld,'*'))||(~isempty(expr)&&strcmp(expr(end),filesep)),
    d = d([d.isdir]);
    ftype = 'folders';
elseif ~isempty(fld) && ~isempty(ck), % files/folders
    d = d(~[d.isdir]);
    ftype = 'files';
else % check isdir(fld)
    d = ones(isdir(fld));
    ftype = 'folder';
end

% get number of files/folders
n = numel(d);

% if checking number
if ~isempty(ck),
    tf = n == ck;
else % check for > 0
    tf = n > 0;
end

% set result
result = sprintf('%s\n%s found: %d, expected: %d',fullfile(fld,expr),ftype,n,ck);

% if false, warn/error
if ~tf,
    % display warning/error
    warning_error(result, verbose, err);
    % if directory does not exist, mkdir 
    if ~isempty(fld) && isempty(expr) && isempty(ck),
        [success,msg] = mkdir(fld);
        if success, % created directory
            n = 1; % set n to 1 now
            dispi(fld,' created',verbose);
        else % failed
            warning_error(fld,' not created: ', msg, verbose, err);
        end
    end
else % display result
    dispi(result, verbose);
end
return;