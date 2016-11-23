function pipeline_JAS(steps, subj_dir, subjID, notes_dir, verbose)
% ------------------------------------------------------------------------
% Automated fMRI analysis pipeline for mrVista analysis
% pipeline_JAS(stepList2run, subj_dir, subjID, notes_dir, verbose)
%
% stepList2run is a list of numbers corresponding to the possible steps to
% run. If stepList2run is not defined, it shows this help.
%
% Steps available to run:
%   0. All of the below steps
%   1. mprage: nifti conversion
%   2. mprage: segmentation using FSL
%   3. mprage: correction of gray mesh irregularities
%   4. mprage: nifti header repair
%   5. retino epi/gems: nifti conversion and removal of ''pRF dummy'' frames
%   6. retino epi/gems: motion correction
%   7. retino epi: MC parameter check and artefact removal
%   8. retino epi/gems: nifti header repair
%   9. retino epi/gems: initialization of mrVista session
%   10. retino epi/gems: alignment of inplane and volume
%   11. retino epi: segmentation installation
%   12. retino/epi: mesh creation
%   13. retino epi: pRF model
%   14. retino epi: mesh visualization of pRF values
%   15. retino epi: extraction of flat projections
%   16. exp epi/gems: nifti conversion
%   17. exp epi/gems: motion correction
%   18. exp epi: artefact removal and MC parameter check
%   19: exp epi/gems: nifti header repair
%   20. exp epi/gems: initialization of mrVista session
%   21. exp epi/gems: alignment of inplane and volume
%   22. exp epi: segmentation installation
%   23. exp epi: mesh creation
%   24. exp epi: GLM sanity check
%   25. exp epi: actual GLM model
%   25. exp epi: mesh visualization
%
% Other inputs:
% - subj_dir: directory path for subject analysis (string) - root of all
%   other folders for that subject
% - subjID: subject id (string, if not provided will take the name of the subject folder)
% - notes_dir: [optional] directory path to save command output (string),
%   default is subj_ID_date_pipeline
% - verbose: if verbose = verboseOFF, none of the disp function will give an
%   ouput (default is verboseON)
% ------------------------------------------------------------------------

% ------------------------------------------------------------------------
% Written Nov 2016
% Justin Theiss and Adrien Chopin
% Legacy Adrien Chopin, Sara Popham late Aug 2015
% From the work made by Eunice Yang, Rachel Denison, Kelly Byrne, Summer
% Sheremata
% ------------------------------------------------------------------------------------------------------------

