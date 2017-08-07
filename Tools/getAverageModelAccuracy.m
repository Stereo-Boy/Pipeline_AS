function [meanvarexp, nbVarSupx] = getAverageModelAccuracy(retinoModelFile, x, verbose)
% Load model from file retinoModelFile (fFit one in Gray/Averages), extract and average its Variance Explained
% in meanvarexp. nbVarSupx is the number of voxels with variance explained >x%
if exist(retinoModelFile, 'file')==0; errori('Missing file for the retinotopic model'); end
if exist('verbose', 'var')==0; verbose='verboseON'; end
if exist('x', 'var')==0; x=10; end

     vol = initHiddenGray; %open Gray
     vol.curDataType = 2; % set to Averages
     dispi('Loading retino model map: File | Retinotopy Model | Load and Select Model File',verbose)
     vol = rmSelect(vol, 1, retinoModelFile);
     
     dispi('Select and average the variance explained:',verbose);
     model = viewGet(vol, 'RMModel');
     varexp = rmGet(model{1}, 'variance explained');
     meanvarexp = mean(varexp(:));
     nbVarSupx = sum(varexp(:)>(x/100));
     dispi('Mean variance explained: ',meanvarexp,' and nb of voxels with variance explained >',x,'%: ', nbVarSupx,'/',numel(varexp(:)),verbose)