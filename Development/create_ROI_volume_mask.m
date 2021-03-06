function [maskNii,n_vox] = create_ROI_volume_mask(volumePath, roiPath)
% ------------------------------------------------------------------------
% Take a nifti volume file and a ROI.mat file and create a spm-like 
% volume mask restricted to the ROI
%
% volumePath - the nifti volume(anatomical) file path
% roiPath - a .mat ROI file path - it is a set of coords refering to 
% voxels in the volume (following volume conventions)
%
% maskNii is the nifti file of the volume mask restricted to the ROI
% ------------------------------------------------------------------------

    if(~exist(volumePath,'file')) || (~exist(roiPath, 'file'))
        error('Not enough info to create nifti volume mask for ROI');
    end

% create new nifti file for mask in maskPath
    maskNii = spm_vol_nifti(volumePath);
    %maskNii = readFileNifti(volumePath);
    
% retrieve dimensions of volume file
    dims = maskNii.dim;

% set mask data to 0's
    %masknii.data = int8(zeros(dims(1), dims(2), dims(3)));
    data = int8(zeros(dims(1), dims(2), dims(3)));
    
% read ROI file and change corresponding data values in mask to 1
    load(roiPath);

    for i = 1:3:numel(ROI.coords)
       x = ROI.coords(i); % x is Ant>Post
       y = ROI.coords(i+1); % y is Left->Right
       z = ROI.coords(i+2); % z is Inf->Sup
       data(z, dims(2) - y, dims(3) - x) = int8(1);
    end
    n_vox=sum(data(:));
% save mask in file
    %p  = fileparts(volumePath);
    %maskPath = fullfile(p,'ROI_volume_mask.nii');
    [path_roi,roi_name]=fileparts(roiPath);
    maskNii.fname=fullfile(path_roi,['ROI_',roi_name,'.nii']);
    %maskPath=fullfile(path_roi,['ROI_',roi_name,'.nii']);
    spm_write_vol(maskNii,data);
    %niftiWrite(maskNii, maskPath); 
    %save_nii(maskNii, maskNii.fname); 
    
    %maskNii = spm_vol_nifti(maskPath);
    %dat=spm_read_vols(maskNii);
    %spm_write_vol(maskNii,dat);
end
