function preprocessing_AS(subj_dir, subj, type, notes_dir)
% preprocessing_AS(subj_dir, subj, notes_dir)
%
% fMRI processing pipeline whose goal is to automatize steps as much as
% possible
%
% Inputs:
% subj_dir: directory path for subject analysis (string)
% subj: subject id (string)
% type: type of scans normal/retino (as 0/1)
% notes_dir: [optional] directory path to save command output (string)
%
% Adrien chopin, Sara Popham late Aug 2015
% From the work made by Eunice Yang, Rachel Denison, Kelly Byrne, Summer
% Sheremata
% Edited by Justin Theiss Oct 2016
% ------------------------------------------------------------------------------------------------------------
clc

%init vars
if ~exist('subj_dir','var')||~exist(subj_dir, 'dir'), 
    subj_dir = uigetdir(pwd, 'Choose folder for analysis:'); 
end;
if ~exist('subj','var'), [~, subj] = fileparts(subj_dir); end;
if exist('notes_dir','var') && exist(notes_dir, 'dir'),
    % create desired filepath
    notes_path = fullfile(notes_dir, date, [subj '_preprocessing_AS']);
    % mkdir if needed
    if ~exist(fileparts(notes_path), 'dir'),
        mkdir(fileparts(notes_path));
    end
    % if another file has been run, append file with number
    apnd = numel(dir([notes_path '*.txt']));
    if apnd == 0, apnd = ''; else apnd = num2str(apnd); end;
    % start diary
    diary([notes_path apnd '.txt']);
end

% display checklist
disp(' --------------   CHECKLIST BEFORE STARTING   -----------------')
disp('- DICOM files should be in the subject folder in a folder called 01_Raw_DICOM')
disp('- PAR files should be in the folder 01_PAR (except for the retino branch)')
disp('- Epi, in 01_Raw_DICOM, should be in folders called epi01-whatever, epi02-whatever, ....')
disp('- Gems, in 01_Raw_DICOM, should be in folders called gems-whatever (no capital)')
disp('- mprage, in 01_Raw_DICOM, should be in folders called gems_mprage-whatever (no capital).')

