function whiteMatterSegment_AS(subjectID)
% ------------------------------------------------------------------------------------------------------------
% fMRI processing pipeline whose goal is to automatize steps as much as
% possible
% ------------------------------------------------------------------------------------------------------------
% Sara Popham, October 2015
% From the work made by Adrien Chopin, Eunice Yang, Rachel Denison, Kelly 
% Byrne, Summer Sheremata
% ------------------------------------------------------------------------------------------------------------
% subjectID = name of folder in freesurfer SUBJECTS_DIR to be created
% 
% This allows either itkGray or mrGray file conversion based on user input.
% ------------------------------------------------------------------------------------------------------------
c=clock;
diaryFile = [num2str(c(1)),num2str(c(2)),num2str(c(3)),'whiteMatterSegment_AS.txt'];
diary(diaryFile);
diary ON
disp(dateTime)

%% FOLDER SETUP AND INITIAL CHECKS
disp('You should be in the 06_mrVista_session folder for the subject that you are analyzing.');
beep; pause
%check that directory is correct
[a,theFolder]=fileparts(pwd);
if strcmpi(theFolder,'06_mrVista_session')==0; error('You are not in the mrVista session folder...'); end

%define subject ID
if ~exist('subjectID','var'); beep; subjectID = input('Enter subject ID:','s'); else disp(['subject ID is: ',  subjectID]); end

mrVistaFolder = cd;
mprageFile = [mrVistaFolder '/nifti/mprage.nii.gz'];
if exist(mprageFile)==0
    error('Mprage file missing (if you run retino branch, please copy the file from main branch') 
else
    disp('Mprage file correctly detected in nifti folder')
end

%make new segmentation folder inside the mrVista session folder
if ~(exist([mrVistaFolder '/Segmentation'],'dir')==7)
    disp('Creating Segmentation folder in mrVista_Session folder')
    mkdir(mrVistaFolder,'Segmentation');
else
    warning('Be careful: segmentation folder in mrVista_Session folder already exists and it contains those files:');
    cd([mrVistaFolder '/Segmentation'])
    ls
    cd(mrVistaFolder)
end
destinationFolder = [mrVistaFolder '/Segmentation'];

%if exist('mrRxSettings.mat','file')==2
disp('--------      WHITE MATTER SEGMENTATION PIPELINE              --------');


%% WHITE MATTER SEGMENTATION
white_matter_seg = 1; %default is that this step will be run
freeSurferSubjectFolder = [getenv('SUBJECTS_DIR') '/' subjectID];
if exist(freeSurferSubjectFolder,'dir')==7
    disp(['A subject folder for this participant already exists in ' getenv('SUBJECTS_DIR')]);
    disp('Have you already run white matter segmentation for this participant?')
    beep; answer = input('1 - yes, skip the step, 2 - yes, delete the folder and redo, 3 - no, exit to check');
    disp(' ');
    if answer==1
        white_matter_seg = 0; %recon-all step will not be run
        disp('Skipping...')
    elseif answer==2
        disp('Deleting the folder')
        cd(freeSurferSubjectFolder)
        status = rmdir(freeSurferSubjectFolder,'s');
        if status==1; disp('Done'); else; warning('It did not happen but lets try to see'); end
        cd(mrVistaFolder)
    elseif answer==3
        error('Please change subjectID or delete subject folder and run white matter segmentation again.');
    else
        error('Input not understood.');
    end
end

if white_matter_seg  %only skipped if user input says that they have already run the white matter segmentation
                     %this will be double-checked on the next step by looking for the existance of the ribbon.mgz file
    disp('Starting white matter segmentation.  May take 8-24 hours to complete...');
    disp(' ');
    success = system(['recon-all -i ' mprageFile ' -subjid ' subjectID ' -all']);
    if success~=0
        error('Error in white matter segmentation... See other messages in command window for details.');
    end
end

