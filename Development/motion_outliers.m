function tabl = motion_outliers(mc_dir,varargin)
% tabl = motion_outliers(mc_dir,...)
% Create table with files, number of outlying TRs, and indices of TRs
% 
% Inputs: 
% mc_dir: string directory containing motion correction files
% other parameters to input to fsl_motion_outliers (see documentation)
%
% Outputs:
% tabl: cell array of columns of file name, number of outliers, and indices
% saved files: file_confound file that contains regressors to remove
% outliers in model
%
% Example:
% tabl = check_motion(pwd)
%
% tabl = 
% 
%     'epi01_retino_12_conf...'    [13]    '52, 53, 55, 68, 69, ...'
%     'epi02_retino_13_conf...'    [ 6]    '3, 68, 69, 85, 91, 126' 
%     'epi03_retino_14_conf...'    [ 4]    '67, 68, 69, 85'         
%     'epi04_retino_15_conf...'    [ 7]    '18, 36, 37, 68, 69, ...'
%     'epi05_retino_16_conf...'    [ 7]    '5, 29, 30, 68, 69, 9...'
%     'epi06_retino_17_conf...'    [ 8]    '2, 3, 21, 40, 68, 69...'
% 
% Created by Justin Theiss 11/2016

% get epi*.nii* files
d = dir(fullfile(mc_dir,'epi*.nii*'));
files = fullfile(mc_dir,{d.name});

% create the filenames for output confounds
confiles = fullfile(mc_dir,strrep({d.name},'.nii.gz','_confound'));
[~,convars] = cellfun(@(x)fileparts(x),confiles,'UniformOutput',0);

% run fsl_motion_outliers for each file
loop_system('fsl_motion_outliers','-i',files,'-o',confiles,varargin{:});

% create table of outliers
for x = 1:numel(confiles),
    tabl{x,1} = convars{x};
    % load confile
    load(confiles{x});
    % set number of outliers
    tabl{x,2} = size(eval(convars{x}),2);
    % set indices of outliers
    idx = find(sum(eval(convars{x}),2))';
    idx = sprintf('%d, ',idx);
    tabl{x,3} = idx(1:end-2);
end