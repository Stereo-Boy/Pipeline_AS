function [success, status] = remove_dir(varargin)
% [success, status] = remove_dir(folders/files, ['s'], ['verboseOFF'], ['errorON'])
%
% Removes folders/files if they exist.
%
% Inputs:
% folder/file: string/cell array of strings corresponding to the folders/files
% to remove
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
if nargin==0,
    return;
elseif ~ischar(varargin{1}) && ~iscell(varargin{1}),
    return;
end
if any(strncmp(varargin,'verbose',7)), 
    verbose = varargin{strncmp(varargin,'verbose',7)};
    varargin(strcmp(varargin,verbose)) = [];
else % default on
    verbose = 'verboseON';
end
if any(strncmp(varargin,'error',5)),
    err = varargin{strncmp(varargin,'error',5)};
    varargin(strcmp(varargin,err)) = [];
else % default off
    err = 'errorOFF';
end
% set to folder(s)
dirs = varargin{1};
if ~iscell(dirs), dirs = {dirs}; end;
% set s
if numel(varargin)==2,
    s = varargin{2};
else % default none
    s = '';
end
% remove non-char cells
dirs(~cellfun('isclass',dirs,'char')) = [];
% if any wildcards, get dir
wld_idx = find(~cellfun('isempty',strfind(dirs,'*')));
if any(wld_idx),
    for x = wld_idx,
        d = dir(dirs{x});
        dirs = cat(2, dirs, {d.name});
    end
    dirs(wld_idx) = [];
end
% init outputs
success = cell(size(dirs)); status = cell(size(dirs));
% if folder exists, remove
for x = 1:numel(dirs),
    if exist(dirs{x},'dir')
        if isempty(s), % dont remove subdirectories
            [success{x}, status{x}] = rmdir(dirs{x}); 
        else % remove subdirectories
            [success{x}, status{x}] = rmdir(dirs{x}, s);
        end
    elseif exist(dirs{x},'file') % delete file
        try % delete files
            delete(dirs{x});
            success{x} = true;
            status{x} = '';
        catch ME
            success{x} = false;
            status{x} = ME.message;
        end
    end
    if success{x}, % display folder/file removed
            dispi(dirs{x}, ' removed', verbose);
    elseif ~success{x}, % warning/error
        warning_error(status{x}, err, verbose); 
    else % display not detected
        dispi(dirs{x},' not detected',verbose)
    end
end