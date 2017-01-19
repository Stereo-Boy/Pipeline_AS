function copy_files(source,expr,destination,verbose)
% function copyFiles(source,expr,destination,verbose)
% copy all files in source (default cd) designated by expr (default *.*) to 
% destination (default cd) and report it or not depending whether verbose is verboseON or verboseOFF
% destination needs to be a fullfile absolute path!!

if ~exist('verbose', 'var')||isempty(verbose); verbose='verboseON'; end
if ~exist('source', 'var')||isempty(source); warni('[copyfiles] no source folder - defaulting to cd', verbose); source=cd; end
if ~exist('destination', 'var')||isempty(destination); warni('[copyfiles] no destination folder - defaulting to cd', verbose); destination=cd; end
if ~exist('expr','var')||isempty(expr); expr='*.*';warni('[copyfiles] expr parameter missing - defaulting to all files in folder', verbose); end


%files=dir(fullfile(source,expr));
[files, nn]=get_dir(source, expr);

successTotal=0;
for i=1:nn %here
   [success,message]=copyfile(files{i}, destination); 
    if success==1, successTotal=successTotal+1; else warni(message,verbose), end     
end
dispi('[copyfiles] Copied ', successTotal, '/',nn,' files from ', source, ' to ', destination, verbose) 