function [averageCorr, sumRMSE] = extractAlignmentPerfStats(mrVistaFolder, sliceNb, verbose)
% [averageCorr, sumRMSE] = extractAlignmentPerfStats(mrVistaFolder, sliceNb, verbose)
% estimates the error in the alignment procedure (inplane/volume)
% averageCorr is the average correlation across all slices and sumRMSE is
% the summed error across all slices
% 
% Inputs:
% mrVistaFolder - path to mrSession directory 
% sliceNb - number of slices in the reference file
% verbose: 'verboseON' (default) or 'verboseOFF'
%
% Outputs:
% averageCorr - average correlation value across slices
% sumRMSE - sum of RMSE values across slices
%
% Created by Adrien Chopin 10/2016

% close open windows
close('all');

% init vars
if ~exist('verbose', 'var'); verbose = 'verboseON'; end;
if ~exist('mrVistaFolder','var'), mrVistaFolder = pwd; end;

% display inputs
dispi(mfilename,'\nmrVistaFolder: ',mrVistaFolder,'\nsliceNb: ',sliceNb,verbose);

% open rxAlign window
dispi('Opening rxAlign window', verbose);
initialPath= pwd;
cd(mrVistaFolder);
rx = rxAlign;
dispi('Comparing slice Rx and reference alignment', verbose);
rx = rxOpenCompareFig(rx);

% init outputs
corrCoeffValue=nan(sliceNb,1);
rmse=nan(sliceNb,1);

% for each slice, get correlation and rmse values
for i=1:sliceNb
    dispi('Slice: ', i, verbose);
    set(rx.ui.rxSlice.sliderHandle, 'Value',i);
    rx = rxRefresh(rx);
    corrCoeffValue(i) = str2double(get(rx.ui.compareStats.corrcoefVal, 'String'));
    rmse(i) = str2double(get(rx.ui.compareStats.rmseVal,'String'));
end

% display correlations
dispi('Correlations for each slice:\n', corrCoeffValue, verbose);
averageCorr = zFisherTransformInv(mean(zFisherTransform(corrCoeffValue)));
% display average
dispi('Average correlation: ', averageCorr, verbose);
% display rmse's
dispi('RMS errors for each slice:\n', rmse, verbose);
sumRMSE=sum(rmse);
% display sum
dispi('Sum of RMS errors: ', sumRMSE, verbose);
% return to initial path
cd(initialPath);
end