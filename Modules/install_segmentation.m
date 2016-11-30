function install_segmentation(mr_dir, seg_dir, ni_dir, verbose)
% install_segmentation(mrVistaFolder, segmentationFolder, niftiFolder, verbose)
% Installs volume anatomy and an existing cortical segmentation into an existing mrSESSION
%
% Inputs:
% mr_dir - mrVista session folder
% seg_dir - the folder containing last t1_class edited files
% ni_dir - where this files should go in the mrVistaFolder 
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
if ~exist('mr_dir','var')||isempty(mr_dir), mr_dir = pwd; end;
if ~exist('seg_dir','var')||isempty(seg_dir), seg_dir = fullfile(pwd,'Segmentation'); end;
if ~exist('ni_dir','var')||isemtpy(ni_dir), ni_dir = fullfile(pwd,'nifti'); end;
initialDir = pwd;

% check for mr_dir
check_exist(mr_dir, 1, verbose);

% run mrVista
cd(mr_dir);
mrVista;

% user-defined parameters:
query = []; %should trigger volume, gray or flat coords calculation if missing
keepAllNodes = 1; %for more flexibility
check_exist(seg_dir, '*t1_class*edited*', 1, 'errorON', verbose);
dispi('Copying ',fullfile(seg_dir,'*t1_class*edited*'),' to ',ni_dir,verbose);
copyfile(fullfile(seg_dir, '*t1_class*edited*'), ni_dir);
seg_file = get_dir(ni_dir, '*t1_class*edited*', 1);
numGrayLayers = 3;

% display parameters
dispi('Please check the following user-defined parameters:', verbose);
dispi('query: ', query, verbose);
dispi('keepAllNodes: ', keepAllNodes, verbose);
dispi('classificationPath: ', seg_file, verbose);
dispi('numGrayLayers: ', numGrayLayers, verbose);

% install segmentation
initHiddenInplane;
dispi('Installing Segmentation...',verbose);
installSegmentation(query, keepAllNodes, seg_file, numGrayLayers);

% check segmentation
open3ViewWindow('gray');
cd(initialDir);
end

