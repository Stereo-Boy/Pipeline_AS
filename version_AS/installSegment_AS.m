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
function installSegment_AS
disp('You should be in the 06_mrVista_session folder for the subject that you are analyzing.');
beep; pause
%check that directory is correct
[a,theFolder]=fileparts(pwd);
if strcmpi(theFolder,'06_mrVista_session')==0; error('You are not in the mrVista session folder...'); end

disp('---------------   Segmentation installation     ---------------')
mrVista;

% user-defined parameters:
query = 0;
keepAllNodes = 0;
sessionPath = cd;
niftiFixFolder = [sessionPath, '/Segmentation_niftiFixed'];
cd(niftiFixFolder)
classificationPath = {[niftiFixFolder,'/t1_class_edited.nii.gz']}; %path from working directory to the classification file
numGrayLayers = 3;

disp('Check the following user-defined parameters before proceeding')
disp('query'); disp(query);
disp('keepAllNodes'); disp(keepAllNodes);
disp('classificationPath'); disp(classificationPath);
disp('numGrayLayers'); disp(numGrayLayers);
disp('Press a key')
pause
cd(sessionPath)
% install segmentation
vw = initHiddenInplane;
disp('Installing Segmentation...')
installSegmentation(query, keepAllNodes, classificationPath, numGrayLayers)

% check segmentation
vo = open3ViewWindow('gray');
disp('Done')

disp(' ----------------- INSTALLATION FINISHED -----------------------')

