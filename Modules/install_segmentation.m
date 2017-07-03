function install_segmentation(mr_dir, seg_dir, ni_dir, verbose)
% install_segmentation(mr_dir, seg_dir, ni_dir, verbose)
% Installs volume anatomy and an existing cortical segmentation into an existing mrSESSION
%
% Inputs:
% mr_dir - string path of mrVista session folder
% seg_dir - string path of directory containing t1_class edited files
% ni_dir - string path of directory to move t1_class edited files
%
% Outputs:
% opens gray mrvista window (if installation fails, window will not open)
%
% Note: To avoid errors, all paths should be fullfile
%
% Adrien Chopin - 2015
% Adapted from kb_installSeg.m
% Kelly Byrne | Silver Lab | UC Berkeley | 2015-09-27 
% modified from code written by the Winawer lab and available at: https://wikis.nyu.edu/display/winawerlab/Install+segmentation
%
% requires the VISTA Lab's Vistasoft package - available at: https://github.com/vistalab/vistasoft

% init vars
if ~exist('mr_dir','var')||isempty(mr_dir), mr_dir = pwd; dispi('empty mr_dri in install_segmentation defaulted to ', mr_dir); end;
if ~exist('seg_dir','var')||isempty(seg_dir), seg_dir = fullfile(pwd,'Segmentation'); dispi('empty seg_dir in install_segmentation defaulted to ', seg_dir); end;
if ~exist('ni_dir','var')||isempty(ni_dir), ni_dir = fullfile(pwd,'nifti'); dispi('empty ni_dir in install_segmentation defaulted to ', ni_dir);end;
initialDir = pwd;

% check for mr_dir
check_folder(mr_dir, 1, verbose);

% run mrVista
cd(mr_dir);
%mrVista;

% user-defined parameters:
query = []; %should trigger volume, gray or flat coords calculation if missing
keepAllNodes = 1; %for more flexibility
check_exist(seg_dir, '*t1_class*edited*', 1, 'errorON', verbose);
dispi('Copying ',fullfile(seg_dir,'*t1_class*edited*'),' to ',ni_dir,verbose);
copyfile(fullfile(seg_dir, '*t1_class*edited*'), ni_dir);
seg_file = get_dir(ni_dir, '*t1_class*edited*', 1);
% needs following structure: left class, right class, empty gray left, empty right gray 
segFilePaths = {seg_file, seg_file, '', ''};
numGrayLayers = 3;

% display parameters
dispi('Please check the following user-defined parameters:', verbose);
dispi('query: ', query, verbose);
dispi('keepAllNodes: ', keepAllNodes, verbose);
dispi('classificationPath: ', segFilePaths, verbose);
dispi('Having a list with two files and two empty string is normal', verbose)
dispi('numGrayLayers: ', numGrayLayers, verbose);

% install segmentation
initHiddenInplane;
dispi('Installing Segmentation...',verbose);
installSegmentation(query, keepAllNodes, segFilePaths, numGrayLayers);

% check segmentation
open3ViewWindow('gray');
cd(initialDir);
end