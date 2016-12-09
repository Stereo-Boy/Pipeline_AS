function pipeline_JAS(stepList2run, subj_dir, subjID, notes_dir, verbose)
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
    if nargin==0
        help(mfilename);
        return;
    end

    %if verbose is set to verboseOFF, it will mute all dispi functions.
    if exist('verbose', 'var')==0; verbose='verboseON'; end
    dispi(' --------------------------  Start of pipeline initialization  ----------------------------------------', verbose)
    
    %check for subj_dir
    if ~exist('subj_dir','var')||~exist(subj_dir, 'dir'), 
        subj_dir = uigetdir(pwd, 'Choose folder for analysis:'); 
    end;
    
    cd(check_folder(subj_dir, 1, verbose));
    
    %check for subjID
    if ~exist('subjID','var'), [~, subjID] = fileparts(subj_dir); end;
    
    %check for notes_dir
    if exist('notes_dir','var') 
        % creates notes_dir if necessary and start diary
        record_notes(check_folder(notes_dir,0, verbose),'pipeline_JAS')
    end

    dispi(dateTime, verbose)
    dispi('Subject folder root is: ', subj_dir, verbose)
    dispi('Subject ID is: ', subjID, verbose)
    
    %load subject parameters
    success = check_files(subj_dir, 'expectedParametersForPipeline.m', 1, 0, verbose);
    if success==0, dispi('The parameter file expectedParametersForPipeline could not ',...
            'be found in the subject directory, where it should be. Template file might be used instead: ',parameterFile, verbose); end
    param=expectedParametersForPipeline(verbose);
    dispi('Current expected parameters are: ', verbose)
    disp(param)
    
    % MENU
    if exist('stepList2run', 'var')==0
        help(mfilename);
        stepList2run=input('Enter the numbers of the desired steps, potentially between brackets: ');
    end
    
    % CHECKS THAT steps are numbers
    if isnumeric(stepList2run)
        if stepList2run==0;            stepList2run=[1:12];   end
    else
        error('The step starter accepts only numeric descriptions.')
    end
    dispi('Steps to run: ',stepList2run, verbose)
    
    % Conventions
        % defines standard folders for each step 
        mprageDICOMfolder = fullfile(subj_dir,'01a_mprage_DICOM');
        mprageNiftiFolder = fullfile(subj_dir,'02_mprage_nifti');
        mprageSegmentedFolder = fullfile(subj_dir,'03_mprage_segmented');
        mprageNiftiFixedFolder = fullfile(subj_dir,'04_mprage_nifti_fixed');

        retinoDICOMfolder = fullfile(subj_dir,'01b_epi_retino_DICOM');
        retinoNiftiFolder = fullfile(subj_dir,'03_retino_nifti');
        retinoMCfolder = fullfile(subj_dir,'04_retino_MC');
        retinoNiftiFixedFolder = fullfile(subj_dir,'05_retino_nifti_fixed');
        retinoMrSessionFolder = fullfile(subj_dir,'06_retino_mrSession');
        retinoMrNiftiDir=fullfile(retinoMrSessionFolder,'nifti');
        retinoMeshFolder=fullfile(retinoMrSessionFolder,'Mesh');
        
        %file names in vista session / nifti
        gemsFile = 'gems_retino.nii.gz';
        mprageFile = 'mprage_nu_RAS_NoRS.nii.gz';
        
        expDICOMfolder = fullfile(subj_dir,'01c_epi_exp_DICOM');
        expPARfolder = fullfile(subj_dir,'01d_epi_exp_PAR');
        expNiftiFolder = fullfile(subj_dir,'03_exp_nifti');
        expMCfolder = fullfile(subj_dir,'04_exp_MC');
        expNiftiFixedFolder = fullfile(subj_dir,'05_exp_nifti_fixed');
        expMrSessionFolder = fullfile(subj_dir,'06_exp_mrSession');
    

    
    dispi(' --------------------------  End of pipeline initialization  ----------------------------------------', verbose)
    
