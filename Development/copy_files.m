function copy_files(source,expr,destination,verbose)
% function copyFiles(source,expr,destination,verbose)
% copy all files in source (default cd) designated by expr (default *.*) to 
% destination (default cd) and report it or not depending whether verbose is verboseON or verboseOFF
% destination needs to be a fullfile absolute path!!

if exist('verbose', 'var')==0; verbose='verboseON'; end
if exist('source', 'var')==0; warni('copyFiles: no source folder - defaulting to cd', verbose); source=cd; end
if exist('destination', 'var')==0; warni('copyFiles: no destination folder - defaulting to cd', verbose); destination=cd; end
if ~exist('expr','var'), expr='*.*';warni('copyFiles: expr parameter missing - defaulting to all files in folder', verbose); end


files=dir(fullfile(source,expr));
successTotal=0;
for i=1:numel(files)
   [success,message]=copyfile(fullfile(source, files(i).name), destination); 
    if success==1, successTotal=successTotal+1; else dispi(message,verbose), end     
end
dispi('copyfiles: moved ', successTotal, '/',numel(files),' files from ', source, ' to ', destination, verbose) 