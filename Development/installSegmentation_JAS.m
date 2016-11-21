function installSegmentation_JAS(mrVistaFolder, segmentationFolder, niftiFolder, verbose)
% installSegmentation_JAS(mrVistaFolder, segmentationFolder, niftiFolder, verbose)
% mrVistaFolder - the mrVista session folder
% segmentationFolder - the folder containing last t1_class edited files
% niftiFolder - where this files should go in the mrVistaFolder 
% adapted for JAS in 2016
% Adrien Chopin - 2015
% Adapted from kb_installSeg.m
% Kelly Byrne | Silver Lab | UC Berkeley | 2015-09-27 
% modified from code written by the Winawer lab and available at: https://wikis.nyu.edu/display/winawerlab/Install+segmentation
%
% requires the VISTA Lab's Vistasoft package - available at: https://github.com/vistalab/vistasoft
%
% installs volume anatomy and an existing cortical segmentation into an existing mrSESSION
%
% required input: user-defined parameters
% desired output: open gray window (if the installation fails, the window will not open)
% ________________________________________________________________________________________________

disp('Check that given mrVista session folder exists');
check_folder(mrVistaFolder, 1, verbose);
%cd(mrVistaFolder)

mrVista;

% user-defined parameters:
query = []; %should trigger volume, gray or flat coords calculation if missing
keepAllNodes = 1; %for more flexibility
[tf, nbFiles] = check_files(segmentationFolder, '*t1_class*edited*', 1, 1, verbose);
copy_files(segmentationFolder, '*t1_class*edited*', niftiFolder, verbose) %copy all nifti mprage files
segmfile = list_files(niftiFolder, '*t1_class*edited*', 1);
numGrayLayers = 3;

disp('Please check the following user-defined parameters:')
dispi('query: ', query, verbose);
dispi('keepAllNodes: ', keepAllNodes, verbose);
dispi('classificationPath: ', segmfile, verbose);
dispi('numGrayLayers: ', numGrayLayers, verbose);

% install segmentation
vw = initHiddenInplane;
disp('Installing Segmentation...')
installSegmentation(query, keepAllNodes, segmfile, numGrayLayers)

% check segmentation
vo = open3ViewWindow('gray');

disp(' ----------------- INSTALLATION FINISHED -----------------------')

