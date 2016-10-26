function [averageCorr sumRMSE]=extractAlignmentPerfStats

close all
if exist('rmse'); clear rmse; end
if exist('corrCoeffValue'); clear corrCoeffValue; end

disp('You need to be in the mrVista root for your session')
disp('And the alignment you want to assess should be saved as the mR alignment')
input('Press ENTER if OK')

disp('Open current rxAlign window')
rx = rxAlign ;
disp('Compare slice Rx and reference for the last best alignment')
rx = rxOpenCompareFig(rx);

disp('For simplicity,  here, we assume that we have 24 slices')
sliceNb=24;
corrCoeffValue=nan(sliceNb,1);
rmse=nan(sliceNb,1);

for i=1:sliceNb
    disp(['Slice: ', num2str(i)])
    set(rx.ui.rxSlice.sliderHandle, 'Value',i)
    rx = rxRefresh(rx);
    corrCoeffValue(i) = str2double(get(rx.ui.compareStats.corrcoefVal, 'String'));
    rmse(i) = str2double(get(rx.ui.compareStats.rmseVal,'String'));
end

disp('The different correlations for each slice are:')
disp(num2str(corrCoeffValue))
disp('The average correlation is: ')
averageCorr = zFisherTransformInv(mean(zFisherTransform(corrCoeffValue)));
disp(num2str(averageCorr))
disp('The different RMS errors for each slice are:')
disp(num2str(rmse))
disp('The sum of RMS errors is: ')
sumRMSE=sum(rmse);
disp(num2str(sumRMSE))