cd([getenv('SUBJECTS_DIR') '/' subjectID '/mri'])

%% MGZ TO NII CONVERSION
if ~(exist('ribbon.mgz','file')==2) %absence of this file indicates that recon-all step has not been run
    error('Ribbon.mgz not found: recon-all segmentation for this subject was not completed.');
end
if ~(exist([subjectID '_nu_RAS_NoRS.nii.gz'],'file')==2) %absence of this file means conversion was not done and we can do it
    disp('-------------         Starting conversion of mgz files to nifti               -------------------')
    %run the mgz to nii conversion since it has not yet been done
    success = system(['mgz2niiOrNoRS.sh ' subjectID ' RAS']);
    if success~=0
        error('mgz2niiOrNoRS.sh: Error in conversion from mgz to nii file type.');
    else
        disp('mgz files were succesfully converted to nifti')
    end 
else
    disp([subjectID '_nu_RAS_NoRS.nii.gz file found: mgz2nii conversion step has previously been done. Be sure skipping it is the correct thing to do (escape now otherwise)...']);
    beep; pause;
    disp('Skipping...')
    disp(' ');
end

%% SETTING UP FILES FOR ITKGRAY OR MRGRAY (User input choice)
if ~(exist([subjectID '_nu_RAS_NoRS.nii.gz'],'file')==2) %absence of this file indicates that mgz2nii step has been run
    error([subjectID '_nu_RAS_NoRS.nii.gz not found: Conversion to nifti for this subject does not exist.']);
end

beep;
disp('Do you want to set up files for')
disp('1. itkGray')
disp('2. mrGray')
disp('3. Skip')
answer = str2double(input('4. Escape ', 's'));
disp(' ');
if answer==1 %I want to set up for itkGray
    disp('Starting fs_ribbon2itk to convert nifti file to itkGray class file')
    if exist('t1_class.nii.gz','file')==2 %presence of this file indicates it was already run in the past
        disp('Error: t1_class.nii.gz found: the code was already run in the past - please check')
        disp('Also note that this conversion is followed a step in which important files are copyied in the right location')
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

    disp('--------     Cleaning     - Copying files back to your segmentation folder in mrVista  --------------------------')
    %copy files to 06_mrVista_session/Segmentation/ folder (ribbon, nu and T1)
    disp('Copying nu.mgz file...'); success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/nu.mgz'],destinationFolder);
    if success; disp(' Done');else error('Error while copying nu.mgz file'); end
    
    disp('Copying ribbon.mgz file... '); success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/ribbon.mgz'],destinationFolder);
    if success; disp(' Done');else error('Error while copying ribbon.mgz file'); end
    
    disp('Copying T1.mgz file...');success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/T1.mgz'],destinationFolder);
    if success; disp(' Done');else error('Error while copying T1.mgz file'); end
    
    disp(['Copying ' subjectID '_nu_RAS_NoRS.nii.gz file...'])
        success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/' subjectID '_nu_RAS_NoRS.nii.gz'],destinationFolder);
    if success; disp(' Done');else error('Error while copying _nu_RAS_NoRS file'); end
    
    disp(['Copying ' subjectID '_ribbon_RAS_NoRS.nii.gz file... Done']);
        success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/' subjectID '_ribbon_RAS_NoRS.nii.gz'],destinationFolder);
    if success; disp(' Done'); else error('Error while copying _ribbon_RAS_NoRSfile'); end
    
    disp(['Copying ' subjectID '_T1_RAS_NoRS.nii.gz file... Done']);
        success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/' subjectID '_T1_RAS_NoRS.nii.gz'],destinationFolder);
    if success; disp(' Done'); else error('Error while copying _T1_RAS_NoRS file'); end
    
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
        error('Some itkGray files missing in your mrVista segmentation folder! Please check');
    end
