function close_mesh_server(verbose)
% close windows and connection to the mesh server
% written in 2016,Adrien Chopin

if ~exist('verbose','var'), verbose='verboseON'; end
dispi('Closing all windows and connections to the mesh server',verbose)

mrmCloseWindow(1001,'localhost');
mrmCloseWindow(1003,'localhost');
mrmCloseWindow(1005,'localhost');
mrmCloseWindow(1007,'localhost');
unix('kb_mrmClose.sh');