try
% ---------- INITIALIZATION --------------------------------------------------------------------------------------------------
    % if no args, display help
    if nargin==0, help(mfilename); return; end;
    %if verbose is set to verboseOFF, it will mute all dispi functions.
    if exist('verbose', 'var')==0; verbose='verboseON'; end
    %check for subj_dir
    if ~exist('subj_dir','var')||~exist(subj_dir, 'dir'), 
        subj_dir = uigetdir(pwd, 'Choose folder for analysis:'); 
    end;
    %check for subjID
    if ~exist('subjID','var'), [~, subjID] = fileparts(subj_dir); end;
    %check for notes_dir
    if exist('notes_dir','var') 
        % creates notes_dir if necessary and start diary
        check_exist(notes_dir, verbose);
        record_notes(notes_dir, 'pipeline_JAS');
    end
    
    % display inputs
    dispi(mfilename,'\nsteps: ',steps,'\nsubj_dir: ',subj_dir,...
        '\nsubjID: ',subjID,'\nnotes_dir: ',notes_dir,verbose);
    
    % display start time
    dispi(repmat('-',1,40),' Start of pipeline initialization ',repmat('-',1,40),verbose);
    dispi(dateTime, verbose);
    
    %load subject parameters
    if exist(fullfile(subj_dir,[subjID,'_params.mat']), 'file'),
        load(fullfile(subj_dir,[subjID,'_params.mat']));
    else % set default params
        params = create_params;
    end
    dispi('Current expected parameters are:\n', params, verbose);
    
    % MENU
    if ~exist('steps', 'var'),
        help(mfilename);
        steps = str2double(cell2mat(inputdlg('Enter steps to run: ')));
        if isnan(steps), warning_error('Steps must be numbers','errorON',verbose); end;
    end
    % set 0 to all steps
    if steps==0, steps = 1:12; end; 
    dispi('Steps to run: ',steps, verbose)
    
    % get parameters from params
    fields = fieldnames(params);
    values = struct2cell(params);
    
    % set values as variable called fields
    for x = 1:numel(fields), assignin('caller',fields{x},values{x}); end;
    
    % Default Conventions
    fields = {'mprage_dicom','mprage_nifti','mprage_seg','mprage_niftiFixed',...
        'retino_dicom','retino_nifti','retino_moco','retino_niftiFixed',...
        'retino_mrSession','exp_dicom','exp_par','exp_nifti','exp_moco',...
        'exp_niftiFixed','exp_mrSession','retino_mr_nifti','retino_mesh',...
        'gemsFile','mprageFile'};
    values = fullfiel(subj_dir, {'01a_mprage_DICOM','02_mprage_nifti',...
        '03_mprage_segmented','04_mprage_nifti_fixed','01b_epi_retino_DICOM',...
        '03_retino_nifti','04_retino_MC','05_retino_nifti_fixed','06_retino_mrSession'});
    values = [values, fullfile(retino_mrSession, {'nifti', 'Mesh'})];
    values = {values, 'gems_retino.nii.gz', 'mprage_nu_RAS_NoRS.nii.gz'};
        
        expDICOMfolder = fullfile(subj_dir,'01c_epi_exp_DICOM');
        expPARfolder = fullfile(subj_dir,'01d_epi_exp_PAR');
        expNiftiFolder = fullfile(subj_dir,'03_exp_nifti');
        expMCfolder = fullfile(subj_dir,'04_exp_MC');
        expNiftiFixedFolder = fullfile(subj_dir,'05_exp_nifti_fixed');
        expMrSessionFolder = fullfile(subj_dir,'06_exp_mrSession');
    
    dispi(repmat('-',1,40),' End of pipeline initialization ',repmat('-',1,40),verbose);
