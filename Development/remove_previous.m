function success = removePrevious(folder, verbose)
% success = removePrevious(folder, verbose)
%
% Checking whether the folder exists (from a previous instance) and removes
% it if it is there.
%
% verbose = verboseOFF, none of the disp function will give an ouput
% (default verboseON)
% ------------------------------------------------------------------------

% ------------------------------------------------------------------------
% Written Nov 2016
% Adrien Chopin
% -------------------------------------------------------------------------

if exist('verbose', 'var')==0; verbose='verboseON'; end
if exist('folder', 'var')==0; help(mfilename); warni('removePrevious needs an input', verbose); return; end

if exist(folder,'dir')
   [success, status]=rmdir(folder,'s'); if success; dispi('Previous run detected and removed: ', folder, verbose);else warni(status, verbose); end
else
    dispi('No previous run detected: ', folder, verbose)
end