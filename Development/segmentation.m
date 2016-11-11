function segmentation(subjectID, mprageNiftiFixedFolder,mprageSegmentedFolder, verbose)
% ------------------------------------------------------------------------------------------------------------
% fMRI processing pipeline whose goal is to automatize steps as much as
% possible
% ------------------------------------------------------------------------------------------------------------
% Justin Theiss and Adrien Chopin
% Legacy Adrien Chopin, Sara Popham late Aug 2015
% ------------------------------------------------------------------------------------------------------------
% subjectID = name of folder in freesurfer SUBJECTS_DIR to be created
% mprageNiftiFixedFolder is the folder in which you have the mprage folder
% to segment
% This allows either itkGray or mrGray file conversion based on user input.
% ------------------------------------------------------------------------------------------------------------

%define subject ID
if ~exist('subjectID','var'); erri('segmentation: subjectID not defined', verbose), end
if ~exist('mprageNiftiFixedFolder','var'); mprageNiftiFixedFolder=cd; dispi('segmentation: mprageNiftiFixedFolder not defined. Defaulting to ',mprageNiftiFixedFolder, verbose), end
if ~exist('mprageSegmentedFolder','var'); erri('segmentation: destination folder is not defined', verbose), end
destinationFolder=mprageSegmentedFolder;

% WHITE MATTER SEGMENTATION
freeSurferSubjectFolder = [getenv('SUBJECTS_DIR') '/' subjectID];
if exist(freeSurferSubjectFolder,'dir')==7
    dispi('A subject folder for this participant already exists in ', getenv('SUBJECTS_DIR'), verbose);
    dispi('We will delete the folder.', verbose)
        cd(freeSurferSubjectFolder)
        status = rmdir(freeSurferSubjectFolder,'s');
        if status==1; dispi('Done', verbose); else warni('It did not happen but lets try to see whether it works anyway', verbose); end
        cd(mprageNiftiFixedFolder)
end

 %this will be double-checked on the next step by looking for the existance of the ribbon.mgz file
    dispi('Starting white matter segmentation.  May take 8-24 hours to complete...', verbose);
    dispi('------------------------------------------------------------------------- ', verbose);
    mprageFile=dir('*mprage*.nii.gz'); %should be only 1 mprage nifti folder here
    success = system(['recon-all -i ' mprageFile ' -subjid ' subjectID ' -all']);
    
    if success~=0
        error('Error in white matter segmentation... See other messages in command window for details.');
    end


cd([getenv('SUBJECTS_DIR') '/' subjectID '/mri'])

% MGZ TO NII CONVERSION
if ~(exist('ribbon.mgz','file')==2) %absence of this file indicates that recon-all step has not been run
    error('Ribbon.mgz not found: recon-all segmentation for this subject was not completed.');
end
if ~(exist([subjectID '_nu_RAS_NoRS.nii.gz'],'file')==2) %absence of this file means conversion was not done and we can do it
    dispi('-------------         Starting conversion of mgz files to nifti               -------------------', verbose)
    %run the mgz to nii conversion since it has not yet been done
    success = system(['mgz2niiOrNoRS.sh ' subjectID ' RAS']);
    if success~=0
        error('mgz2niiOrNoRS.sh: Error in conversion from mgz to nii file type.');
    else
        dispi('mgz files were succesfully converted to nifti', verbose)
    end 
else
    dispi(subjectID, '_nu_RAS_NoRS.nii.gz file found: mgz2nii conversion step has previously been done. Be sure skipping it is the correct thing to do (escape now otherwise)...', verbose);
    beep; pause;
    disp('Skipping...')
    disp(' ');
end

% SETTING UP FILES FOR ITKGRAY OR MRGRAY (User input choice)
if ~(exist([subjectID '_nu_RAS_NoRS.nii.gz'],'file')==2) %absence of this file indicates that mgz2nii step has been run
    error([subjectID '_nu_RAS_NoRS.nii.gz not found: Conversion to nifti for this subject does not exist.']);
end

dispi('Setting up files for itkGray', verbose)
dispi('Starting fs_ribbon2itk to convert nifti file to itkGray class file', verbose)
    if exist('t1_class.nii.gz','file')==2 %presence of this file indicates it was already run in the past
        disp('Error: t1_class.nii.gz found: the code was already run in the past - please check')
        disp('Also note that this conversion is followed by a step in which important files are copyied in the right location')
        disp('So please do not skip that step if it was wrongly addressed')
        error('See error above')
    else %OK run the code
        fs_ribbon2itk(subjectID);
    end
    
    %check that fs_ribbon2itk was successful
    if exist('t1_class.nii.gz','file')==2
        disp(' ')
        disp('Default file t1_class.nii.gz was succesfully produced')
    else
        error('t1_class.nii.gz missing: fs_ribbon2itk went wrong')
    end

    disp('--------     Cleaning     - Copying files back to your segmentation folder  --------------------------')
    %copy files to 06_mrVista_session/Segmentation/ folder (ribbon, nu and T1)
   % disp('Copying nu.mgz file...'); success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/nu.mgz'],destinationFolder);
   % if success; disp(' Done');else error('Error while copying nu.mgz file'); end
    
   % disp('Copying ribbon.mgz file... '); success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/ribbon.mgz'],destinationFolder);
   % if success; disp(' Done');else error('Error while copying ribbon.mgz file'); end
    
   % disp('Copying T1.mgz file...');success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/T1.mgz'],destinationFolder);
   % if success; disp(' Done');else error('Error while copying T1.mgz file'); end
    
    disp(['Copying ' subjectID '_nu_RAS_NoRS.nii.gz file...'])
        success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/' subjectID '_nu_RAS_NoRS.nii.gz'],destinationFolder);
    if success; disp(' Done');else error('Error while copying _nu_RAS_NoRS file'); end
    
  %  disp(['Copying ' subjectID '_ribbon_RAS_NoRS.nii.gz file... Done']);
   %     success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/' subjectID '_ribbon_RAS_NoRS.nii.gz'],destinationFolder);
   % if success; disp(' Done'); else error('Error while copying _ribbon_RAS_NoRSfile'); end
    
   % disp(['Copying ' subjectID '_T1_RAS_NoRS.nii.gz file... Done']);
   %     success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/' subjectID '_T1_RAS_NoRS.nii.gz'],destinationFolder);
   % if success; disp(' Done'); else error('Error while copying _T1_RAS_NoRS file'); end
    
    disp('Copying t1_class.nii.gz file... Done');
        success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/t1_class.nii.gz'],destinationFolder);
    if success; disp(' Done');else error('Error while copying t1_class.nii.gz file'); end
    disp('  ');
    
    %check that itkGray files were actually put in the correct place
    cd(destinationFolder);
    if exist('t1_class.nii.gz','file')==2 && exist([subjectID '_nu_RAS_NoRS.nii.gz'],'file')==2 && exist([subjectID '_ribbon_RAS_NoRS.nii.gz'],'file')==2
        disp('Necessary files for itkGray successfully copied!');
        disp(['Process complete for ' subjectID '!!']);
    else
        error('Some itkGray files missing in your segmentation folder! Please check');
    end

disp(' ---------------------------------------------------------------------------------------------')
disp('--------     nifti header fix  --------------------------')
    disp('Fixing...')
    niftiFixHeader3(destinationFolder);

disp(' ------------------ AUTO SEGMENTATION FINISHED ------------------------------------------------------------ ');

