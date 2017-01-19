function o=parameterFile(subj_dir, verbose)
%   o = parameterFile
% This function neesd to be present in a the root folder for the subject to 
% be analysed with pipeline_JAS.m.
% It should define basic expected parameters such as:
% o.mprageSliceNb - the number of expected slices for the mprage 
% o.retinoEpiTRNb - the number of expected TR for the retino EPI  
% o.expEpiTRNb = the number of expected TR for the exp EPI  
% All of these parameters will be instanciated as variables after loading

% Written nov 2016 - Adrien Chopin
% Justin-unapproved

 % defines standard folders for each step 
       o.mpr_dicom_dir = fullfile(subj_dir,'01a_mprage_DICOM');
       o.mpr_ni_dir = fullfile(subj_dir,'02_mprage_nifti');
       o.mpr_segm_dir = fullfile(subj_dir,'03_mprage_segmented');
       o.mpr_niFixed_dir = fullfile(subj_dir,'04_mprage_nifti_fixed');

       o.ret_dicom_dir = fullfile(subj_dir,'01b_epi_retino_DICOM');
       o.ret_ni_dir = fullfile(subj_dir,'03_retino_nifti');
       o.ret_mc_dir = fullfile(subj_dir,'04_retino_MC');
       o.ret_mcFixed_dir = fullfile(subj_dir,'05_retino_nifti_fixed');
       o.ret_mr_dir = fullfile(subj_dir,'06_retino_mrSession');
       o.ret_mr_ni_dir=fullfile(o.ret_mr_dir,'nifti');
       o.ret_mr_mesh_dir=fullfile(o.ret_mr_dir,'Mesh');
        
%         expDICOMfolder = fullfile(subj_dir,'01c_epi_exp_DICOM');
%         expPARfolder = fullfile(subj_dir,'01d_epi_exp_PAR');
%         expNiftiFolder = fullfile(subj_dir,'03_exp_nifti');
%         expMCfolder = fullfile(subj_dir,'04_exp_MC');
%         expNiftiFixedFolder = fullfile(subj_dir,'05_exp_nifti_fixed');
%         expMrSessionFolder = fullfile(subj_dir,'06_exp_mrSession');

 % standard file names in vista session / nifti
        o.gemsFile = 'gems_retino.nii.gz';
        o.mprageFile = 'mprage_nu_RAS_NoRS.nii.gz';

 % motion correction parameters
    o.reference = 3;            % reference option for motion correction of epis and/or gems
            % reference values:
                % 1. gems downsampled at epi resolution - gems is corrected
                % 2. gems at original resolution - epi will be upsampled to gems resolution - gems is corrected
                % 3. first epi, first TR - gems is uncorrected
                % 4. first epi, first TR - gems is corrected  
                % 5. first epi, middle TR - gems is uncorrected
                
 % nifti header fix 
    o.nifti_fix_skip = 0;        % whether to skip (1) or do (0) nifti header fixing
    o.freq_dim = 1;              % necessary to correct nifti header
    o.phase_dim = 2;             % necessary to correct nifti header
    o.slice_dim = 3;             % necessary to correct nifti header
    
 % mprage
    o.mprageSliceNb = 160;                                  % nb of slices in the mprage scan
    o.mpr_slice_end = 'eval(ni.dim(ni.slice_dim)-1)';       % necessary to correct nifti header for mprage
    o.mpr_slice_duration = 0;                               % necessary to correct nifti header for mprage (0 avoid mrvista slice timing correction)
    
 % retino epi
    o.retinoEpiNb = 6;                                          % nb of retinotopic epis
    o.retinoEpiTRNb = 135;                                      % nb of TR in the retino epi scans
    o.pRFdummyFramesNb = 5;                                     % nb of frames to remove for pRF (first fixation TR)
    o.retinoEpiTRNbAdj = o.retinoEpiTRNb-o.pRFdummyFramesNb;    % nb of TR in the retino epi scans after adjusting by removing some pRF-dummy frames
    o.retinoEpi_slice_duration = 1.8; %TR in sec
    
 % retino gems
    o.retinoGemsNb = 1;                 % nb of retinotopic gems
    o.retinoGemsSliceNb = 24;           % nb of slices in the gems scan
    o.retinoGems_slice_duration = 0;	%(0 avoid mrvista slice timing correction)
 
 % exp epi
    o.expEpiNb = 10;                % nb of exp epis
    o.expEpiTRNb = 126;             % nb of TR in the experimental epi scans
    
 % exp gems
    o.expGemsNb = 1;                % nb of exp gems
    o.expGemsSliceNb = 38;          % nb of slices in the gems scan
    o.expGems_slice_duration = 0;   %(0 avoid mrvista slice timing correction)
   
 % mesh parameters
    o.smoothingIterations = 600; %nb of iteration for smoothing when inflating mesh
    
    if strcmp(verbose,'verboseON'); disp(o); end
 
 % pRF retino parameters
    o.analysis = struct('fieldSize',9.1,...
            'sampleRate',.28);
        if strcmp(verbose,'verboseON'); disp(o.analysis); end       
 
    o.stim(1) = struct('stimType', '8Bars',...
             'stimSize', 9.1,...
            'stimWidth', 213.6264,...
              'nCycles', 1,...
           'nStimOnOff', 4,...
           'nUniqueRep', 1,...
      'prescanDuration', 5,...
                 'nDCT', 0,...
          'framePeriod', o.retinoEpi_slice_duration,...
              'nFrames', o.retinoEpiTRNbAdj,...
           'fliprotate', [0 0 0],...
               'imFile', 'None',...
           'jitterFile', 'None',...
           'paramsFile', 'None',...
             'imFilter', 'None',...
     'orientationOrder', [2,1,4,7,3,8,5,6],...
            'nOffBlock', 6.5,...
            'hrfType','two gammas (SPM style)',...
            'hrfParams',{{[1.68 3 2.05],[5.4 5.2 10.8 7.35 0.35]}});
      if strcmp(verbose,'verboseON'); disp(o.stim); end
