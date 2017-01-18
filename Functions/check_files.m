function [success, nbFiles] = check_files(folder, expr, n, forceError, verbose)
% [success, nbFiles] = check_files(folder, expr, n, forceError, verbose)
% Check if number of files of certain expression exist in folder.
% 
% Inputs:
% folder: a directory in which the function will check the file existence (default pwd)
% expr: string expression of files to check
% n: number of expected files
% forceError = 1 (default 0): forces an error instead of a warning 
% verbose = verboseOFF, none of the disp function will give an ouput
% (default verboseON)
%
% Outputs:
% success: boolean result of checking if number of files with expr matches n
%
% Example:
% success = check_files('*_mcf.nii*', 6)
% 
% success =
% 
%      1
% 
% Created by Justin Theiss 11/2016
% Edited by Adrien Chopin 11/2016

% return number of files with expr == n
if ~exist('verbose', 'var'); verbose='verboseON'; end
if ~exist('forceError', 'var'); forceError=0; end
if ~exist('folder','var')||~exist(folder, 'dir'), help(mfilename);erri('Missing folder'); end
if ~exist('expr','var'), expr='*.*';warni('check_files expr parameter missing - defaulting to all files in folder', verbose); end

nbFiles=numel(dir(fullfile(folder,expr)));
success = (nbFiles == n);

if success==1
    dispi(nbFiles,'/',n,' files correctly detected (', expr, ') in ', folder, verbose)
else
    if forceError, erri('Nb of files is incorrect: (',expr,'): ', nbFiles,'/',n,' files detected in ', folder)
    else warni('Nb of files is incorrect (',expr,'): ', nbFiles,'/',n,' files detected.in ', folder, verbose)
    end
end
return;