% ---------- PIPELINE STEP CHECKS --------------------------------------------------------------------------------------------------
%for step=stepList2run
%     switch step
%         case {1}
%             dispi('For some of the steps you selected, we need to run quick basic checks. Please wait for them to be finished before leaving', verbose)
%             disp('For mprage nifti conversion: ')
%             dispi('DICOM mprage files (and only them) should be in a folder called ',mprageDICOMfolder, ' in the subject root folder',verbose)
%                 check_folder(mprageDICOMfolder, 0, verbose);
%                 check_files(mprageDICOMfolder,'*.dcm', param.mprageSliceNb, 1, verbose); %looking for the expected nb of dcm files
%         case {5}    
%                 disp('For nifti conversion of retino epi/gems: ')
%                 dispi('For each epi and gems, DICOM should be in separate folders inside ',retinoDICOMfolder, ' in the subject root folder',verbose)
%                 dispi('Each epi folder should contain the word epi in the name and each gems should contain gems.', verbose)
%                 check_folder(retinoDICOMfolder, 0, verbose);
%                 epiFolders = list_folders(retinoDICOMfolder, '*epi*', 1); %detects nomber of epi folders
%                 nbOfDetectedEpi=numel(epiFolders);
%                 if nbOfDetectedEpi==param.retinoEpiNb, dispi(nbOfDetectedEpi,'/',param.retinoEpiNb,' epis correctly detected', verbose); 
%                      else  warni(nbOfDetectedEpi,'/',param.retinoEpiNb,' epis detected: incorrect number', verbose); end
%                 for i=1:nbOfDetectedEpi  %check that we have the correct number of dcm files in each folder
%                      check_files(fullfile(retinoDICOMfolder,epiFolders(i)),'*.dcm', param.retinoEpiTRNb, 0, verbose); %looking for the expected nb of dcm files
%                 end
%                 gemsFolders = list_folders(retinoDICOMfolder, '*gems*', 1); %detects nomber of gems folders
%                 nbOfDetectedGems=numel(gemsFolders);
%                 if gemsFolders==param.retinoGemsNb, dispi(nbOfDetectedGems,'/',param.retinoGemsNb,' gems correctly detected', verbose); 
%                      else  warni(nbOfDetectedGems,'/',param.retinoGemsNb,' gems detected: incorrect number', verbose); end
%                 for i=1:nbOfDetectedGems  %check that we have the correct number of dcm files in each folder
%                      check_files(fullfile(retinoDICOMfolder,gemsFolders(i)),'*.dcm', param.retinoGemsSliceNb, 0, verbose); %looking for the expected nb of dcm files
%                 end
%          case {15}            
%                 
%     end
% end

