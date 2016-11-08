function [tf, nbFiles] = check_files(folder, expr, n, forceError, verbose)
%  tf = check_files(folder, expr, n, forceError, verbose)
% Check if number of files of certain expression exist.
% 
% Inputs:
% folder: a directory in which the function will check the file existence
% expr: string expression of files to check
% n: number of expected files
% forceError = 1 (default 0): forces an error instead of a warning 
% verbose = verboseOFF, none of the disp function will give an ouput
% (default verboseON)
%
% Outputs:
% tf: boolean result of checking if number of files with expr matches n
%
% Example:
% tf = check_files('*_mcf.nii*', 6)
% 
% tf =
% 
%      1
% 
% Created by Justin Theiss 11/2016
% Edited by Adrien Chopin 11/2016

% return number of files with expr == n
if exist('verbose', 'var')==0; verbose='verboseON'; end
if exist('forceError', 'var')==0; forceError=0; end
if (~exist('folder','var')||~exist(folder, 'dir')), help(mfilename);erri('Missing folder'); end
if ~exist('expr','var'), expr='*.*';warni('check_files expr parameter missing - defaulting to all files in folder', verbose); end

currentPwd=pwd;
cd(folder);
nbFiles=numel(dir(expr));
tf = (nbFiles == n);

if tf==1
    dispi(nbFiles,'/',n,' files correctly detected (', expr, ') in ', cd, verbose)
else
    if forceError, erri('Nb of files is incorrect: ', nbFiles,'/',n,' files detected in ', cd)
    else warni('Nb of files is incorrect: ', nbFiles,'/',n,' files detected.in ', cd, verbose)
    end
end
cd(currentPwd);
return;