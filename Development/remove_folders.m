function [success, status] = remove_folders(varargin)
% [success, status] = remove_folders(folder(s), ['s'], ['verboseOFF'], ['errorON'])
%
% Checking whether each folder exists (from a previous instance) and removes it.
%
% Inputs:
% folder: string/cell array of strings corresponding to the folders to
% remove
% s: remove all subdirectories of folder (as in call rmdir(fld,'s'),
% default is none)
% verbose: 'verboseOFF' to prevent output displays (default is 'verboseON')
% err: 'errorON' to throw error if unable to remove a found folder (default
% is 'errorOFF')
% 
% Outputs:
% success: cell array of 1/0 for success/failure of removing existing
% folders
% status: cell array of status from each rmdir call
%
% Example: make 2 test folders, and attempt to remove 3
% flds = fullfile(pwd, {'test1', 'test2', 'test3'});
% mkdir(flds{1}); mkdir(flds{3});
% [success, status] = remove_previous(fullfile(pwd,{'test1','test2','test3'}),'s','errorON')
%
% /Users/test1 detected and removed
% /Users/test2 not detected
% /Users/test3 detected and removed
% 
% success = 
% 
%     [1]    []    [1]
% 
% 
% status = 
% 
%     ''    []    ''
%
% Written Nov 2016
% Adrien Chopin

% init vars
if any(strncmp(varargin,'verbose',7)), 
    verbose = varargin(strncmp(varargin,'verbose',7));
    varargin(strcmp(varargin,verbose)) = [];
else % default on
    verbose = 'verboseON';
end
if any(strncmp(varargin,'error',5)),
    err = varargin(strncmp(varargin,'error',5));
    varargin(strcmp(varargin,err)) = [];
else % default off
    err = 'errorOFF';
end
% init outputs
success = cell(size(varargin)); status = cell(size(varargin));
% set folders or return
if isempty(varargin), 
    return;
else % set to folder(s)
    folder = varargin;
end;
if ~iscell(folder), folder = {folder}; end;
% set s
if numel(varargin)==2,
    s = varargin{2};
else % default none
    s = '';
end

% if folder exists, remove
for x = 1:numel(folder),
    if exist(folder{x},'dir')
        if isempty(s), % dont remove subdirectories
            [success{x}, status{x}] = rmdir(folder{x}); 
        else % remove subdirectories
            [success{x}, status{x}] = rmdir(folder{x}, s);
        end
        if success{x}, % display folder removed
            dispi(folder{x}, ' detected and removed', verbose);
        else % warning/error
            warning_error(status{x}, err, verbose); 
        end
    else % display no folder
        dispi(folder{x},' not detected',verbose)
    end
end