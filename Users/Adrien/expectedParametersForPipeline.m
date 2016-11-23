function o = expectedParametersForPipeline(verbose)
%   o = expectedParametersForPipeline(verbose)
% This function neesd to be present in a the root folder for the subject to 
% be analysed with pipeline_JAS.m.
% It should define basic expected parameters such as:
% o.mprageSliceNb - the number of expected slices for the mprage 
% o.retinoEpiTRNb - the number of expected TR for the retino EPI  
% o.expEpiTRNb = the number of expected TR for the exp EPI  

% Written nov 2016 - Adrien Chopin
% Justin-unapproved

if exist('verbose', 'var')==0; verbose='verboseON'; end

% Checks that the called parameter file is the correct one
if strcmp(cd, fileparts(which('expectedParametersForPipeline')))==1
    dispi('Loading parameters found in file in root subject folder', verbose) 
else
   warning(['Parameter file not found  in root subject folder. Loading default: ', which('expectedParametersForPipeline')])
   
end
    o.mprageSliceNb = 160;  % nb of slices in the mprage scan
    o.retinoEpiTRNb = 135;  % nb of TR in the retino epi scans
    o.expEpiTRNb = 126;     % nb of TR in the experimental epi scans
    o.retinoGemsSliceNb = 24;  % nb of slices in the gems scan
    o.retinoEpiNb = 6;      % nb of retinotopic epis
    o.retinoGemsNb = 1;      % nb of retinotopic gems
    o.expEpiNb = 10;      % nb of exp epis
    o.expGemsNb = 1;      % nb of exp gems
    o.pRFdummyFramesNb = 5; % nb of frames to remove for pRF (first fixation TR)
end