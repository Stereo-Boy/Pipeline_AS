function tabl = motion_outliers(mc_dir,expr,varargin)
% tabl = motion_outliers(mc_dir,exrp,...,['verboseOFF'])
% Create table with files, number of outlying TRs, and indices of TRs
% 
% Inputs: 
% mc_dir: string directory containing motion correction files (default is pwd)
% expr: string expression to find files (default is 'epi*.nii*')
% other parameters to input to fsl_motion_outliers (see documentation)
% 'verboseOFF': prevent display in command window (default 'verboseON')
%
% Outputs:
% tabl: cell array of columns of nifti file name, number of outliers, and
% outlier TRs
% saved files: file_confound file that contains regressors to remove
% outliers in model
%
% Example:
% tabl = check_motion(pwd,'epi*.nii.gz','verboseOFF')
%
% tabl = 
% 
%     'Users/epi01_retino_12.nii.gz'    [13]    [1x13 double]
%     'Users/epi02_retino_13.nii.gz'    [ 6]    [1x6 double] 
%     'Users/epi03_retino_14.nii.gz'    [ 4]    [1x4 double]         
%     'Users/epi04_retino_15.nii.gz'    [ 7]    [1x7 double]
%     'Users/epi05_retino_16.nii.gz'    [ 7]    [1x7 double] 
%     'Users/epi06_retino_17.nii.gz'    [ 8]    [1x8 double]
% 
% Note: A *_confound file is only created for those files that have
% outliers.
% Created by Justin Theiss 11/2016

% init vars
if ~exist('mc_dir','var')||isempty(mc_dir), mc_dir = pwd; end;
if ~exist('expr','var')||isempty(expr), expr = 'epi*.nii*'; end;
if any(strncmp(varargin,'verbose',7)),
    verbose = varargin{strncmp(varargin,'verbose',7)};
else % default on
    verbose = 'verboseON';
end

% get epi*.nii* files
d = dir(fullfile(mc_dir,expr));
files = fullfile(mc_dir,{d.name});

% create the filenames for output confounds
confiles = fullfile(mc_dir,strrep({d.name},'.nii.gz','_confound'));
[~,convars] = cellfun(@(x)fileparts(x),confiles,'UniformOutput',0);

% run fsl_motion_outliers for each file
loop_system('fsl_motion_outliers','-i',files,'-o',confiles,varargin{:},verbose);

% create table of outliers
for x = 1:numel(confiles),
    % set first column to files
    tabl{x,1} = files{x};
    % check confile exists, if not skip
    if ~check_exist(fileparts(confiles{x}),convars{x},1,verbose), 
        continue; 
    end;
    % load confile
    load(confiles{x});
    % set number of outliers
    tabl{x,2} = size(eval(convars{x}),2);
    % set indices of outliers
    tabl{x,3} = find(sum(eval(convars{x}),2))';
end