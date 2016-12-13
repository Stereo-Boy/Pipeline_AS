function create_mesh(mesh_dir, iter_n, gray_n, verbose)
% create_mesh(mesh_dir, iter_n, verbose)
% Builds and saves a smoothed and inflated mesh for each hemispheres
%
% Inputs:
% mesh_dir - string directory for mesh folder (default is pwd)
% iter_n - number of iterations of smoothing iterations for unfolding
% (default 600 iterations)
% gray_n - number of gray layers
% verbose - 'verboseOFF' to prevent displays (default is 'verboseON')
%
% Outputs:
% files saved: lh_pial.mat, rh_pial.mat, lh_inflated.mat rh_inflated.mat
% 
% Kelly Byrne | Silver Lab | UC Berkeley | 2015-09-28
% modified from code written by the VISTA lab and available at: http://web.stanford.edu/group/vista/cgi-bin/wiki/index.php/Mesh#Creating_a_mesh
% modified for JAS pipeline nov 2016 (Adrien Chopin)

% init vars
if ~exist('mesh_dir','var')||isempty(mesh_dir), mesh_dir = pwd; end;
if ~exist('iter_n','var')||isempty(iter_n), iter_n = 600; end;
if ~exist('verbose','var')||~strcmp(verbose,'verboseOFF'), verbose = 'verboseON'; end

% display function and inputs
dispi(mfilename,'\nmesh_dir:\n',mesh_dir,'\niter_n:\n',iter_n,'\ngray_n:\n',gray_n,verbose);

% open a connection to the mesh server
% GUI will appear asking to allow incoming connections, this is OK - allow it!
% to stop the GUI from appearing, add a signature to the mrMeshMac application and server executable
% see the website below (specifically answers 2 & 3) for helpful information about this process 
% http://apple.stackexchange.com/questions/3271/how-to-get-rid-of-firewall-accept-incoming-connections-dialog
dispi('Opening connection to mrm server', verbose);
mrmStart(1,'localhost');

% build and inflate left hemisphere mesh
% 4 GUIs will appear - the first is the build parameters, you can accept the default values. the second should ask for 
% confirmation that the appropriate class file was found. the third will ask you to save the pial surface for the
% hemisphere you're working on, our naming convention is lh_pial for the left hemisphere (should be saved in mesh
% directory): ignore it because we save it from command line after that. the fourth asks for smoothing parameters - default should be our value. 
side = {'left','right'};
hemi = {'lh','rh'};
for x = 1:2,
    % open each side's gray view 
    dispi('Opening ', side{x}, ' hidden gray view', verbose);
    vw = initHiddenGray;
    
    % build mesh
    dispi('Building ', side{x}, ' mesh', verbose);
    vw = meshBuild(vw, side{x}, gray_n); 
    
    % save pial mesh to mesh_dir
    filename = fullfile(mesh_dir,[hemi{x},'_pial.mat']);
    msh = viewGet(vw, 'Mesh');
    msh = meshSet(msh,'path',fileparts(filename));
    msh = meshSet(msh,'filename',filename);
    save(filename, 'msh');
    dispi('Saving unfolded mesh in %s\n', filename, verbose);
    
    % inflate and smooth left mesh
    dispi('Inflating/smoothing ',side{x},' mesh with ', iter_n, ' iterations ', verbose);
    msh = viewGet(vw, 'Mesh');
    msh = meshSet(msh,'smooth_iterations',iter_n);
    vw = viewSet(vw, 'Mesh', meshSmooth(msh,0));
    dispi('Coloring ',side{x},' mesh', verbose);
    msh = meshVisualize(viewGet(vw, 'Mesh'));
    msh = meshColor(msh);
    
    % save unfolded mesh to mesh_dir
    filename = fullfile(mesh_dir,[hemi{x},'_inflated.mat']);
    dispi('Saving unfolded ', side{x}, ' mesh', verbose);
    msh = meshSet(msh,'path',fileparts(filename));
    msh = meshSet(msh,'filename',filename);
    save(filename, 'msh');
    dispi('Saving unfolded mesh in %s\n', filename, verbose);
end

% close windows and connection to the mesh server
dispi('Closing all windows and connections to the mesh server',verbose);
close all;
mrmCloseWindow(1001,'localhost');
mrmCloseWindow(1003,'localhost');
mrmCloseWindow(1005,'localhost');
mrmCloseWindow(1007,'localhost');
system('kb_mrmClose.sh');
end