elseif answer==2 %I do want to set up for mrGray
     disp(' ');
        
        disp('On any pop-ups that appear, save in the default location presented to you.  Press any key to continue.');
        pause
        disp(' ');
        
        createVolAnatSKERI([subjectID '_nu.nii.gz']);
        fs4_ribbon2class([subjectID '_ribbon.nii.gz']);
        
        %copy files to 06_mrVista_session/Segmentation/ folder
        success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/' subjectID '_nu.nii.gz'],destinationFolder);
        if success; disp(['Copying ' subjectID '_nu.nii.gz file... Done']);else error(status); end
        success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/' subjectID '_ribbon.nii.gz'],destinationFolder);
        if success; disp(['Copying ' subjectID '_ribbon.nii.gz file... Done']);else error(status); end
        success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/UnfoldParams.mat'],destinationFolder);
        if success; disp('Copying UnfoldParams.mat file... Done');else error(status); end
        success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/vAnatomy.dat'],destinationFolder);
        if success; disp('Copying vAnatomy.dat file... Done');else error(status); end
        success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/left.Class'],destinationFolder);
        if success; disp('Copying left.Class file... Done');else error(status); end
        success = copyfile([getenv('SUBJECTS_DIR') '/' subjectID '/mri/right.Class'],destinationFolder);
        if success; disp('Copying right.Class file... Done');else error(status); end
        disp(' ');
        
        %check that mrGray files were actually put in the correct place
        cd(destinationFolder);
        if exist([subjectID '_nu.nii.gz'],'file')==2 && exist([subjectID '_ribbon.nii.gz'],'file')==2 && exist('vAnatomy.dat','file')==2 ...
                && exist('vAnatomy.dat','file')==2 && exist('left.Class','file')==2 && exist('right.Class','file')==2
            disp('Necessary files for mrGray successfully copied!');
            disp(['Process complete for ' subjectID '!!']);
        else
            error('Some mrGray files missing! Please check');
        end
        close all %closing any figures that 
        
elseif answer==3
        disp('Skipping')
elseif answer==4
    error('Escaping...');
else
    error('Answer not understood')
end
disp(' ---------------------------------------------------------------------------------------------')
disp('--------     nifti header fix  --------------------------')
niftiFixFolder = [mrVistaFolder '/Segmentation_niftiFixed'];
if exist('niftiFixFolder','dir')==7
    disp('Segmentation_niftiFixed folder found: fix was probably done.')
    disp('Would you like to proceed (redo) or skip this correction')
    disp('1. Proceed')
    doFix = str2double(input('2. Skip  ', 's'));
else
    doFix=1;
    disp('Creating Segmentation_niftiFixed folder') 
    [success, status]=mkdir(niftiFixFolder); if success; disp('Done');else error(status); end
    disp('Copying file to the folder')
    [success, status]=copyfile([destinationFolder,'/t1_class.nii.gz'],niftiFixFolder); if success; disp('Done');else error(status); end
    [success, status]=copyfile([destinationFolder, '/', subjectID, '_nu_RAS_NoRS.nii.gz'],niftiFixFolder); if success; disp('Done');else error(status); end
end
if doFix == 1
    disp('Fixing...')
    niftiFixHeader3(niftiFixFolder);
elseif doFix==2 
    disp('Skipping - be aware that nifti header fix did not occur for your segmentation/anatomical files')
else
    error('Answer not understood...')
end

disp('--------  Installing volume Anatomy       --------')
    cd(niftiFixFolder);
    files=dir('*_nu_RAS_NoRS.nii.gz');
    vAnatFile = [niftiFixFolder,'/',files.name];
    if exist(vAnatFile,'file')==2
        disp('Linking vAnatomy')
        vPath = setVAnatomyPath(vAnatFile);
        disp('Linked to:')
        disp(vPath)
    else
        disp(['File _nu_RAS_NoRS.nii.gz does not exist']);
    end
disp(' ------------------ AUTO SEGMENTATION PIPELINE FINISHED ------------------------------------------------------------ ');

