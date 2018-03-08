function maskNii = create_ROI_volume_mask(volumePath, roiPath)
% ------------------------------------------------------------------------
% Take an nifti volume file and a ROI .mat file and create a spm-like 
% volume mask restricted to the ROI
%
% volumePath - the nifti volume(anatomical) file path
% roiPath - a .mat ROI file path
%
% maskNii is the nifti file of the volume mask restricted to the ROI
% ------------------------------------------------------------------------

    if(~exist(volumePath) || ~exist(roiPath))
        erri('Not enough info to create nifti volume mask for ROI');
    end

% create new nifti file for mask in maskPath
    maskNii = readFileNifti(volumePath);
    
% retrieve dimensions of volume file
    dims = maskNii.dim;
% set mask data to 0's
    maskNii.data = int16(zeros(dims(1), dims(2), dims(3)));
    
% read ROI file and change corresponding data values in mask to 1
    load(roiPath);
    
    for i = 1:3:numel(ROI.coords)
       x = ROI.coords(i); % x is Ant>Post
       y = ROI.coords(i+1); % y is Left->Right
       z = ROI.coords(i+2); % z is Inf->Sup
       maskNii.data(z, dims(2) - y, dims(3) - x) = int16(1);
    end
    
% save mask in file
    [p,n,e]  = fileparts(volumePath);
    maskPath = fullfile(p,strcat('ROI_volume_mask',e));
    niftiWrite(maskNii, maskPath); 

end
