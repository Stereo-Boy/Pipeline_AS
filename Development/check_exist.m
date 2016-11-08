function [tf, n] = check_exist(varargin)
% [tf, n] = check_exist(folder, expr, n, 'verboseOFF', 'errorON')
% Check if file/folder exists or has number of files equal to n.
% Furthermore, if folder does not exist, create folder.
%
% Optional Inputs:
% folder: folder to check if exists (or contains files)
% expr: expression to search for files (e.g., 'epi*.nii*')
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

% switch number of inputs
if numel(varargin) == 1, % directory
    tf = isdir(varargin{1}); 
    n = double(tf);
    result = sprintf('%s\nfound: %d',varargin{1},n);
    
elseif numel(varargin) <= 3, % files/number comparison
    % if isdir, set varargin{2} with *
    if isdir(fullfile(varargin{1:2})),
        varargin{2} = [varargin{2} '*'];
    end
    
    % dir for expression
    d = dir(fullfile(varargin{1:2}));
    n = sum(~[d.isdir]); % remove dirs
    
    % if 2 args, compare with 0
    if numel(varargin) == 2,
        tf = n > 0;
        result = sprintf('%s\nfiles found: %d',fullfile(varargin{1:2}),n);
    else % 3 args, compare with varargin{3}
        tf = n == varargin{3};
        result = sprintf('%s\nfiles found: %d, expected: %d',fullfile(varargin{1:2}),n,varargin{3});
    end
    
else % unknown inputs
    warning_error('Unknown inputs',verbose,err);
    return;
end

% display warning/error if false
if ~tf,
    % warning/error
    warning_error(result,verbose,err);
    
    % if directory, mkdir
    if numel(varargin) == 1,
        [success,msg] = mkdir(varargin{1});
        if success, % created directory
            n = 1; % set n to 1 now
            dispi(varargin{1},' created',verbose);
        else % failed
            warning_error(varargin{1},' not created: ',msg,verbose,err);
        end
    end
    
else % display true
    dispi(result,verbose);
end
return;
    