% ---------- PIPELINE STEPS --------------------------------------------------------------------------------------------------
    dispi('Start to run pipeline steps', verbose)
    for step=stepList2run
        switch step
            case {1}            %   1. mprage: nifti conversion
                %basic checks
                dispi(' -------  ',step, '. Starting nifti conversion with dcm2niix from ',mprageDICOMfolder, ' to ', mprageNiftiFolder, verbose)
                dispi('DICOM mprage files (and only them) should be in a folder called ',mprageDICOMfolder, ' in the subject root folder',verbose)
                dispi('Check that source folders exist for that step', verbose)
                check_folder(mprageDICOMfolder, 1, verbose); %check that DICOM folder exists
                check_files(mprageDICOMfolder,'*.dcm', param.mprageSliceNb, 1, verbose); %looking for the expected nb of dcm files
                remove_previous(mprageNiftiFolder, verbose);
                disp('Check folder was correctly removed and creates a new one (will issue a benine warning)')
                check_folder(mprageNiftiFolder,0, verbose);
                success = system(['dcm2niix -z y -s n -t y -x n -v n -f "mprage" -o "', mprageNiftiFolder, '" "', mprageDICOMfolder,'"']);
                check_files(mprageNiftiFolder,'*.nii.gz', 1, 1, verbose);
                dispi(' --------------------------  End of mprage nitfi conversion  ----------------------------------------', verbose)
                            % -z y : gzip the files
                            % -s n : convert all images in folder
                            % -t y : save a text note file
                            % -x n : do not crop
                            % -v n : no verbose
                            % -o : output directory
                            % end term: input directory  
                 
           case {2}        %  2. mprage: segmentation using FSL
                %basic checks
                 dispi(' -------  ',step, '. Starting FSL segmentation from ',mprageNiftiFolder, ' to ', mprageSegmentedFolder, verbose)
                 dispi('Check that source folders exist for that step', verbose)
                 check_folder(mprageNiftiFolder, 1, verbose);
                 check_files(mprageNiftiFolder,'*mprage*.nii.gz', 1, 1, verbose); %looking for 1 mprage nifti file
                 remove_previous(mprageSegmentedFolder, verbose);
                 disp('Check that potential folder was correctly removed and creates a new one (will issue a benine warning)')
                 check_folder(mprageSegmentedFolder, 0, verbose);
                 segmentation(subjID, mprageNiftiFolder,mprageSegmentedFolder, verbose)
                 dispi(' --------------------------  end of segmentation  ----------------------------------------', verbose)
                 
           case {3}    %   3. mprage: correction of gray mesh irregularities
                dispi(' -------  ',step, '. mprage: correction of gray mesh irregularities not implemented yet', verbose)
                dispi(' This step has to be done manually on a Windows computer with itkGray/itkSnap', verbose)
                dispi(' --------------------------------------------------------------------------------------', verbose)
                
           case {4}        %   4. mprage: fix nifti header
                 %basic checks
                 dispi(' -------  ',step, '. Starting repair of nifti headers from ',mprageSegmentedFolder, ' to ', mprageNiftiFixedFolder, verbose)
                 dispi('Check that source folders exist for that step', verbose)
                 check_folder(mprageSegmentedFolder, 1, verbose);
                 check_files(mprageSegmentedFolder,'*nu_RAS_NoRS*.nii.gz', 1, 1, verbose); %looking for 1 mprage nifti file
                 remove_previous(mprageNiftiFixedFolder, verbose);
                 disp('Check that potential folder was correctly removed and creates a new one (will issue a benine warning)')
                 check_folder(mprageNiftiFixedFolder,0, verbose);
                 copy_files(mprageSegmentedFolder, '*nu_RAS_NoRS*.nii.gz', mprageNiftiFixedFolder, verbose) %copy all nifti mprage files
                 check_files(mprageNiftiFixedFolder,'*nu_RAS_NoRS*.nii.gz', 1, 1, verbose); %looking for 1 mprage nifti file
                 niftiFixHeader3(mprageNiftiFixedFolder)
                 check_files(mprageNiftiFixedFolder,'epiHeaders_FIXED.txt', 1, 1, verbose); %looking for 1 txt file called epiHeaders_FIXED
                 dispi(' --------------------------  End of nitfi repair for mprage  ----------------------------------------', verbose)
                
            case {5}     %   5. retino epi/gems: nifti conversion and removal of ''pRF dummy'' frames
                dispi(' -------  ',step, '. retino epi/gems: nifti conversion and removal of ''pRF dummy'' frames', verbose)
                %basic checks
                dispi(' -------  Starting nifti conversion with dcm2niix from ',retinoDICOMfolder, ' to  ', retinoNiftiFolder, verbose)
                dispi('For each epi and gems, DICOM should be in separate folders inside ',retinoDICOMfolder, ' in the subject root folder',verbose)
                dispi('Each epi folder should contain the word epi in the name and each gems should contain gems.', verbose)
                dispi('Check that source folders exist for that step', verbose)
                check_folder(retinoDICOMfolder, 1, verbose); %check that DICOM folder exists
                epiFolders = list_folders(retinoDICOMfolder, '*epi*', 1); %detects nomber of epi folders
                nbOfDetectedEpi=numel(epiFolders); %check whether number of EPI matches with what we expect
                if nbOfDetectedEpi==param.retinoEpiNb, dispi(nbOfDetectedEpi,'/',param.retinoEpiNb,' epis correctly detected', verbose); 
                     else  warni(nbOfDetectedEpi,'/',param.retinoEpiNb,' epis detected: incorrect number', verbose); end
                for i=1:nbOfDetectedEpi  %check that we have the correct number of dcm files in each folder
                     check_files(epiFolders{i},'*.dcm', param.retinoEpiTRNb, 0, verbose); %looking for the expected nb of dcm files
                end
                gemsFolders = list_folders(retinoDICOMfolder, '*gems*', 1); %detects nomber of gems folders
                nbOfDetectedGems=numel(gemsFolders); %checks that it matches what we expect
                if nbOfDetectedGems==param.retinoGemsNb, dispi(nbOfDetectedGems,'/',param.retinoGemsNb,' gems correctly detected', verbose); 
                     else  warni(nbOfDetectedGems,'/',param.retinoGemsNb,' gems detected: incorrect number', verbose); end
                for i=1:nbOfDetectedGems  %check that we have the correct number of dcm files in gem folder
                     check_files(gemsFolders{i},'*.dcm', param.retinoGemsSliceNb, 0, verbose); %looking for the expected nb of dcm files
                end
                remove_previous(retinoNiftiFolder, verbose); %remove older runs of that code
                disp('Check that potential folder was correctly removed and creates a new one (will issue a benine warning)')
                check_folder(retinoNiftiFolder,0, verbose); %check we have an output nifit folder or creates it
                success = system(['dcm2niix -z y -s n -t y -x n -v n -f "%p%s" -o "', retinoNiftiFolder, '" "', retinoDICOMfolder,'"']);
                %at the moment, it uses the %p to rename the output files so that we have the gems, epi, mprage names in the files.
                %However, if one uses different names in the dicom  sequences, all names will be incorrect for the next steps (we already have trouble
                % with some called ep2d instead of epi)
                check_files(retinoNiftiFolder,'*epi*.nii.gz', nbOfDetectedEpi, 1, verbose);
                check_files(retinoNiftiFolder,'*gems*.nii.gz', nbOfDetectedGems, 1, verbose);
                dispi(' --------------------------  End of retino epi nitfi conversion  ----------------------------------------', verbose)
                dispi(' --------------------------  Removing dummy pRF frames  ----------------------------------------', verbose)
                listConvertedEPI=list_files(retinoNiftiFolder, '*epi*.nii.gz', 1);
                for i=1:numel(listConvertedEPI)
                    remove_frames(listConvertedEPI{i}, param.pRFdummyFramesNb, verbose)
                end  
                dispi(' --------------------------  End of removing dummy pRF TR for epi ----------------------------------------', verbose)
                
            case {6}    %   6. retino epi/gems: motion correction 
                dispi(' ---------------  ',step, '. retino epi/gems: motion correction ------------------------', verbose)
                %basic checks
                dispi(' ------- from ',retinoNiftiFolder, ' to  ', retinoMCfolder, verbose)
                dispi('nifti header-fixed epi files (and only them) should be in a folder called ',retinoNiftiFolder, verbose)
                dispi('Check that source folders exist for that step', verbose)
                check_folder(retinoNiftiFolder, 1, verbose);
                remove_previous(retinoMCfolder, verbose);
                dispi('Check that potential folder was correctly removed and creates a new one (will issue a benine warning)', verbose)
                check_folder(retinoMCfolder, 0, verbose);
                copy_files(retinoNiftiFolder, '*.nii.gz', retinoMCfolder, verbose) %copy all nifti files to MC folder
                dispi('Check that we have all our nifti files in MC folder', verbose)
                [~, nbFiles]=check_files(retinoMCfolder,'*.nii.gz', param.retinoEpiNb+param.retinoGemsNb, 0, verbose); %we know we have nbFiles now
                
