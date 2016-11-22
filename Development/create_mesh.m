function create_mesh(meshFolder, nbOfIterations, verbose)
% initially kb_macCreateMesh.m
% required input: the Mesh folder inside mrVistaFolder, where the session is hosted
%                 nbOfIterations being the number of smoothing iterations
%                 for unfolding
% desired output: lh_pial.mat, rh_pial.mat, lh_inflated.mat rh_inflated.mat
% mrVistaFolder
% Kelly Byrne | Silver Lab | UC Berkeley | 2015-09-28
% modified from code written by the VISTA lab and available at: http://web.stanford.edu/group/vista/cgi-bin/wiki/index.php/Mesh#Creating_a_mesh
% modified again to work with JAS in nov 2016 (Adrien Chopin
% builds and saves a smoothed and inflated mesh for each hemispheres
% ____________________________________________________________________________________


% open a connection to the mesh server
% GUI will appear asking to allow incoming connections, this is OK - allow it!
% to stop the GUI from appearing, add a signature to the mrMeshMac application and server executable
% see the website below (specifically answers 2 & 3) for helpful information about this process 
% http://apple.stackexchange.com/questions/3271/how-to-get-rid-of-firewall-accept-incoming-connections-dialog


dispi('Opening connection to mrm server', verbose)
mrmStart(1,'localhost');


% build and inflate left hemisphere mesh
% 4 GUIs will appear - the first is the build parameters, you can accept the default values. the second should ask for 
% confirmation that the appropriate class file was found. the third will ask you to save the pial surface for the
% hemisphere you're working on, our naming convention is lh_pial for the left hemisphere (should be saved in mesh
% directory). the fourth asks for smoothing parameters - try 600 iterations

dispi('Opening hidden gray view', verbose)
vw=initHiddenGray;
dispi('Still using GUI for mesh input parameters: PLEASE ACCEPT ALL DEFAULT - CANCEL GUIs for SAVING files', verbose)
dispi('Building left mesh', verbose)
vw = meshBuild(vw, 'left');  MSH = meshVisualize( viewGet(vw, 'Mesh') );  
filename=fullfile(meshFolder,'lh_pial.mat');
mrmWriteMeshFile(viewGet(vw, 'Mesh'), filename, 1) %last parameter is verbose

dispi('Inflating/smoothing left mesh with ', nbOfIterations, ' iterations ', verbose)
msh = viewGet(vw, 'Mesh');
msh = meshSet(msh,'smooth_iterations',nbOfIterations);
vw = viewSet( vw, 'Mesh', meshSmooth(msh,0) );
dispi('Coloring left mesh', verbose)
MSH = meshVisualize( viewGet(vw, 'Mesh') );
MSH = meshColor(MSH);
filename=fullfile(meshFolder,'lh_inflated.mat');
dispi('Saving unfolded left mesh', verbose)
mrmWriteMeshFile(MSH, filename, 1) %last parameter is verbose

% build and inflate right hemisphere mesh
% 4 GUIs will appear - the first is the build parameters, you can accept the default values. the second should ask for 
% confirmation that the appropriate class file was found. the third will ask you to save the pial surface for the
% hemisphere you're working on, our naming convention is rh_pial for the right hemisphere (should be saved in mesh
% directory). the fourth asks for smoothing parameters - try 600 iterations
dispi('Opening hidden gray view', verbose)
vw2=initHiddenGray;
dispi('Building right mesh', verbose)
vw2 = meshBuild(vw2, 'right');  MSH2 = meshVisualize( viewGet(vw2, 'Mesh') );  
filename2=fullfile(meshFolder,'rh_pial.mat');
mrmWriteMeshFile(viewGet(vw2, 'Mesh'), filename2, 1) %last parameter is verbose

dispi('Inflating/smoothing right mesh with ', nbOfIterations, ' iterations ', verbose)
msh2 = viewGet(vw2, 'Mesh');
msh2 = meshSet(msh2,'smooth_iterations',nbOfIterations);
vw2 = viewSet( vw2, 'Mesh', meshSmooth(msh2,0) );
dispi('Coloring right mesh', verbose)
MSH2 = meshVisualize( viewGet(vw2, 'Mesh') );
MSH2 = meshColor(MSH2);
dispi('Visualizing right mesh', verbose)
filename2=fullfile(meshFolder, 'rh_inflated.mat');
dispi('Saving unfolded right mesh', verbose)
mrmWriteMeshFile(MSH2, filename2, 1) %last parameter is verbose

% close windows and connection to the mesh server
dispi('Closing all windows and connections to the mesh server',verbose)
close all;
mrmCloseWindow(1001,'localhost');
mrmCloseWindow(1003,'localhost');
mrmCloseWindow(1005,'localhost');
mrmCloseWindow(1007,'localhost');
unix('kb_mrmClose.sh');