% ---------- PIPELINE STEPS -----------------------------------------------
    dispi('Start to run pipeline steps', verbose)
    for step=steps
        dispi('Step: ',step,verbose);
        switch step
            case {1} % 1. mprage: nifti conversion
                % basic checks
                dispi('Starting nifti conversion with dcm2niix from ',mprage_dcm_dir,' to ',mprage_ni_dir,verbose);
                dispi('Checking that source folders exist for that step', verbose);
                check_exist(mprage_dcm_dir, 'errorON', verbose); 
                check_exist(mprage_dcm_dir,'*.dcm', mprage_slc_n, 1, verbose); 
                remove_previous(mprage_nifti, verbose);
                dispi('Checking folder was correctly removed and creates a new one',verbose);
                check_exist(mprage_nifti, verbose);
                % run dcm2nii (with gzip option and set filename to mprage)
                loop_system('dcm2niix','-z y', '-f mprage','-o',['"',mprage_ni_dir,'"'],['"',mprage_dcm_dir,'"'],verbose);
                check_exist(mprage_ni_dir,'*.nii.gz', 1, 'errorON', verbose);
                dispi(repmat('-',1,40),' End of mprage nitfi conversion ',repmat('-',1,40),verbose);
                
           case {2} % 2. mprage: segmentation using freesurfer
               % basic checks
               dispi('Starting freesurfer segmentation from ',mprage_ni_dir,' to ',mprage_seg,verbose);
               dispi('Checking that source folders exist for that step', verbose);
               check_exist(mprage_ni_dir, 'errorON', verbose);
               check_exist(mprage_ni_dir, '*mprage*.nii.gz', 1, 'errorON', verbose); 
               remove_previous(mprage_seg, verbose);
               dispi('Checking folder was correctly removed and creates a new one', verbose);
               check_exist(mprage_seg, verbose);
               % run segmentation
               segmentation(subjID, mprage_ni_dir,mprage_seg, verbose);
               dispi(repmat('-',1,40),' End of segmentation ',repmat('-',1,40),verbose);
                 
           case {3} % 3. mprage: correction of gray mesh irregularities
                dispi('mprage: correction of gray mesh irregularities not implemented yet', verbose);
                dispi('This step has to be done manually on a Windows computer with itkGray/itkSnap', verbose);
                dispi(repmat('-',1,40), verbose);
                
           case {4} % 4. mprage: fix nifti header
                 % basic checks
                 dispi('Starting repair of nifti headers from ',mprage_seg, ' to ', mprage_niftiFixed, verbose);
                 dispi('Checking that source folders exist for that step', verbose);
                 check_exist(mprage_seg, 'errorON', verbose);
                 check_files(mprage_seg,'*nu_RAS_NoRS*.nii.gz', 1, 'errorON', verbose); 
                 remove_previous(mprage_niftiFixed, verbose);
                 dispi('Checking folder was correctly removed and creates a new one', verbose);
                 check_folder(mprage_niftiFixed,0, verbose);
                 copy_files(mprage_seg, '*nu_RAS_NoRS*.nii.gz', mprage_niftiFixed, verbose) %copy all nifti mprage files
                 check_files(mprage_niftiFixed,'*nu_RAS_NoRS*.nii.gz', 1, 1, verbose); %looking for 1 mprage nifti file
                 niftiFixHeader3(mprage_niftiFixed)
                 check_files(mprage_niftiFixed,'epiHeaders_FIXED.txt', 1, 1, verbose); %looking for 1 txt file called epiHeaders_FIXED
                 dispi(' --------------------------  End of nitfi repair for mprage  ----------------------------------------', verbose)
                
            case {5}     %   5. retino epi/gems: nifti conversion and removal of ''pRF dummy'' frames
                dispi(' -------  ',step, '. retino epi/gems: nifti conversion and removal of ''pRF dummy'' frames', verbose)
                %basic checks
                dispi(' -------  Starting nifti conversion with dcm2niix from ',retino_dicom, ' to  ', retino_nifti, verbose)
                dispi('For each epi and gems, DICOM should be in separate folders inside ',retino_dicom, ' in the subject root folder',verbose)
                dispi('Each epi folder should contain the word epi in the name and each gems should contain gems.', verbose)
                dispi('Check that source folders exist for that step', verbose)
                check_folder(retino_dicom, 1, verbose); %check that DICOM folder exists
                epiFolders = list_folders(retino_dicom, '*epi*', 1); %detects nomber of epi folders
                nbOfDetectedEpi=numel(epiFolders); %check whether number of EPI matches with what we expect
                if nbOfDetectedEpi==param.retinoEpiNb, dispi(nbOfDetectedEpi,'/',param.retinoEpiNb,' epis correctly detected', verbose); 
                     else  warni(nbOfDetectedEpi,'/',param.retinoEpiNb,' epis detected: incorrect number', verbose); end
                for i=1:nbOfDetectedEpi  %check that we have the correct number of dcm files in each folder
                     check_files(epiFolders{i},'*.dcm', param.retinoEpiTRNb, 0, verbose); %looking for the expected nb of dcm files
                end
                gemsFolders = list_folders(retino_dicom, '*gems*', 1); %detects nomber of gems folders
                nbOfDetectedGems=numel(gemsFolders); %checks that it matches what we expect
                if nbOfDetectedGems==param.retinoGemsNb, dispi(nbOfDetectedGems,'/',param.retinoGemsNb,' gems correctly detected', verbose); 
                     else  warni(nbOfDetectedGems,'/',param.retinoGemsNb,' gems detected: incorrect number', verbose); end
                for i=1:nbOfDetectedGems  %check that we have the correct number of dcm files in gem folder
                     check_files(gemsFolders{i},'*.dcm', param.retinoGemsSliceNb, 0, verbose); %looking for the expected nb of dcm files
                end
                remove_previous(retino_nifti, verbose); %remove older runs of that code
                disp('Check that potential folder was correctly removed and creates a new one (will issue a benine warning)')
                check_folder(retino_nifti,0, verbose); %check we have an output nifit folder or creates it
                success = system(['dcm2niix -z y -s n -t y -x n -v n -f "%p%s" -o "', retino_nifti, '" "', retino_dicom,'"']);
                %at the moment, it uses the %p to rename the output files so that we have the gems, epi, mprage names in the files.
                %However, if one uses different names in the dicom  sequences, all names will be incorrect for the next steps (we already have trouble
                % with some called ep2d instead of epi)
                check_files(retino_nifti,'*epi*.nii.gz', nbOfDetectedEpi, 1, verbose);
                check_files(retino_nifti,'*gems*.nii.gz', nbOfDetectedGems, 1, verbose);
                dispi(' --------------------------  End of retino epi nitfi conversion  ----------------------------------------', verbose)
                dispi(' --------------------------  Removing dummy pRF frames  ----------------------------------------', verbose)
                listConvertedEPI=list_files(retino_nifti, '*epi*.nii.gz', 1);
                for i=1:numel(listConvertedEPI)
                    remove_frames(listConvertedEPI{i}, param.pRFdummyFramesNb, verbose)
                end  
                dispi(' --------------------------  End of removing dummy pRF TR for epi ----------------------------------------', verbose)
                
            case {6}    %   6. retino epi/gems: motion correction 
                dispi(' ---------------  ',step, '. retino epi/gems: motion correction ------------------------', verbose)
                %basic checks
                dispi(' ------- from ',retino_nifti, ' to  ', retino_moco, verbose)
                dispi('nifti header-fixed epi files (and only them) should be in a folder called ',retino_nifti, verbose)
                dispi('Check that source folders exist for that step', verbose)
                check_folder(retino_nifti, 1, verbose);
                remove_previous(retino_moco, verbose);
                dispi('Check that potential folder was correctly removed and creates a new one (will issue a benine warning)', verbose)
                check_folder(retino_moco, 0, verbose);
                copy_files(retino_nifti, '*.nii.gz', retino_moco, verbose) %copy all nifti files to MC folder
                dispi('Check that we have all our nifti files in MC folder', verbose)
                [~, nbFiles]=check_files(retino_moco,'*.nii.gz', param.retinoEpiNb+param.retinoGemsNb, 0, verbose); %we know we have nbFiles now
                
