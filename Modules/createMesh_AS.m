% initially kb_macCreateMesh.m
% 
% Kelly Byrne | Silver Lab | UC Berkeley | 2015-09-28
% modified from code written by the VISTA lab and available at: http://web.stanford.edu/group/vista/cgi-bin/wiki/index.php/Mesh#Creating_a_mesh
%
% builds and saves a smoothed and inflated mesh for each hemispheres
%
% required input: user-defined parameters
% desired output: lh_pial.mat, rh_pial.mat, lh_inflated.mat rh_inflated.mat
% ________________________________________________________________________________________________
clear all

disp('You should be in the 06_mrVista_session folder for the subject that you are analyzing.');
beep; pause
%check that directory is correct
[a,theFolder]=fileparts(pwd);
if strcmpi(theFolder,'06_mrVista_session')==0; error('You are not in the mrVista session folder...'); end

% user-defined parameters:
sessPath = cd;
%[projHome, subj]=fileparts(projHome);

% open a connection to the mesh server
% GUI will appear asking to allow incoming connections, this is OK - allow it!
% to stop the GUI from appearing, add a signature to the mrMeshMac application and server executable
% see the website below (specifically answers 2 & 3) for helpful information about this process 
% http://apple.stackexchange.com/questions/3271/how-to-get-rid-of-firewall-accept-incoming-connections-dialog
mkdir('Mesh')
close all;
mrmStart(1,'localhost');

% build and inflate left hemisphere mesh
% 4 GUIs will appear - the first is the build parameters, you can accept the default values. the second should ask for 
% confirmation that the appropriate class file was found. the third will ask you to save the pial surface for the
% hemisphere you're working on, our naming convention is lh_pial for the left hemisphere (should be saved in mesh
% directory). the fourth asks for smoothing parameters - try 600 iterations
open3ViewWindow('gray')
VOLUME{1} = meshBuild(VOLUME{1}, 'left');  
MSH = meshVisualize( viewGet(VOLUME{1}, 'Mesh') );  
VOLUME{1} = viewSet( VOLUME{1}, 'Mesh', meshSmooth( viewGet(VOLUME{1}, 'Mesh'),1) ); 
MSH = meshColor(MSH);
MSH = meshVisualize( viewGet(VOLUME{1}, 'Mesh') );
filename=fullfile(sessPath, '/Mesh/lh_inflated.mat');
verbose=1;
mrmWriteMeshFile(MSH, filename, verbose)

% build and inflate right hemisphere mesh
% 4 GUIs will appear - the first is the build parameters, you can accept the default values. the second should ask for 
% confirmation that the appropriate class file was found. the third will ask you to save the pial surface for the
% hemisphere you're working on, our naming convention is rh_pial for the right hemisphere (should be saved in mesh
% directory). the fourth asks for smoothing parameters - try 600 iterations
open3ViewWindow('gray')
VOLUME{2} = meshBuild(VOLUME{2}, 'right');  MSH = meshVisualize( viewGet(VOLUME{2}, 'Mesh') );  
VOLUME{2} = viewSet( VOLUME{2}, 'Mesh', meshSmooth( viewGet(VOLUME{2}, 'Mesh'),1) )
MSH = meshColor(MSH);
MSH = meshVisualize( viewGet(VOLUME{2}, 'Mesh') );
filename=fullfile(sessPath, '/Mesh/rh_inflated.mat')
mrmWriteMeshFile(MSH, filename, verbose)

% close windows and connection to the mesh server
close all;
mrmCloseWindow(1001,'localhost');
mrmCloseWindow(1003,'localhost');
mrmCloseWindow(1005,'localhost');
mrmCloseWindow(1007,'localhost');
unix('kb_mrmClose.sh');