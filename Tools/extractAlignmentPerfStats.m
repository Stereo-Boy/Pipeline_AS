function [averageCorr, sumRMSE]=extractAlignmentPerfStats(mrVistaFolder, sliceNb, verbose)
% [averageCorr, sumRMSE]=extractAlignmentPerfStats(mrVistaFolder, sliceNb, verbose)
% estimates the error in the alignment procedure (inplane/volume)
% averageCorr is the average correlation across all slices and sumRMSE is
% the summed error across all slices
% mrVistaFolder - where is the mrVista session 
% sliceNb - how many slices in the ref?
% verbose: verboseON (default) or verboseOFF

close all
%if exist('rmse'); clear rmse; end
%if exist('corrCoeffValue'); clear corrCoeffValue; end

if exist('verbose', 'var')==0; verbose='verboseON'; end
if exist('mrVistaFolder','var')==0; warni('You need to provide mrVista root for your session',verbose); mrVistaFolder =pwd; end
dispi('The alignment you want to assess should be saved as the current mr alignment', verbose)
%input('Press ENTER if OK')

dispi('Opens rxAlign window' ,verbose)
initialPath= pwd;
cd(mrVistaFolder);
rx = rxAlign ;
dispi('Compare slice Rx and reference for that last best alignment', verbose)
rx = rxOpenCompareFig(rx);

corrCoeffValue=nan(sliceNb,1);
rmse=nan(sliceNb,1);

for i=1:sliceNb
    disp(['Slice: ', num2str(i)])
    set(rx.ui.rxSlice.sliderHandle, 'Value',i)
    rx = rxRefresh(rx);
    corrCoeffValue(i) = str2double(get(rx.ui.compareStats.corrcoefVal, 'String'));
    rmse(i) = str2double(get(rx.ui.compareStats.rmseVal,'String'));
end

dispi('The different correlations for each slice are:', verbose)
disp(corrCoeffValue)
averageCorr = zFisherTransformInv(mean(zFisherTransform(corrCoeffValue)));
dispi('The average correlation is: ', averageCorr, verbose)
dispi('The different RMS errors for each slice are: ', rmse, verbose)
sumRMSE=sum(rmse);
dispi('The sum of RMS errors is: ', sumRMSE, verbose)
cd(initialPath);