function maskNii = create_ROI_inplane_mask(inplanePath, roiPath)
% ------------------------------------------------------------------------
% Take an nifti inplane file and a ROI .mat file and create a spm-like 
% inplane mask restricted to the ROI
%
% inplanePath - the nifti inplane(gems) file path
% roiPath - a .mat ROI file path
%
% maskNii is the nifti file of the inplane mask restricted to the ROI
% ------------------------------------------------------------------------

    if(~exist(inplanePath) || ~exist(roiPath))
        erri('Not enough info to create nifti inplane mask for ROI');
    end

% create new nifti file for mask in maskPath
    maskNii = readFileNifti(inplanePath);
       
% retrieve dimensions of inplane file
    dims = maskNii.dim;
% set mask data to 0's
    maskNii.data = int16(zeros(dims(1), dims(2), dims(3)));
    
% read ROI file and change corresponding data values in mask to 1
    load(roiPath);
    
    for i = 1:3:numel(ROI.coords)
        x = ROI.coords(i); % x is Ant>Post
       y = ROI.coords(i+1); % y is Left->Right
        z = ROI.coords(i+2); % z is Inf->Sup
        maskNii.data(dims(1) - y, x, z) = int16(1);
    end

% save mask in file
    [p,n,e]  = fileparts(inplanePath);
    maskPath = fullfile(p,strcat('ROI_inplane_mask',e));
    niftiWrite(maskNii, maskPath); 

end