%                 motion_correction(retinoMCfolder, '*epi*.nii.gz', 'reffile') %motion correct the epi first
%                   %ref volume which should be the newly created ref_vol.nii.gz
%                 motion_correction(retinoMCfolder, '*gems*.nii.gz', 'reffile',fullfile(retinoMCfolder,'ref_vol.nii.gz'),1) %motion correct the gems second, using the same 
                
                dispi('We want mcFLIRT to motion correct the epis to the higher resolution GEMS') 
                dispi('To avoid mcFLIRT resampling the epi to this higher resolution, we will first resample the GEMS with the EPI resolution')
                gemsFile = list_files(retino_moco, '*gems*.nii.gz', 1);
                epis = list_files(retino_moco, '*epi*.nii.gz', 1);
                
                gemsFileRef=fullfile(retino_moco,'gemsRef.nii.gz');
                %gemsFileRef=fullfile(subj_dir,'gems90x90.nii.gz');
                fslresample(gemsFile,gemsFileRef, '-ref', epis{1}, verbose)
                

                %motion correct the epi to the higher resolution gems (as a ref file)
                dispi('Motion-correcting all epis to the gems reference file: ', gemsFileRef, verbose);
                motion_correction(retino_moco, '*epi*.nii.gz', {'reffile', gemsFileRef, 1}, '-plots','-report','-cost mutualinfo','-smooth 16',verbose) 

                dispi('Check that we have all our MC files in MC folder', verbose)
                check_files(retino_moco,'*_mcf.nii.gz', nbFiles-1, 1, verbose); %should be nb of epi -1 bc we do not correct our gems
                check_files(retino_moco,'*_mcf.par', nbFiles-1, 1, verbose);
                dispi('Deleting the downsampled gems reference file', verbose)
                delete(gemsFileRef)
               dispi(' --------------------------  retino epi/gems: end of motion correction  ----------------------------------------', verbose)
               
          case {7}   %   7. retino epi: MC parameter check and artefact removal
                dispi(' -------  ',step, '. retino epi: MC parameter check and artefact removal', verbose)
                
                %bad_trs = motion_parameters(retinoMCfolder);
                %dispi('Suspicious TR detected     EPI   TR', verbose)
                %disp(bad_trs)
                
                dispi(' Nifti should be in folder :', retino_nifti)
                dispi('Check that source folders exist for that step', verbose)
                check_folder(retino_nifti, 1, verbose);
                dispi('Removing potential previous files for motion parameters')
                listConfounds=list_files(retino_nifti, '*confound*', 1);
                if numel(listConfounds)>0; dispi('Found ', numel(listConfounds),' confound files that are deleted now', verbose); delete(listConfounds{:}); end
                dispi('Using motion_outliers code from FSL for detecting artefacts', verbose)
                bad_trs=motion_outliers(retino_nifti, '-p', fullfile(retino_nifti,'motion_params.png'), '--dvars');
                dispi('Suspicious TR detected are:', verbose)
                disp(bad_trs)
                %TO DO HERE
                %Let's move all confounds files and images to a different
                %folder for clarity  
                dispi(' --------------------------  retino epi: end of motion param checks  ----------------------------------------', verbose)
                
          case {8} %8. retino epi/gems: nifti header repair
                dispi(' ------- --- ',step, '. retino epi/gems: nifti header repair --------------------', verbose)
                dispi('Check that source folders exist for that step', verbose)
                check_folder(retino_moco, 1, verbose);
                remove_previous(retino_niftiFixed, verbose);
                disp('Check that potential folder was correctly removed and creates a new one (will issue a benine warning)')
                check_folder(retino_niftiFixed, 0, verbose);
                [~, nbFiles]=check_files(retino_moco,'*_mcf.nii.gz', param.retinoEpiNb, 0, verbose); %we know we have nbFiles now
                disp('Copying')
                copy_files(retino_moco, '*_mcf.nii.gz', retino_niftiFixed, verbose) %copy all mcf nifti files to nifti fixed folder
                copy_files(retino_moco, '*gems*', retino_niftiFixed, verbose) %copy all gems files too to nifti fixed folder
                check_files(retino_niftiFixed,'*.nii.gz', nbFiles+1, 1, verbose); %should include all epi copied files + gems
                niftiFixHeader3(retino_niftiFixed)
                dispi(' --------------------------  retino epi/gems: end of nifti header repair ----------------------------------------', verbose)

         case {9}  %   9. retino epi/gems: initialization of mrVista session
                dispi(' -----------------  ',step, '. retino epi/gems: initialization of mrVista session ------------------------------', verbose) 
                dispi('Check that source folders exist for that step', verbose)
                check_folder(retino_niftiFixed, 1, verbose);
                check_folder(mprage_niftiFixed, 1, verbose);
                dispi('Check that headers are corrected')
                check_files(mprage_niftiFixed,'epiHeaders_FIXED.txt', 1, 1, verbose); %looking for 1 txt file called epiHeaders_FIXED
                check_files(retino_niftiFixed,'epiHeaders_FIXED.txt', 1, 1, verbose); %looking for 1 txt file called epiHeaders_FIXED
                remove_previous(retino_mrSession, verbose);
                dispi('Check that potential folder was correctly removed and creates a new one (will issue a benine warning)', verbose)
                check_folder(retino_mrSession, 0, verbose);
                check_folder(retino_mr_nifti, 0, verbose);
                copy_files(retino_niftiFixed, '*epi*mcf*.nii.gz', retino_mr_nifti, verbose) %copy mcf nifti fixed epi to nifti mrvista folder
                copy_files(retino_niftiFixed, '*gems*.nii.gz', fullfile(retino_mr_nifti,gemsFile), verbose) %copy nifti fixed gems to nifti mrvista folder
                copy_files(mprage_niftiFixed, '*nu_RAS_NoRS*.nii.gz', fullfile(retino_mr_nifti,mprageFile), verbose) %copy nifti fixed mprage to nifti mrvista folder
                check_files(retino_mr_nifti,'*epi*mcf*.nii.gz', param.retinoEpiNb, 0, verbose); %looking for 1 txt file called epiHeaders_FIXED
                close all;
                init_session(retino_mrSession, retino_mr_nifti, 'inplane',fullfile(retino_mr_nifti,gemsFile),'functionals','*epi*mcf*.nii*','vAnatomy',fullfile(retino_mr_nifti,mprageFile),...
                    'sessionDir',retino_mrSession,'subject', subjID)%,'scanGroups', 1:param.retinoEpiNb)
                %alternative: kb_initializeVista2_retino(retinoMrSessionFolder, subjID)
                dispi(' --------------------------  retino epi: end of mrVista session initialization ----------------------------------------', verbose)
                
         case {10}  %   10. retino epi/gems: alignment of inplane and volume
                dispi(' --------------------  ',step, '. retino epi/gems: alignment of inplane and volume  ------------------------------', verbose) 
                dispi('Check that source folders exist for that step', verbose)
                check_folder(retino_mrSession, 1, verbose);
                check_folder(retino_dicom, 1, verbose);
                check_folder(retino_mr_nifti, 1, verbose);
                xform = alignment(retino_mrSession, fullfile(retino_mr_nifti,mprageFile), fullfile(retino_mr_nifti, gemsFile), fullfile(retino_dicom,'gems_retino_11'));
                dispi('Resulting xform matrix:',verbose)
                disp(xform)
                [averageCorr, sumRMSE]=extractAlignmentPerfStats(retino_mrSession, param.retinoGemsSliceNb, verbose);
                dispi(' --------------------------  retino epi: end of alignment volume/inplane  ----------------------------------------', verbose)
                
         case {11}  %   11. retino epi: segmentation installation
             dispi(' --------------------  ',step, '. retino epi/gems: install of segmentation  ------------------------------', verbose) 
             initialPath=cd;
             cd(retino_mrSession)
             install_segmentation(retino_mrSession, mprage_seg, retino_mr_nifti, verbose)
             cd(initialPath)
             dispi(' --------------------------  retino epi: end of install of segmentation  ----------------------------------------', verbose)
             
        case {12}  %   12. retino/epi: mesh creation
             dispi(' --------------------  ',step, '. retino/epi: mesh creation / inflating ------------------------------', verbose) 
             initialPath=cd;
             cd(retino_mrSession)
             remove_previous(retino_mesh, verbose);
             check_folder(retino_mrSession, 1, verbose);
             check_folder(retino_mesh, 0, verbose);
             create_mesh(retino_mesh, 600, verbose)
   %         create_mesh
             dispi('Checking for output mesh files in Mesh folder', verbose)
             check_files(retino_mesh, 'lh_pial.mat', 1, verbose);
             check_files(retino_mesh, 'rh_pial.mat', 1, verbose);
             check_files(retino_mesh, 'lh_inflated.mat', 1, verbose);
             check_files(retino_mesh, 'rh_inflated.mat', 1, verbose);
             cd(initialPath)
             dispi(' --------------------------  retino/epi: end of mesh creation / inflating ----------------------------------------', verbose)

            %   13. retino epi: pRF model
            %   14. retino epi: mesh visualization of pRF values
            %   15. retino epi: extraction of flat projections
            
         case {16}    % 16. Exp epi/gems: nifti conversion and fix of nifti headers
                dispi(' -------  ',step, '. Exp epi/gems: nifti conversion and fix of nifti headers', verbose)
                %basic checks
                dispi(' -------  Starting nifti conversion with dcm2niix from ',expDICOMfolder, ' to  ', expNiftiFolder, verbose)
                dispi('For each epi and gems, DICOM should be in separate folders inside ',expDICOMfolder, ' in the subject root folder',verbose)
                dispi('Each epi folder should contain the word epi in the name and each gems should contain gems.', verbose)
                dispi('Check that source folders exist for that step', verbose)
                check_folder(expDICOMfolder, 1, verbose); %check that DICOM folder exists
                epiFolders = list_folders(expDICOMfolder, '*epi*', 1); %detects nomber of epi folders
                nbOfDetectedEpi=numel(epiFolders); %check whether number of EPI matches with what we expect
                if nbOfDetectedEpi==param.expEpiNb, dispi(nbOfDetectedEpi,'/',param.expEpiNb,' epis correctly detected', verbose); 
                     else  warni(nbOfDetectedEpi,'/',param.expEpiNb,' epis detected: incorrect number', verbose); end
                for i=1:nbOfDetectedEpi  %check that we have the correct number of dcm files in each folder
                     check_files(epiFolders{i},'*.dcm', param.expEpiTRNb, 0, verbose); %looking for the expected nb of dcm files
                end
                gemsFolders = list_folders(expDICOMfolder, '*gems*', 1); %detects nomber of gems folders
                nbOfDetectedGems=numel(gemsFolders); %checks that it matches what we expect
                if nbOfDetectedGems==param.expGemsNb, dispi(nbOfDetectedGems,'/',param.expGemsNb,' gems correctly detected', verbose); 
                     else  warni(nbOfDetectedGems,'/',param.expGemsNb,' gems detected: incorrect number', verbose); end
                for i=1:nbOfDetectedGems  %check that we have the correct number of dcm files in gem folder
                     check_files(gemsFolders{i},'*.dcm', param.expGemsSliceNb, 0, verbose); %looking for the expected nb of dcm files
                end
                remove_previous(expNiftiFolder, verbose); %remove older runs of that code
                dispi('Check that potential folder was correctly removed and creates a new one (will issue a benine warning)', verbose)
                check_folder(expNiftiFolder,0, verbose); %check we have an output nifit folder or creates it
                success = system(['dcm2niix -z y -s n -t y -x n -v n -f "%p%s" -o "', expNiftiFolder, '" "', expDICOMfolder,'"']);
                %at the moment, it uses the %p to rename the output files so that we have the gems, epi, mprage names in the files.
                %However, if one uses different names in the dicom sequences, all names will be incorrect for the next steps
                check_files(expNiftiFolder,'*ep*.nii.gz', nbOfDetectedEpi, 1, verbose);
                check_files(expNiftiFolder,'*gems*.nii.gz', nbOfDetectedGems, 1, verbose);
                dispi(' --------------------------  End of exp epi nitfi conversion  ----------------------------------------', verbose)
                
            
            %   17. exp epi/gems: motion correction
            %   18. exp epi: artefact removal and MC parameter check


            case {19}% 19: exp epi/gems: nifti header repair
                dispi(' --------------------------  Fixing nifti headers for exp epi/gems----------------------------------------', verbose)
                dispi('Check that source folders exist for that step', verbose)
                check_folder(expNiftiFolder, 1, verbose); %check that DICOM folder exists
                niftiFixHeader3(expNiftiFolder)
                expectedFiles= nbOfDetectedEpi+nbOfDetectedGems;
                check_files(expNiftiFolder,'*.nii.gz', expectedFiles, 1, verbose);
                dispi(' --------------------------  End of nifti headers for exp epi/gems ----------------------------------------', verbose)
            
            %   20. exp epi/gems: initialization of mrVista session
            %   21. exp epi/gems: alignment of inplane and volume
            %   22. exp epi: segmentation installation
            %   23. exp epi: mesh creation
            %   24. exp epi: GLM sanity check
            %   25. exp epi: actual GLM model
            %   25. exp epi: mesh visualization
            otherwise
                dispi('Warning: this step is not recognized: ', step, verbose)
        end
    end
 
    dispi(' --------------------------  End of pipeline ',dateTime, ' -------------------------', verbose)
    record_notes('off');
catch err
    try
        %cd(subj_dir)
        save('errorLog', 'err')
        whos
        clear all
        load('errorLog', 'err')
        record_notes('off');
        rethrow(err);
    catch err2
        rethrow(err2);
    end
end
end

function local_startupchecks(step, verbose, varargin)
% display starting step
dispi('Starting ', step, verbose);


end
    