%                 motion_correction(retinoMCfolder, '*epi*.nii.gz', 'reffile') %motion correct the epi first
%                   %ref volume which should be the newly created ref_vol.nii.gz
%                 motion_correction(retinoMCfolder, '*gems*.nii.gz', 'reffile',fullfile(retinoMCfolder,'ref_vol.nii.gz'),1) %motion correct the gems second, using the same 
                
                reference = 3;
                % reference values:
                % 1. gems downsampled at epi resolution
                % 2. gems at original resolution - epi will be upsampled to gems resolution 
                % 3. first epi, first TR - gems is uncorrected
                switch reference
                    case {1}
                        dispi('We want mcFLIRT to motion correct the epis to the downsampled resolution GEMS') 
                        dispi('In that version, the EPIs will not be resampled at high resolution')
                        epis = list_files(retinoMCfolder, '*epi*.nii.gz', 1);
                        gems = list_files(retinoMCfolder, '*gems*.nii.gz', 1);
                        refFile=fullfile(retinoMCfolder,'gemsRef90.nii.gz');
                        fslresample(gems,refFile, '-ref', epis{1}, verbose)
                    case {2} % 2. gems at original resolution - epi will be upsampled to gems resolution 
                        dispi('We want mcFLIRT to motion correct the epis to the higher resolution GEMS') 
                        dispi('In that version, we will align the EPIs to the high resolution GEMS, which means EPIS will be resampled at high resolution')
                        listGEMS = list_files(retinoMCfolder, '*gems*.nii.gz', 1);
                        refFile=listGEMS{1};
                   case {3} % 3. first epi, first TR - gems is uncorrected
                        dispi('We want mcFLIRT to motion correct the epis to the first TR of the first epi') 
                        dispi('In that version, GEMS remains unaligned')
                        epis = list_files(retinoMCfolder, '*epi*.nii.gz', 1);
                        refFile= epis{1};
                end
                                        

                %motion correct the epi to the higher resolution gems (as a ref file)
                dispi('Motion-correcting all epis to the following reference file: ', refFile, verbose);
                motion_correction(retinoMCfolder, '*epi*.nii.gz', {'reffile', refFile, 1}, '-plots','-report','-cost mutualinfo','-smooth 16',verbose) 

                dispi('Check that we have all our MC files in MC folder', verbose)
                check_files(retinoMCfolder,'*_mcf.nii.gz', nbFiles-1, 1, verbose); %should be nb of epi -1 bc we do not correct our gems
                check_files(retinoMCfolder,'*_mcf.par', nbFiles-1, 1, verbose);
                %dispi('Deleting the downsampled gems reference file', verbose)
                %delete(gemsFileRef)
               dispi(' --------------------------  retino epi/gems: end of motion correction  ----------------------------------------', verbose)
               
          case {7}   %   7. retino epi: MC parameter check and artefact removal
                dispi(' -------  ',step, '. retino epi: MC parameter check and artefact removal', verbose)
                
                %bad_trs = motion_parameters(retinoMCfolder);
                %dispi('Suspicious TR detected     EPI   TR', verbose)
                %disp(bad_trs)
                
                dispi(' Nifti should be in folder :', retinoNiftiFolder)
                dispi('Check that source folders exist for that step', verbose)
                check_folder(retinoNiftiFolder, 1, verbose);
                dispi('Removing potential previous files for motion parameters')
                listConfounds=list_files(retinoNiftiFolder, '*confound*', 1);
                if numel(listConfounds)>0; dispi('Found ', numel(listConfounds),' confound files that are deleted now', verbose); delete(listConfounds{:}); end
                dispi('Using motion_outliers code from FSL for detecting artefacts', verbose)
                bad_trs=motion_outliers(retinoNiftiFolder, '-p', fullfile(retinoNiftiFolder,'motion_params.png'), '--dvars');
                dispi('Suspicious TR detected are:', verbose)
                disp(bad_trs)
                %TO DO HERE
                %Let's move all confounds files and images to a different
                %folder for clarity  
                dispi(' --------------------------  retino epi: end of motion param checks  ----------------------------------------', verbose)
                
          case {8} %8. retino epi/gems: nifti header repair
                dispi(' ------- --- ',step, '. retino epi/gems: nifti header repair --------------------', verbose)
                dispi('Check that source folders exist for that step', verbose)
                check_folder(retinoMCfolder, 1, verbose);
                remove_previous(retinoNiftiFixedFolder, verbose);
                disp('Check that potential folder was correctly removed and creates a new one (will issue a benine warning)')
                check_folder(retinoNiftiFixedFolder, 0, verbose);
                [~, nbFiles]=check_files(retinoMCfolder,'*_mcf.nii.gz', param.retinoEpiNb, 0, verbose); %we know we have nbFiles now
                disp('Copying')
                copy_files(retinoMCfolder, '*_mcf.nii.gz', retinoNiftiFixedFolder, verbose) %copy all mcf nifti files to nifti fixed folder
                copy_files(retinoMCfolder, '*gems*', retinoNiftiFixedFolder, verbose) %copy all gems files too to nifti fixed folder
                check_files(retinoNiftiFixedFolder,'*.nii.gz', nbFiles+1, 1, verbose); %should include all epi copied files + gems
                niftiFixHeader3(retinoNiftiFixedFolder)
                dispi(' --------------------------  retino epi/gems: end of nifti header repair ----------------------------------------', verbose)

         case {9}  %   9. retino epi/gems: initialization of mrVista session
                dispi(' -----------------  ',step, '. retino epi/gems: initialization of mrVista session ------------------------------', verbose) 
                dispi('Check that source folders exist for that step', verbose)
                check_folder(retinoNiftiFixedFolder, 1, verbose);
                check_folder(mprageNiftiFixedFolder, 1, verbose);
                dispi('Check that headers are corrected')
                check_files(mprageNiftiFixedFolder,'epiHeaders_FIXED.txt', 1, 1, verbose); %looking for 1 txt file called epiHeaders_FIXED
                check_files(retinoNiftiFixedFolder,'epiHeaders_FIXED.txt', 1, 1, verbose); %looking for 1 txt file called epiHeaders_FIXED
                remove_previous(retinoMrSessionFolder, verbose);
                dispi('Check that potential folder was correctly removed and creates a new one (will issue a benine warning)', verbose)
                check_folder(retinoMrSessionFolder, 0, verbose);
                check_folder(retinoMrNiftiDir, 0, verbose);
                copy_files(retinoNiftiFixedFolder, '*epi*mcf*.nii.gz', retinoMrNiftiDir, verbose) %copy mcf nifti fixed epi to nifti mrvista folder
                check_files(retinoNiftiFixedFolder,'*gems*.nii.gz', 1, 1, verbose); %looking for only 1 gems file there (otherwise there is room for errors)
                copy_files(retinoNiftiFixedFolder, '*gems*.nii.gz', fullfile(retinoMrNiftiDir,gemsFile), verbose) %copy nifti fixed gems to nifti mrvista folder
                copy_files(mprageNiftiFixedFolder, '*nu_RAS_NoRS*.nii.gz', fullfile(retinoMrNiftiDir,mprageFile), verbose) %copy nifti fixed mprage to nifti mrvista folder
                check_files(retinoMrNiftiDir,'*epi*mcf*.nii.gz', param.retinoEpiNb, 0, verbose); %looking for all the epis
                close all;
                init_session(retinoMrSessionFolder, retinoMrNiftiDir, 'inplane',fullfile(retinoMrNiftiDir,gemsFile),'functionals','*epi*mcf*.nii*','vAnatomy',fullfile(retinoMrNiftiDir,mprageFile),...
                    'sessionDir',retinoMrSessionFolder,'subject', subjID)%,'scanGroups', 1:param.retinoEpiNb)
                %alternative: kb_initializeVista2_retino(retinoMrSessionFolder, subjID)
                dispi(' --------------------------  retino epi: end of mrVista session initialization ----------------------------------------', verbose)
                
         case {10}  %   10. retino epi/gems: alignment of inplane and volume
                dispi(' --------------------  ',step, '. retino epi/gems: alignment of inplane and volume  ------------------------------', verbose) 
                dispi('Check that source folders exist for that step', verbose)
                check_folder(retinoMrSessionFolder, 1, verbose);
                check_folder(retinoDICOMfolder, 1, verbose);
                check_folder(retinoMrNiftiDir, 1, verbose);
                xform = alignment(retinoMrSessionFolder, fullfile(retinoMrNiftiDir,mprageFile), fullfile(retinoMrNiftiDir, gemsFile), fullfile(retinoDICOMfolder,'gems_retino_11'));
                dispi('Resulting xform matrix:',verbose)
                disp(xform)
                [averageCorr, sumRMSE]=extractAlignmentPerfStats(retinoMrSessionFolder, param.retinoGemsSliceNb, verbose);
                dispi(' --------------------------  retino epi: end of alignment volume/inplane  ----------------------------------------', verbose)
                
         case {11}  %   11. retino epi: segmentation installation
             dispi(' --------------------  ',step, '. retino epi/gems: install of segmentation  ------------------------------', verbose) 
             initialPath=cd;
             cd(retinoMrSessionFolder)
             install_segmentation(retinoMrSessionFolder, mprageSegmentedFolder, retinoMrNiftiDir, verbose)
             cd(initialPath)
             dispi(' --------------------------  retino epi: end of install of segmentation  ----------------------------------------', verbose)
             
        case {12}  %   12. retino/epi: mesh creation
             dispi(' --------------------  ',step, '. retino/epi: mesh creation / inflating ------------------------------', verbose) 
             initialPath=cd;
             cd(retinoMrSessionFolder);
             remove_previous(retinoMeshFolder, verbose);
             check_folder(retinoMrSessionFolder, 1, verbose);
             check_folder(retinoMeshFolder, 0, verbose);
             create_mesh(retinoMeshFolder, param.smoothingIterations, verbose)
             dispi('Checking for output mesh files in Mesh folder', verbose)
             check_files(retinoMeshFolder, 'lh_pial.mat', 1, verbose);
             check_files(retinoMeshFolder, 'rh_pial.mat', 1, verbose);
             check_files(retinoMeshFolder, 'lh_inflated.mat', 1, verbose);
             check_files(retinoMeshFolder, 'rh_inflated.mat', 1, verbose);
             cd(initialPath);
             dispi(' --------------------------  retino/epi: end of mesh creation / inflating ----------------------------------------', verbose)

         case {13}  %  13. retino epi: pRF model
             dispi(' --------------------  ',step, '. retino/epi: pRF model ------------------------------', verbose) 
             check_folder(retinoMrSessionFolder, 1, verbose);
             pRF_model(retinoMrSessionFolder, retinoMrNiftiDir, '*epi*.nii*', param, 1, verbose)
             dispi('Check success of pRF model', verbose)
             check_files(fullfile(retinoMrSessionFolder,'Gray/Averages'), '*fFit*', 1, verbose); %check that retino model exists
             dispi(' --------------------------  retino/epi: end of pRF model ----------------------------------------', verbose)

        case {14} %   14. retino epi: mesh visualization of pRF values
                dispi(' --------------------  ',step, '. retino epi: mesh visualization of pRF values ------------------------------', verbose) 
                check_folder(retinoMrSessionFolder, 1, verbose);
                check_folder(retinoMeshFolder, 1, verbose);
                dispi('Check that pRF model was run', verbose)
                check_files(fullfile(retinoMrSessionFolder,'Gray/Averages'), '*fFit*', 1, verbose); %check that retino model exists
                retinoModelFile = list_files(fullfile(retinoMrSessionFolder,'Gray/Averages'), '*fFit*',1);
                
                curdir = pwd; 
                cd(retinoMrSessionFolder)
                vol = initHiddenGray; %open Gray
                vol.curDataType = 2; % set to Averages
                dispi('Loading retino model map: File | Retinotopy Model | Load and Select Model File',verbose)
                vol = rmSelect(vol, 1, retinoModelFile); vol = rmLoadDefault(vol); %load retino model map File | Retinotopy Model | Load and Select Model File
                dispi('Selecting phase map: View | Phase map',verbose)
                vol=setDisplayMode(vol,'ph');%select phase map: View | Phase map
                %vw=refreshScreen(vw);
                dispi('Opening connection to mrm server', verbose)
                windowID=mrmStart(1,'localhost'); %start mrm mesh visualization server
                %input('Press a key when server ready')
                dispi('Opening a gray view for left hemisphere and loading the inflated mesh into it', verbose)
                vol = meshLoad(vol, fullfile(retinoMeshFolder,'lh_inflated.mat'), 1); %Gray | Surface Mesh | Load and Display 
                %input('Press a key when server ready')
                vol = meshColorOverlay(vol); %Gray | update mesh
                cd(curdir)
                input('Press a key to quit and close visualization')
                close_mesh_server(verbose);
                
                dispi(' -------------------------- retino epi: end of mesh visualization of pRF values ----------------------------------------', verbose)
                
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
        record_notes('off');
        save('errorLog', 'err')
        whos
        clear all
        load('errorLog', 'err')
        rethrow(err);
    catch err2
        rethrow(err2);
    end
end