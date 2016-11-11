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
%   12. retino epi: pRF model
%   13. retino epi: mesh visualization of pRF values
%   14. retino epi: extraction of flat projections
%   15. exp epi/gems: nifti conversion
%   16. exp epi/gems: motion correction / nifti header repair
%   17. exp epi: artefact removal and MC parameter check
%   18: -
%   19. exp epi/gems: initialization of mrVista session
%   20. exp epi/gems: alignment of inplane and volume
%   21. exp epi: segmentation installation
%   22. exp epi: GLM sanity check
%   23. exp epi: actual GLM model
%   24. exp epi: mesh visualization
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
        record_notes(check_folder(notes_dir,0, verbose))
    end

    dispi(dateTime, verbose)
    dispi('Subject folder root is: ', subj_dir, verbose)
    dispi('Subject ID is: ', subjID, verbose)
    
    %load subject parameters
    cd(subj_dir)
    success = check_files(subj_dir, 'expectedParametersForPipeline.m', 1, 0, verbose);
    if success==0, dispi('The parameter file expectedParametersForPipeline could not \n',...
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
        if stepList2run==0;            stepList2run=[1:17,19:24];   end
    else
        error('The step starter accepts only numeric descriptions.')
    end
    
    %defines standard folders for each step
    mprageDICOMfolder = fullfile(subj_dir,'01a_mprage_DICOM');
    mprageNiftiFolder = fullfile(subj_dir,'02_mprage_nifti');
    mprageSegmentedFolder = fullfile(subj_dir,'03_mprage_segmented');
    mprageNiftiFixedFolder = fullfile(subj_dir,'04_mprage_nifti_fixed');
        
    retinoDICOMfolder = fullfile(subj_dir,'01b_epi_retino_DICOM');
    retinoNiftiFolder = fullfile(subj_dir,'03_retino_nifti');
    retinoMCfolder = fullfile(subj_dir,'04_retino_MC');
    retinoNiftiFixedFolder = fullfile(subj_dir,'05_retino_nifti_fixed');
    retinoMrSessionFolder = fullfile(subj_dir,'06_retino_mrSession');
    
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
%                 dispi('For each epi and gems, DICOM should be in separate folders inside ',retinoDICOMfolder, '\n in the subject root folder',verbose)
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
                dispi(' -------  ',step, '. Starting nifti conversion with dcm2niix from ',mprageDICOMfolder, ' to \n', mprageNiftiFolder, verbose)
                dispi('DICOM mprage files (and only them) should be in a folder called ',mprageDICOMfolder, ' in the subject root folder',verbose)
                check_folder(mprageDICOMfolder, 0, verbose); %check that DICOM folder exists
                check_files(mprageDICOMfolder,'*.dcm', param.mprageSliceNb, 1, verbose); %looking for the expected nb of dcm files
                remove_previous(mprageNiftiFolder, verbose);
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
                 dispi(' -------  ',step, '. Starting FSL segmentation from ',mprageNiftiFixedFolder, ' to \n', mprageSegmentedFolder, verbose)
                 check_folder(mprageNiftiFixedFolder, 0, verbose);
                 check_files(mprageNiftiFixedFolder,'*mprage*.nii.gz', 1, 1, verbose); %looking for 1 mprage nifti file
                 check_files(mprageNiftiFixedFolder,'epiHeaders_FIXED.txt', 1, 1, verbose); %looking for 1 txt file called epiHeaders_FIXED
                 remove_previous(mprageSegmentedFolder, verbose);
                 check_folder(mprageSegmentedFolder, 0, verbose);
                 segmentation(subjID, mprageNiftiFixedFolder,mprageSegmentedFolder, verbose)
                 
           case {3}    %   3. mprage: correction of gray mesh irregularities
                dispi(' -------  ',step, '. mprage: correction of gray mesh irregularities not implemented yet', verbose)
                
           case {4}        %   4. mprage: fix nifti header
                 %basic checks
                 dispi(' -------  ',step, '. Starting repair of nifti headers from ',mprageSegmentedFolder, ' to \n', mprageNiftiFixedFolder, verbose)
                 check_folder(mprageSegmentedFolder, 0, verbose);
                 check_files(mprageSegmentedFolder,'*nu_RAS_NoRS*.nii.gz', 1, 1, verbose); %looking for 1 mprage nifti file
                 remove_previous(mprageNiftiFixedFolder, verbose);
                 check_folder(mprageNiftiFixedFolder,0, verbose);
                 copy_files(mprageSegmentedFolder, '*nu_RAS_NoRS*.nii.gz', mprageNiftiFixedFolder, verbose) %copy all nifti mprage files
                 check_files(mprageNiftiFixedFolder,'*nu_RAS_NoRS*.nii.gz', 1, 1, verbose); %looking for 1 mprage nifti file
                 niftiFixHeader3(mprageNiftiFixedFolder)
                 dispi(' --------------------------  End of nitfi repair for mprage  ----------------------------------------', verbose)
                
            case {5}     %   5. retino epi/gems: nifti conversion and removal of ''pRF dummy'' frames
                dispi(' -------  ',step, '. retino epi/gems: nifti conversion and removal of ''pRF dummy'' frames', verbose)
                %basic checks
                dispi(' -------  Starting nifti conversion with dcm2niix from ',retinoDICOMfolder, ' to \n ', retinoNiftiFolder, verbose)
                dispi('For each epi and gems, DICOM should be in separate folders inside ',retinoDICOMfolder, '\n in the subject root folder',verbose)
                dispi('Each epi folder should contain the word epi in the name and each gems should contain gems.', verbose)
                check_folder(retinoDICOMfolder, 0, verbose); %check that DICOM folder exists
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
                dispi(' ------- from ',retinoNiftiFolder, ' to \n ', retinoMCfolder, verbose)
                dispi('nifti header-fixed epi files (and only them) should be in a folder called ',retinoNiftiFolder, verbose)
                check_folder(retinoNiftiFolder, 1, verbose);
                [~, nbFiles]=check_files(retinoNiftiFolder,'*.nii.gz', param.retinoEpiNb+param.retinoGemsNb, 0, verbose); %we know we have nbFiles now
                remove_previous(retinoMCfolder, verbose);
                check_folder(retinoMCfolder, 0, verbose);
                copy_files(retinoNiftiFolder, '*.nii.gz', retinoMCfolder, verbose) %copy all nifti files to MC folder
                check_files(retinoMCfolder,'*.nii.gz', nbFiles, 1, verbose);
                motion_correction(retinoMCfolder, '*epi*.nii.gz', 'reffile') %motion correct the epi first
                motion_correction(retinoMCfolder, '*gems*.nii.gz', 'reffile',fullfile(retinoMCfolder,'ref_vol.nii.gz'),1) %motion correct the gems second, using the same 
                %ref volume which should be the newly created ref_vol.nii.gz
                check_files(retinoMCfolder,'*_mcf.nii.gz', nbFiles, 1, verbose);
                check_files(retinoMCfolder,'*_mcf.par', nbFiles, 1, verbose);
                 
          case {7}   %   7. retino epi: MC parameter check and artefact removal
                dispi(' -------  ',step, '. retino epi: MC parameter check and artefact removal', verbose)
                dispi(' Motion corrected files should be nifti-header fixed in folder :', retinoMCfolder)
                check_folder(retinoMCfolder, 1, verbose);
                bad_trs = motion_parameters(retinoMCfolder);
                dispi('Suspicious TR detected \n    EPI   TR')
                disp(bad_trs)
                dispi(' --------------------------  retino epi: end of motion param checks  ----------------------------------------', verbose)
                %  motion_outliers(retinoNiftiFolder)
                
          case {8} %8. retino epi/gems: nifti header repair
                dispi(' ------- --- ',step, '. retino epi/gems: nifti header repair --------------------', verbose)
                check_folder(retinoMCfolder, 1, verbose);
                remove_previous(retinoNiftiFixedFolder, verbose);
                check_folder(retinoNiftiFixedFolder, 0, verbose);
                [~, nbFiles]=check_files(retinoMCfolder,'*_mcf.nii.gz', param.retinoEpiNb+param.retinoGemsNb, 0, verbose); %we know we have nbFiles now
                copy_files(retinoMCfolder, '*_mcf.nii.gz', retinoNiftiFixedFolder, verbose) %copy all mcf nifti files to nifti fixed folder
                check_files(retinoNiftiFixedFolder,'*_mcf.nii.gz', nbFiles, 1, verbose);
                niftiFixHeader3(retinoNiftiFixedFolder)
                dispi(' --------------------------  retino epi/gems: nifti header repair ----------------------------------------', verbose)

         case {9}  %   9. retino epi/gems: initialization of mrVista session
                dispi(' -------  ',step, '. retino epi/gems: initialization of mrVista session', verbose) 
                check_folder(retinoNiftiFixedFolder, 0, verbose);
                check_folder(mprageNiftiFixedFolder, 0, verbose);
                remove_previous(retinoMrSessionFolder, verbose);
                check_folder(retinoMrSessionFolder, 0, verbose);
                check_folder(fullfile(retinoMrSessionFolder,'nifti'), 0, verbose);
                copy_files(retinoNiftiFixedFolder, '*epi*mcf*.nii.gz', fullfile(retinoMrSessionFolder,'nifti'), verbose) %copy mcf nifti fixed epi to nifti mrvista folder
                copy_files(retinoNiftiFixedFolder, '*gems*mcf*.nii.gz', fullfile(retinoMrSessionFolder,'nifti','gems.nii.gz'), verbose) %copy mcf nifti fixed gems to nifti mrvista folder
                copy_files(mprageNiftiFixedFolder, '*nu_RAS_NoRS*.nii.gz', fullfile(retinoMrSessionFolder,'nifti','mprage.nii.gz'), verbose) %copy nifti fixed mprage to nifti mrvista folder
                mrNiftiDir=fullfile(retinoMrSessionFolder,'nifti');
                init_session(retinoMrSessionFolder, mrNiftiDir, 'inplane',fullfile(mrNiftiDir,'gems.nii.gz'),'functionals','*epi*mcf*.nii*','vAnatomy',fullfile(mrNiftiDir,'mprage.nii.gz'),...
                    'sessionDir',retinoMrSessionFolder,'subject', subjID)
                
            %   10. retino epi/gems: alignment of inplane and volume
            %   11. retino epi: segmentation installation
            %   12. retino epi: pRF model
            %   13. retino epi: mesh visualization of pRF values
            %   14. retino epi: extraction of flat projections
            
         case {15}    % 15. Exp epi/gems: nifti conversion and fix of nifti headers
                dispi(' -------  ',step, '. Exp epi/gems: nifti conversion and fix of nifti headers', verbose)
                %basic checks
                dispi(' -------  Starting nifti conversion with dcm2niix from ',expDICOMfolder, ' to \n ', expNiftiFolder, verbose)
                dispi('For each epi and gems, DICOM should be in separate folders inside ',expDICOMfolder, '\n in the subject root folder',verbose)
                dispi('Each epi folder should contain the word epi in the name and each gems should contain gems.', verbose)
                check_folder(expDICOMfolder, 0, verbose); %check that DICOM folder exists
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
                check_folder(expNiftiFolder,0, verbose); %check we have an output nifit folder or creates it
                success = system(['dcm2niix -z y -s n -t y -x n -v n -f "%p%s" -o "', expNiftiFolder, '" "', expDICOMfolder,'"']);
                %at the moment, it uses the %p to rename the output files so that we have the gems, epi, mprage names in the files.
                %However, if one uses different names in the dicom sequences, all names will be incorrect for the next steps
                check_files(expNiftiFolder,'*ep*.nii.gz', nbOfDetectedEpi, 1, verbose);
                check_files(expNiftiFolder,'*gems*.nii.gz', nbOfDetectedGems, 1, verbose);
                dispi(' --------------------------  End of exp epi nitfi conversion  ----------------------------------------', verbose)
                
            %   16. exp epi/gems: motion correction and fix nifti headers
            case {16}
                dispi(' --------------------------  Fixing nifti headers for exp epi/gems----------------------------------------', verbose)
                niftiFixHeader3(expNiftiFolder)
                expectedFiles= nbOfDetectedEpi+nbOfDetectedGems;
                check_files(expNiftiFolder,'*.nii.gz', expectedFiles, 1, verbose);
                dispi(' --------------------------  End of nifti headers for exp epi/gems ----------------------------------------', verbose)
            %   17. exp epi: artefact removal and MC parameter check
            case {18}
                dispi(' -------  ',step, '. nifti header repair should be done in same step as motion correction so nothing special here', verbose)
            %   19. exp epi/gems: initialization of mrVista session
            %   20. exp epi/gems: alignment of inplane and volume
            %   21. exp epi: segmentation installation
            %   22. exp epi: GLM sanity check
            %   23. exp epi: actual GLM model
            %   24. exp epi: mesh visualization
            otherwise
                dispi('Warning: this step is not recognized: ', step, verbose)
        end
    end
 
    dispi(' --------------------------  End of pipeline ',dateTime, ' -------------------------', verbose)
    record_notes('off');
catch err
    try
        cd(subj_dir)
        record_notes('off');
        rethrow(err);
    catch err2
        rethrow(err2);
    end
end

    