% % % %check whether pathFile.mat can be found (a file that should be in your
% % % %Pipeline_AS/Users/ and which defines where is Pipeline_AS
% % % if exist('pathFile.mat','file')~=2; 
% % %     disp('pathFile.mat not found'); 
% % %     disp('Creating your personal pathFile')
% % %     pipelineASFolder = input('Enter absolute path to Pipeline_AS folder (included, no need for ''): ','s'); 
% % %     userFolder = input('What is the name of your personal folder in Pipeline_AS? ','s'); 
% % %     %no end slash
% % %     if strcmpi(pipelineASFolder(end),'/'); pipelineASFolder = pipelineASFolder(1:end-1); end
% % %     save([pipelineASFolder,'/Users/',userFolder,'/pathFile.mat'],'pipelineASFolder');
% % % else
% % %     load('pathFile.mat','pipelineASFolder')
% % %     disp(['Loaded pathFile.mat from ',which('pathFile.mat')])
% % % end

% Naming conventions for the different folders in subject folder
dcm_dir = fullfile(subj_dir,'01_Raw_DICOM');
par_dir = fullfile(subj_dir,'01_PAR');
backup_dir = fullfile(subj_dir,'02_Raw_DICOM_Backup');
nii_dir = fullfile(subj_dir,'03_nifti');
mc_dir = fullfile(subj_dir,'04A_MoCo');
mc_ck_dir = fullfile(subj_dir,'04B_MoCo_Check');
nii_fix_dir = fullfile(subj_dir,'05_nifti_fixed');
mr_dir = fullfile(subj_dir,'06_mrVista_session');

% Retino/normal scan branches
if retino==1; disp('Retinotopy branch'); elseif retino==0; disp('Normal branch'); end

disp(['***********       STARTING PIPELINE  AT  ', dateTime,' for subjectID ', subj,'       *******************'])
%check existence of folders
disp(['Subject folder is : ', subj_dir])
disp('Testing whether dcm2nii is found (you should see Chris Rordens dcm2nii help below):')
if system('dcm2nii')>0
    error('System call to dcn2nii failed') 
end

% file organization
disp(['---------       01-02  FILE ORGANISATION AND NIFTI CONVERSION (',dateTime,')         ---------------------------------------------------------'])
%first check the existence of the two initial folders
if exist(subject_folderDICOM,'dir')==7; disp('Raw DICOM folder in Subject folder exists'); else error('Missing Raw DICOM folder in Subject folder...'); end
if retino==0
    if exist(subject_folderPAR,'dir')==7; disp('PAR folder in Subject folder exists'); else error('Missing PAR folder in Subject folder...'); end
else
    disp('Retino scan branch - skipping PAR file check')
end
    
    %check whether nifti conversion was already run successfully or not
    doNiftiConversion = 1; %default
    doReOrg = 1; %default
    if exist(subject_folderNIFTI,'dir')==7; 
        disp('dicom2vista_org.py was previously run and files reorganized (nifti folder detected) - so we skip that step and the next')
        doNiftiConversion = 0;
        doReOrg = 0;
    end
    %next block is skipped if previous condition was validated
    if doNiftiConversion==1 && exist([subject_folderDICOM,'/',dcm_dir,'_backup'],'dir')==7; 
            disp('It seems that dicom2vista_org.py was previously run. What to do?'); 
            disp('1. Run again (will move folder back to where they should be)');
            disp('2. Skip (recommended)');
            disp('3. Escape');
            answer2 = input('? ','s');
        switch answer2
            case {1} %go for it, so first move folders back to starting structure
                disp('Copying folder from backup back to raw dicom folder...')
                    [success, status]=copyfile([subject_folderDICOM,'/',dcm_dir,'_backup/*'],subject_folderDICOM); if success; disp('Done');else error(status); end
                disp('Deleting old folders...')
                    [success, status]=rmdir([subject_folderDICOM,'/',dcm_dir,'_backup'],'s'); if success; disp('Done');else error(status); end
                    [success, status]=rmdir([subject_folderDICOM,'/',dcm_dir,'_nifti'],'s');  if success; disp('Done');else error(status); end
                    [success, status]=rmdir([subject_folderDICOM,'/',dcm_dir,'_dicom'],'s');  if success; disp('Done');else error(status); end
            case {2} %dont go, move to next step
                doNiftiConversion = 0;
            case {3} %escape
                error('Voluntary interruption')
            otherwise
                error('Answer not understood')
        end
    end
    if doNiftiConversion; 
        disp('Starting dicom2vista_org.py...'); 
            success=system(['python dicom2vista_org.py ', subject_folderDICOM]); %CAREFUL - this is a python 2.7 code that does not work with 3.4 syntax (check what version is run by typing system python in matlab)
            if success==0 %GOOD
                disp('python dicom2vista_org.py: DONE'); 
            else %NOT GOOD
                disp('Something went wrong with last step')
                disp('Assuming it did not find dicom2vista_org.py from python environment, which is the most common, we will try first to run')
                disp(' an absolute link to that file, if we can localize it.')
                absoPath2File=which('dicom2vista_org.py');
                if isempty(absoPath2File)==0; disp(['We have localized it to ', absoPath2File]); end
                disp(['python ', absoPath2File, ' ', subject_folderDICOM])
                success=system(['python ', absoPath2File, ' ', subject_folderDICOM]);
                if success==0; disp('Success! python dicom2vista_org.py: DONE');  else error('Failure!'); end
            end
        %check that nifti conversion was successful
        cd([subject_folderDICOM,'/',dcm_dir,'_nifti']);
        [match,dummy] =  regexp(ls,'epi+\w+\.nii\.gz','match','split');%find all nii.gz files starting with epi
            if isempty(match)==1; 
                error('Unsuccessful nifti conversion'); 
            else
                if numel(match)==nbOfEPI
                    disp(['Nifti conversion seems successful: ',num2str(nbOfEPI),' nifti files detected.']);
                else  
                    error(['We detected converted nifti files but the number of files seems incorrect: ',num2str(numel(match)), 'files instead of ', num2str(nbOfEPI)]); 
                end
            end
        disp('Finished FILE ORGANISATION AND NIFTI CONVERSION')
    end

disp(['---------      03   REORGANISATION II   (',dateTime,')    ---------------------------------------------------------------------------'])
    %check whether reorganization was already run successfully or not
    if exist(fullfile(subj_dir,backup_dir),'dir')==7; 
        disp('You may have run the reorgaisation II code before (Raw DICOM backup folder detected). What to do?');  
        disp('2. Skip (recommended)');
        beep; answer3 = input('3. Escape ');
        switch answer3
            case {2} %dont go, move to next step
                doReOrg = 0;
                disp('Skipped');
            case {3} %escape
                error('Voluntary interruption')
            otherwise
                error('Answer not understood')
        end
    end

    if doReOrg==1 %reorganisation II
        disp(['Creating backup folder: ', backup_dir])
            [success, status]=mkdir(fullfile(subj_dir,backup_dir)); if success; disp('Done');else error(status); end
        disp('Moving DICOM files to backup folder and back to initial folder')
            [success, status]=copyfile([subject_folderDICOM,'/',dcm_dir,'_backup/*'],fullfile(subj_dir,backup_dir)); if success; disp('Done');else error(status); end
            [success, status]=copyfile([subject_folderDICOM,'/',dcm_dir,'_backup/*'],fullfile(subj_dir,dcm_dir)); if success; disp('Done');else error(status); end
        disp(['Creating nifti folder: ', nii_dir])
            [success, status]=mkdir(subject_folderNIFTI); if success; disp('Done');else error(status); end
        disp('Moving nifti files to nifti folder')
            [success, status]=copyfile([subject_folderDICOM,'/',dcm_dir,'_nifti/*'],subject_folderNIFTI); if success; disp('Done');else error(status); end
        disp('Deleting old folders...')
            [success, status]=rmdir([subject_folderDICOM,'/',dcm_dir,'_backup'],'s'); if success; disp('Done');else error(status); end
            [success, status]=rmdir([subject_folderDICOM,'/',dcm_dir,'_nifti'],'s');  if success; disp('Done');else error(status); end
            [success, status]=rmdir([subject_folderDICOM,'/',dcm_dir,'_dicom'],'s');  if success; disp('Done');else error(status); end
        disp('Finished REORGANISATION II ')
    else
        disp('Reorganisation II skipped')
    end

disp(['---------      04A   MOTION CORRECTION    (',dateTime,')   ---------------------------------------------------------------------------'])
    %python motioncorrect.py [01_Raw_DICOM folder path]
    doMotionCorrection = 1; %default
    %check that nifti folder exists
    if ~(exist(subject_folderNIFTI,'dir')==7);  error('Missing nifti folder in Subject folder'); end
    
    %check whether code was already run successfully or not
    if exist(subject_folderMoco,'dir')==7;  disp('You may have run the MoCo code before (moco folder detected). What to do?'); 
        disp('2. Skip (recommended)');
            beep; answer4 = input('3. Escape ');
            switch answer4
                case {1} % delete moco folder
                    rmdir('04A_MoCo','s');
                case {2} %dont go, move to next step
                    doMotionCorrection = 0;
                    disp('Skipped');
                case {3} %escape
                    error('Voluntary interruption')
                otherwise
                error('Answer not understood')
            end            
    end
    if doMotionCorrection==1
        disp(['Creating MoCo folder and subfolders: ', mc_dir])
            [success, status]=mkdir(subject_folderMoco); if success; disp('Done');else error(status); end
            %the py program needs that subfolder in the root folder
            [success, status]=mkdir([subject_folderMoco,'/',mc_dir,'_nifti']); if success; disp('Done');else error(status); end 
            %it also needs this one to build a reference DICOM file
    %to do: LETS COPY ONLY EPI01 IN THAT DICOM
            [success, status]=mkdir([subject_folderMoco,'/',mc_dir,'_dicom']); if success; disp('Done');else error(status); end 
        disp('Copying nifti files to MoCo subfolders...')
            [success, status]=copyfile([subject_folderNIFTI,'/*'],[subject_folderMoco,'/',mc_dir,'_nifti']); if success; disp('Done');else error(status); end
            [success, status]=copyfile([subject_folderDICOM,'/*'],[subject_folderMoco,'/',mc_dir,'_dicom']); if success; disp('Done');else error(status); end
        disp('Starting motioncorrect_SP.py in:'); 
        if exist([preprocessPath, '/motioncorrect_SP.py'],'file')==2
            cd(preprocessPath) %if you have the file for updated motion correction, use it
            disp('Enhanced motion correction file motioncorrect_SP.py found in /Tools will be used.');
            disp('This will align all epi files to the middle volume of the middle epi.');
            disp('Press any key to continue. Cancel the process if you wish to use a different motion correction method.');
            beep; pause;
            disp('Starting...')
            success = system(['python motioncorrect_SP.py ', subject_folderMoco]);
        else 
            cd(preprocessPath) %otherwise use old version to align to epi01
            disp('Old motion correction file motioncorrect.py found Tools will be used.');
            disp('This will align all epi files to the first volume of epi01.');
            disp('Press any key to continue. Cancel the process if you wish to use a different motion correction method.');
            beep; pause;
            disp('Starting...')
            success = system(['python motioncorrect.py ', subject_folderMoco]);
        end 
        if success==0 %GOOD
                disp('python motioncorrect_SP.py: DONE');
        else %NOT GOOD
            error('python motioncorrect_SP.py: Something went wrong with last step')
        end
    end
    readMotionCorrectedParameters = 1;
    cleaning=1;
    %check whether code was already run successfully or not
    if exist([subject_folderMoco '/' mc_dir '_nifti'],'dir')==0;  disp('You may have run the MoCo cleaning code before (moco folder _nifti not detected). What to do?'); 
        disp('2. Skip (recommended)');
            beep; answer4 = input('3. Escape ');
            switch answer4
                case {2} %dont go, move to next step
                    readMotionCorrectedParameters = 0; cleaning=0;
                    disp('Skipped');
                case {3} %escape
                    error('Voluntary interruption')
                otherwise
                error('Answer not understood')
            end            
    end
    if readMotionCorrectedParameters==1
         % PROCESS MOTION PARAMETERS READING
                % Need to write voxel size to a .txt file for motionparams_SP_advanced.py to read in
                    disp('Writing parameters in voxelinfo.txt and brainDimsInfo.txt for correct reading of motion parameters')
                    first_epi_file = dir([subject_folderNIFTI '/epi01*']);
                    ni = readFileNifti([subject_folderNIFTI '/' first_epi_file.name]);
                    voxel_size = ni.pixdim(1:3);  
                    %if not retino, shoudl be reorder as x z y
                    if retino==0; voxel_size = voxel_size([1 3 2]); end
                    fileID = fopen([subject_folderMoco '/' mc_dir '_nifti/voxelinfo.txt'],'w');  fprintf(fileID,'%8.5f',voxel_size);
                    fclose(fileID);
                 % needs brain dimensions too
                    brainDims=ni.pixdim(1:3).*ni.dim(1:3);
                    fileID = fopen([subject_folderMoco '/' mc_dir '_nifti/brainDimsInfo.txt'],'w');fprintf(fileID,'%8.5f %8.5f %8.5f',brainDims);
                    fclose(fileID);
                disp('Please check the motion correction results...')
                cd(preprocessPath);
                if retino==0 %for normal scans, we use advanced motion param calculation assuming this is a whole brain
                    disp('Normal scan branch: we assume this is a whole brain scan and use averages - if this is too inacurate, modify code')
                    disp(' to use motionparams_SP instead or edit motionparams_SP_advanced with different brain average dimensions.')
                    success = system(['python motionparams_SP_advanced.py ', subject_folderMoco]);
                    %the code above will estimate motion parameters based
                    %on a worse case scenario of the translation occuring
                    %as a result of the rotations of the whole brain
                else %retinotopy branch
                    disp('Retino scan branch: we use advanced code that consider the whole scan volume to estimate motion parameters.')
                    disp('To work that way, it needs to find a file called brainDimsInfo with the dimensions of the volume in mm')
                    success = system(['python motionparams_SP_advanced.py ', subject_folderMoco]);
                end
                if success==0 %GOOD
                    disp('python motionparams_SP.py: DONE')
                    beep; answer5 = input('Figure: Is everything OK? (y)es / (n)o: ', 's');
                    if strcmpi(answer5, 'n')==1; error('Something went wrong, according to you...');end
                else %NOT GOOD
                    error('python motionparams_SP.py: Something went wrong with last step')
                end
    end
    % CLEANING FILES 
    if cleaning==1
        disp('Moving files back to moco root folder...')
                [success, status]=copyfile([subject_folderMoco,'/',mc_dir,'_nifti/*'],subject_folderMoco); if success; disp('Done');else error(status); end
        disp('Deleting old folders...')
                [success, status]=rmdir([subject_folderMoco,'/',mc_dir,'_nifti'],'s'); if success; disp('Done');else error(status); end
                [success, status]=rmdir([subject_folderMoco,'/',mc_dir,'_dicom'],'s'); if success; disp('Done');else error(status); end

        %CHECK SUCCESS here (presence of MCF FILES)
        %for that, find any file that matches ('*_mcf.nii.gz')
            cd(subject_folderMoco);
            [match,dummy] =  regexp(ls,'epi+\w+_mcf\.nii\.gz','match','split');%find all nii.gz files containing word mcf
            if isempty(match)==0; disp('Motion correction seems successful: mcf files detected.'); else error('Unsuccessful motion correction'); end
       disp('Finished MOTION CORRECTION')
    end
    
    disp(['---------      04B  MOTION CORRECTION CHECK   (',dateTime,')   ---------------------------------------------------------------------------'])
    doMotionCorrectionCheck = 1; %default
    %check that nifti folder exists
    if ~(exist(subject_folderMoco,'dir')==7);  error('Missing Moco folder in Subject folder'); end
    
    %check whether code was already run successfully or not
    if exist(subject_folderMocoCheck,'dir')==7;  disp('You may have run the MoCo Check test code before (moco check folder detected). What to do?'); 
        disp('1. Start this step over (delete existing 04B folder)');
        disp('2. Skip (recommended)');
            beep; answer6 = input('3. Escape ');
            switch answer6
                case {1} %delete subject_folderMocoCheck
                    %added because deleting this folder manually everytime
                    %i wanted to redo this step during debugging was very
                    %annoying -- Sara Popham
                    %ERROR HERE - [success, status]=rmdir([subject_folderMocoCheck,'/',mocoCheckFolder,'_nifti'],'s'); if success; disp('Deleted');else error(status); end
                    [success, status]=rmdir(subject_folderMocoCheck,'s'); if success; disp('Deleted');else error(status); end
                case {2} %dont go, move to next step
                    doMotionCorrectionCheck = 0;
                    disp('Skipped');
                case {3} %escape
                    error('Voluntary interruption')
                otherwise
                error('Answer not understood')
            end            
    end
    
    if doMotionCorrectionCheck==1
        disp(['Creating MoCo Check folder and subfolders: ', mc_ck_dir])
            [success, status]=mkdir(subject_folderMocoCheck); if success; disp('Done');else error(status); end
            %the py program needs that subfolder in the root folder
            [success, status]=mkdir([subject_folderMocoCheck,'/',mc_ck_dir,'_nifti']); if success; disp('Done');else error(status); end 
            [success, status]=mkdir([subject_folderMocoCheck,'/',mc_ck_dir,'_dicom']); if success; disp('Done');else error(status); end 
        disp('Copying nifti files to MoCo check subfolders...')
            [success, status]=copyfile([subject_folderMoco,'/*_mcf.nii.gz'],[subject_folderMocoCheck,'/',mc_ck_dir,'_nifti']); if success; disp('Done');else error(status); end
            [success, status]=copyfile([subject_folderDICOM,'/epi*'],[subject_folderMocoCheck,'/',mc_ck_dir,'_dicom']); if success; disp('Done');else error(status); end
        %rename epi_whatever to epi_whatever_mcf
        epiFolders = dir([subject_folderMocoCheck,'/',mc_ck_dir,'_dicom/epi*']);
        for i=1:length(epiFolders)
            movefile([subject_folderMocoCheck,'/',mc_ck_dir,'_dicom/',epiFolders(i).name],[subject_folderMocoCheck,'/',mc_ck_dir,'_dicom/',epiFolders(i).name,'_mcf']);
        end
            disp('Motion correction check: Starting motioncorrect_SP.py in:');
        if exist([preprocessPath '/motioncorrect_SP.py'],'file')==2
            cd(preprocessPath); %if you have the file for updated motion correction, use it
            disp('Updated motion correction file found and will be used.');
            disp('This will align all epi files to the middle volume of the middle epi.');
            disp('Press any key to continue. Cancel the process if you wish to use a different motion correction method.');
            beep; pause;
            disp('Starting...')
            success = system(['python motioncorrect_SP.py ', subject_folderMocoCheck]); 
        else 
            cd(preprocessPath); %otherwise use old version to align to epi01
            disp('Old motion correction file found and will be used.');
            disp('This will align all epi files to the first volume of the first epi.');
            disp('Press any key to continue. Cancel the process if you wish to use a different motion correction method.');
            beep; pause;
            disp('Starting...')
            success = system(['python motioncorrect.py ', subject_folderMocoCheck]); 
        end  
        if success==0 %GOOD
               disp('python motioncorrect_SP.py: DONE'); 
                   % CHECK PARAMS HERE
                disp('Retrieve info files')
                [success, status] = copyfile([subject_folderMoco '/voxelinfo.txt'],[subject_folderMocoCheck '/' mc_ck_dir '_nifti/voxelinfo.txt']);
                if success; disp('voxelinfo.txt file copied...');else error(status); end
                [success, status] = copyfile([subject_folderMoco '/brainDimsInfo.txt'],[subject_folderMocoCheck '/' mc_ck_dir '_nifti/brainDimsInfo.txt']);
                if success; disp('brainDimsInfo.txt file copied...');else error(status); end
                disp('Please check the motion correction results...')
                if retino==0 %for normal scans, we use advanced motion param calculation assuming this is a whole brain
                    disp('Normal scan branch: we assume this is a whole brain scan and use averages - if this is too inacurate, modify code')
                    disp(' to use motionparams_SP instead or edit motionparams_SP_advanced with different brain average dimensions.')
                    success = system(['python motionparams_SP_advanced.py ', subject_folderMocoCheck]);
                    %the code above will estimate motion parameters based
                    %on a worse case scenario of the translation occuring
                    %as a result of the rotations of the whole brain
                else %retinotopy branch
                    disp('Retino scan branch: we use advanced code that consider the whole scan volume to estimate motion parameters.')
                    disp('To work that way, it needs to find a file called brainDimsInfo with the dimensions of the volume in mm')
                    success = system(['python motionparams_SP_advanced.py ', subject_folderMocoCheck]);
                end
                if success==0 %GOOD
                    disp('python motionparams_SP.py: DONE')
                    beep; answer7 = input('Figure: Is everything OK? (y)es / (n)o: ', 's');
                    if strcmpi(answer7, 'n')==1; error('Something went wrong, according to you...');end
                else %NOT GOOD
                    error('python motionparams_SP_advanced.py: Something went wrong with last step')
                end
        else %NOT GOOD
            error('python motionparams_SP_advanced.py: Something went wrong with last step')
        end
        disp('Moving files back to mococheck root folder...')
                [success, status]=copyfile([subject_folderMocoCheck,'/',mc_ck_dir,'_nifti/*'],subject_folderMocoCheck); if success; disp('Done');else error(status); end
        disp('Deleting old folders...')
                [success, status]=rmdir([subject_folderMocoCheck,'/',mc_ck_dir,'_nifti'],'s'); if success; disp('Done');else error(status); end
                [success, status]=rmdir([subject_folderMocoCheck,'/',mc_ck_dir,'_dicom'],'s'); if success; disp('Done');else error(status); end

        %CHECK SUCCESS here (presence of MCF_MCF FILES)
        %for that, find any file that matches ('*mcf_mcf.nii.gz')
            cd(subject_folderMocoCheck);
            [match,dummy] =  regexp(ls,'epi+\w+mcf_mcf\.nii\.gz','match','split');%find all nii.gz files containing word mcf
            if isempty(match)==0; disp('Motion correction check seems successful: mcf files detected.'); else error('Unsuccessful motion correction check'); end
       disp('Finished MOTION CORRECTION CHECK')
    end
    
    disp(['---------     05    RENAMING 1 / FIX NIFTI HEADERS  (',dateTime,')     ------------------------------------------------------------'])
        renaming1 = 1; %default
        %check that nifti folder exists
            if ~(exist(subject_folderNIFTI,'dir')==7);  error('Missing nifti folder in Subject folder'); end
            if ~(exist(subject_folderMoco,'dir')==7);  error('Missing moco folder in Subject folder'); end
            
            %check whether code was already run successfully or not
            if exist(subject_folderNiftiFx,'dir')==7;  disp('You may have run the renaming 1 / nifti fix code before (niftiFixedFolder detected). What to do?'); 
                disp('2. Skip (recommended)');
                    beep; answer8 = input('3. Escape ');
                    switch answer8
                        case {2} %dont go, move to next step
                            renaming1 = 0;
                            disp('Skipped');
                        case {3} %escape
                            error('Voluntary interruption')
                        otherwise
                            error('Answer not understood')
                    end            
            end
        if renaming1==1
            disp(['Creating ',nii_fix_dir,' folder...'])
                [success, status]=mkdir(subject_folderNiftiFx); if success; disp('Done');else error(status); end               
            disp(['Copying moco nifti files to : ',nii_fix_dir])
                cd(subject_folderMoco);
                [match,dummy] =  regexp(ls,'epi+\w+_mcf\.nii\.gz','match','split');%find all nii.gz files containing word mcf
                for i=1:numel(match)
                   [success, status]=copyfile(match{i},subject_folderNiftiFx); if success; disp('Done');else error(status); end
                end
            disp(['Copying gems and mprage from nifti folder to: ',nii_fix_dir])
                cd(subject_folderNIFTI);
                [matchMPRAGE,dummy] =  regexp(ls,'^((?<![co])\w*)mprage\w*\.nii\.gz','match','split'); %find all nii.gz files containing word mprage except ones starting by co and o
                [matchGEMS,dummy] =  regexp(ls,'gems\w*\.nii\.gz','match','split'); %find all nii.gz files containing word gems
                for i=1:numel(matchMPRAGE)
                       [success, status]=copyfile(matchMPRAGE{i},subject_folderNiftiFx); if success; disp('Done');else error(status); end
                end
                for i=1:numel(matchGEMS)
                       [success, status]=copyfile(matchGEMS{i},subject_folderNiftiFx); if success; disp('Done');else error(status); end
                end
             disp('Renaming mprage file to mprage.nii.gz')
                      cd(subject_folderNiftiFx);
                     if numel(matchMPRAGE)>1
                         error('More than one mprage file found...')
                     else
                         [success, status]=movefile(matchMPRAGE{1},'mprage.nii.gz'); if success; disp('Done');else error(status); end
                     end
             disp('Renaming gems* file to gems.nii.gz')
                  cd(subject_folderNiftiFx);
                 if numel(matchGEMS)>1
                     error('More than one gems file found...')
                 else
                     if strcmpi(matchGEMS{1},'gems.nii.gz')==0
                        [success, status]=movefile(matchGEMS{1},'gems.nii.gz'); if success; disp('Done');else error(status); end
                     else
                        disp('Gems file is already called gems.nii.gz.')
                     end
                 end
        
            % FIX HEADERS
                if retino==0
                    disp('Normal scan branch: we will use niftiFixHeader3')
                else
                    disp('Retinotopy scan branch: we will use niftiFixHeader3_retino')
                end
                 %beep; answer = input('Have you edited that code for your needs? (y)es/(n)o: ','s');
                 %if strcmpi(answer,'n'); error('Please proceed and edit the code before fixing headers...');end
            doFixHeaders = 1; %default
            %check whether code was already run successfully or not
                cd(subject_folderNiftiFx)
                if exist('epiHeaders_FIXED.txt','file')==2;  disp('CAREFUL: You may have run the -fixing header- code before on these same files (epiHeaders_FIXED.txt detected). What to do?'); 
                    disp('1. Do it again (first remove epiHeaders_FIXED.txt file)');
                    disp('2. Skip (recommended)');
                        beep; answer9 = input('3. Escape ');
                        switch answer9
                            case {1} %move on
                                delete('epiHeaders_FIXED.txt');
                            case {2} %dont go, move to next step
                                doFixHeaders = 0;
                                disp('Skipped');
                            case {3} %escape
                                error('Voluntary interruption')
                            otherwise
                                error('Answer not understood')
                        end            
                end
            if doFixHeaders == 1
                 disp('Fixing headers')
                    if retino==0
                        niftiFixHeader3(subject_folderNiftiFx);
                    else
                        niftiFixHeader3_retino(subject_folderNiftiFx);
                    end
                    if exist('epiHeaders_FIXED.txt','file')==2
                        disp('Header fixing was successful.')
                    else
                        error('Some files could not be fixed')
                    end
                    disp('Take some time here to check that the headers are all OK (freq_dim/phase_dim/slice_duration should not be OK for gems/mprage). TR should be correct too. Press any key if yes.'); beep; pause;
            end
        end
  
      disp(['---------     06   Start of mrVista session   (',dateTime,')    -------------------------------------------------------------------'])
       doMrVista = 1; %default
       %check that nifti folder exists
            if retino==0
                if ~(exist(subject_folderPAR,'dir')==7);  error('Missing PAR folder in Subject folder (for par files)'); end
            end
            if ~(exist(subject_folderNiftiFx,'dir')==7);  error('Missing fixed nifti folder in Subject folder'); end
            
            %check whether code was already run successfully or not
            if exist([subject_folderVista,'/Inplane'],'dir')==7;  disp('You may have run the mrVista code before (subject_folderVista/Inplane detected). What to do?'); 
                disp('2. Skip (recommended)');
                    beep; answer10 = input('3. Escape ');
                    switch answer10
                        case {2} %dont go, move to next step
                            doMrVista = 0;
                            disp('Skipped');
                        case {3} %escape
                            error('Voluntary interruption')
                        otherwise
                            error('Answer not understood')
                    end            
            end
       if doMrVista == 1
           disp('Creating nifti folder, for epi, gems, and mprage')
                [success, status]=mkdir([subject_folderVista,'/nifti']); if success; disp('Done');else error(status); end
           disp('Creating Parfiles folder, for par files')
                [success, status]=mkdir([subject_folderVista,'/Stimuli/Parfiles']); if success; disp('Done');else error(status); end
           
           disp('Copying files to nifti and Parfiles subfolders')
               cd(subject_folderNiftiFx);
               [match,dummy] =  regexp(ls,'\w+\.nii\.gz','match','split');%find all nii.gz files
               for i=1:numel(match)
                       [success, status]=copyfile(match{i},[subject_folderVista,'/nifti']); if success; disp('Done');else error(status); end
               end
            if retino==0
                    cd(subject_folderPAR);
                    for i=1:numel(match)
                       [success, status]=copyfile('*',[subject_folderVista,'/Stimuli/Parfiles']); if success; disp('Done');else error(status); end
                    end
            else
               disp('Retino scan branch - skipping PAR files')
            end
           disp('Running adapted Kelly/Winaver code to inialize a mrVista session...')
           if retino==0
                kb_initializeVista2(subject_folderVista, subj)
           else
               disp('Retino branch - we use a specific code for that branch')
               kb_initializeVista2_retino(subject_folderVista, subj)
           end
           disp('Lets check that...') %the success of initialization
                cd(subject_folderVista);
                if exist('mrSESSION.mat','file')==2 && exist('mrSESSION_backup.mat','file')==2 && exist('mrInit_params.mat','file')==2 
                    disp('Success confirmed')
                else
                    error('Some files/folders are missing')
                end
       end
 

    
disp(['***********       PIPELINE FINISHED  AT  ', dateTime,' for subjectID ', subj,'       *******************'])
beep;
