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
%   2. mprage: fix nifti header
%   3. mprage: segmentation using FSL
%   4. mprage: correction of gray mesh irregularities
%   5. retino epi/gems: nifti conversion and removal of ''pRF dummy'' frames
%   6. retino epi/gems: motion correction and MC parameter check
%   7. retino epi: artefact removal
%   8. retino epi/gems: fix nifti headers
%   9. retino epi/gems: initialization of mrVista session
%   10. retino epi/gems: alignment of inplane and volume
%   11. retino epi: segmentation installation
%   12. retino epi: pRF model
%   13. retino epi: mesh visualization of pRF values
%   14. retino epi: extraction of flat projections
%   15. exp epi/gems: nifti conversion
%   16. exp epi/gems: motion correction and MC parameter check
%   17. exp epi: artefact removal
%   18. exp epi/gems: fix nifti headers
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
    cd(subj_dir)
    param=expectedParametersForPipeline(verbose);
    dispi('Current expected parameters are: ')
    disp(param)
    
    % MENU
    if exist('stepList2run', 'var')==0
        help(mfilename);
        stepList2run=input('Enter the numbers of the desired steps, potentially between brackets: ');
    end
    
    % CHECKS THAT steps are numbers
    if isnumeric(stepList2run)
        if stepList2run==0;            stepList2run=1:24;   end
    else
        error('The step starter accepts only numeric descriptions.')
    end
    
    %defines standard folders for each step
    mprageDICOMfolder = fullfile(subj_dir,'01a_mprage_DICOM');
    epiRetinoDICOMfolder = fullfile(subj_dir,'01b_epi_retino_DICOM');
    epiExpDICOMfolder = fullfile(subj_dir,'01c_epi_exp_DICOM');
    epiExpPARfolder = fullfile(subj_dir,'01d_epi_exp_PAR');
    mprageNiftiFolder = fullfile(subj_dir,'02_mprage_nifti');
    mprageNiftiFixedFolder = fullfile(subj_dir,'03_mprage_nifti_fixed');
    mprageSegmentedFolder = fullfile(subj_dir,'04_mprage_segmented');
    epiRetinoNiftiFolder = fullfile(subj_dir,'05_epi_retino_nifti_folder');
    epiRetinoMCfolder = fullfile(subj_dir,'06_epi_retino_MC_folder');
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
%                 dispi('For each epi and gems, DICOM should be in separate folders inside ',epiRetinoDICOMfolder, '/n in the subject root folder',verbose)
%                 dispi('Each epi folder should contain the word epi in the name and each gems should contain gems.', verbose)
%                 check_folder(epiRetinoDICOMfolder, 0, verbose);
%                 epiFolders = list_folders(epiRetinoDICOMfolder, '*epi*', 1); %detects nomber of epi folders
%                 nbOfDetectedEpi=numel(epiFolders);
%                 if nbOfDetectedEpi==param.retinoEpiNb, dispi(nbOfDetectedEpi,'/',param.retinoEpiNb,' epis correctly detected', verbose); 
%                      else  warni(nbOfDetectedEpi,'/',param.retinoEpiNb,' epis detected: incorrect number', verbose); end
%                 for i=1:nbOfDetectedEpi  %check that we have the correct number of dcm files in each folder
%                      check_files(fullfile(epiRetinoDICOMfolder,epiFolders(i)),'*.dcm', param.retinoEpiTRNb, 0, verbose); %looking for the expected nb of dcm files
%                 end
%                 gemsFolders = list_folders(epiRetinoDICOMfolder, '*gems*', 1); %detects nomber of gems folders
%                 nbOfDetectedGems=numel(gemsFolders);
%                 if gemsFolders==param.retinoGemsNb, dispi(nbOfDetectedGems,'/',param.retinoGemsNb,' gems correctly detected', verbose); 
%                      else  warni(nbOfDetectedGems,'/',param.retinoGemsNb,' gems detected: incorrect number', verbose); end
%                 for i=1:nbOfDetectedGems  %check that we have the correct number of dcm files in each folder
%                      check_files(fullfile(epiRetinoDICOMfolder,gemsFolders(i)),'*.dcm', param.retinoGemsSliceNb, 0, verbose); %looking for the expected nb of dcm files
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
                dispi(' -------  1. Starting nifti conversion with dcm2niix from ',mprageDICOMfolder, ' to ', mprageNiftiFolder, verbose)
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
                
            case {2}        %   2. mprage: fix nifti header
                 %basic checks
                 dispi(' -------  2. Starting repair of nifti headers from ',mprageNiftiFolder, ' to ', mprageNiftiFixedFolder, verbose)
                 check_folder(mprageNiftiFolder, 0, verbose);
                 check_files(mprageNiftiFolder,'*mprage*.nii.gz', 1, 1, verbose); %looking for 1 mprage nifti file
                 remove_previous(mprageNiftiFixedFolder, verbose);
                 check_folder(mprageNiftiFixedFolder,0, verbose);
                 copy_files(mprageNiftiFolder, '*mprage*.nii.gz', mprageNiftiFixedFolder, verbose) %copy all nifti mprage files
                 check_files(mprageNiftiFixedFolder,'*mprage*.nii.gz', 1, 1, verbose); %looking for 1 mprage nifti file
                 niftiFixHeader3(mprageNiftiFixedFolder)
                 cd(subj_dir)
                 dispi(' --------------------------  End of nitfi repair for mprage  ----------------------------------------', verbose)
                 
           case {3}        %  3. mprage: segmentation using FSL
                %basic checks
                 dispi(' -------  3. Starting FSL segmentation from ',mprageNiftiFixedFolder, ' to ', mprageSegmentedFolder, verbose)
                 check_folder(mprageNiftiFixedFolder, 0, verbose);
                 check_files(mprageNiftiFixedFolder,'*mprage*.nii.gz', 1, 1, verbose); %looking for 1 mprage nifti file
                 check_files(mprageNiftiFixedFolder,'epiHeaders_FIXED.txt', 1, 1, verbose); %looking for 1 txt file called epiHeaders_FIXED
                 remove_previous(mprageSegmentedFolder, verbose);
                 check_folder(mprageSegmentedFolder, 0, verbose);
                 segmentation(subjID, mprageNiftiFixedFolder,mprageSegmentedFolder, verbose)
            case {4}    %   4. mprage: correction of gray mesh irregularities
                dispi(' 4. mprage: correction of gray mesh irregularities not implemented yet', verbose)
            case {5}     %   5. retino epi/gems: nifti conversion and removal of ''pRF dummy'' frames
                dispi(' 5. retino epi/gems: nifti conversion and removal of ''pRF dummy'' frames', verbose)
                %basic checks
                dispi(' -------  Starting nifti conversion with dcm2niix from ',epiRetinoDICOMfolder, ' to /n ', epiRetinoNiftiFolder, verbose)
                dispi('For each epi and gems, DICOM should be in separate folders inside ',epiRetinoDICOMfolder, '/n in the subject root folder',verbose)
                dispi('Each epi folder should contain the word epi in the name and each gems should contain gems.', verbose)
                check_folder(epiRetinoDICOMfolder, 0, verbose); %check that DICOM folder exists
                epiFolders = list_folders(epiRetinoDICOMfolder, '*epi*', 1); %detects nomber of epi folders
                nbOfDetectedEpi=numel(epiFolders); %check whether number of EPI matches with what we expect
                if nbOfDetectedEpi==param.retinoEpiNb, dispi(nbOfDetectedEpi,'/',param.retinoEpiNb,' epis correctly detected', verbose); 
                     else  warni(nbOfDetectedEpi,'/',param.retinoEpiNb,' epis detected: incorrect number', verbose); end
                for i=1:nbOfDetectedEpi  %check that we have the correct number of dcm files in each folder
                     check_files(epiFolders{i},'*.dcm', param.retinoEpiTRNb, 0, verbose); %looking for the expected nb of dcm files
                end
                gemsFolders = list_folders(epiRetinoDICOMfolder, '*gems*', 1); %detects nomber of gems folders
                nbOfDetectedGems=numel(gemsFolders); %checks that it matches what we expect
                if nbOfDetectedGems==param.retinoGemsNb, dispi(nbOfDetectedGems,'/',param.retinoGemsNb,' gems correctly detected', verbose); 
                     else  warni(nbOfDetectedGems,'/',param.retinoGemsNb,' gems detected: incorrect number', verbose); end
                for i=1:nbOfDetectedGems  %check that we have the correct number of dcm files in gem folder
                     check_files(gemsFolders{i},'*.dcm', param.retinoGemsSliceNb, 0, verbose); %looking for the expected nb of dcm files
                end
                remove_previous(epiRetinoNiftiFolder, verbose); %remove older runs of that code
                check_folder(epiRetinoNiftiFolder,0, verbose); %check we have an output nifit folder or creates it
                success = system(['dcm2niix -z y -s n -t y -x n -v n -f "%p%s" -o "', epiRetinoNiftiFolder, '" "', epiRetinoDICOMfolder,'"']);
                %at the moment, it uses the %p to rename the output files
                %so that we have the gems, epi, mprage names in the files.
                %However, if one uses different names in the dicom
                %sequences, all names will be incorrect for the next steps
                check_files(epiRetinoNiftiFolder,'*epi*.nii.gz', nbOfDetectedEpi, 1, verbose);
                check_files(epiRetinoNiftiFolder,'*gems*.nii.gz', nbOfDetectedGems, 1, verbose);
                dispi(' --------------------------  End of retino epi nitfi conversion  ----------------------------------------', verbose)
                dispi(' --------------------------  Fixing nifti headers and removing dummy pRF frames  ----------------------------------------', verbose)
                niftiFixHeader3(epiRetinoNiftiFolder)
                expectedFiles= nbOfDetectedEpi+nbOfDetectedGems;
                check_files(epiRetinoNiftiFolder,'*.nii.gz', expectedFiles, 1, verbose);
                listConvertedEPI=list_files(epiRetinoNiftiFolder, '*epi*.nii.gz', 1);
                for i=1:numel(listConvertedEPI)
                    remove_frames(listConvertedEPI{i}, param.pRFdummyFramesNb, verbose)
                end  
                dispi(' --------------------------  End of nifti headers and removing dummy pRF for epi ----------------------------------------', verbose)
            case {6}    %   6. retino epi/gems: motion correction and MC parameter check
                dispi('6. retino epi/gems: motion correction', verbose)
                %basic checks
                dispi(' -------  retino epi: starting motion correction from ',epiRetinoNiftiFolder, ' to /n ', epiRetinoMCfolder, verbose)
                dispi('nifti header-fixed epi files (and only them) should be in a folder called ',epiRetinoNiftiFolder, verbose)
                check_folder(epiRetinoNiftiFolder, 0, verbose);
                [~, nbFiles]=check_files(epiRetinoNiftiFolder,'*.nii.gz', param.retinoEpiNb+param.retinoGemsNb, 0, verbose); %we know we have nbFiles now
                remove_previous(epiRetinoMCfolder, verbose);
                check_folder(epiRetinoMCfolder, 0, verbose);
                copy_files(epiRetinoNiftiFolder, '*.nii.gz', epiRetinoMCfolder, verbose) %copy all nifti files to MC folder
                check_files(epiRetinoMCfolder,'*.nii.gz', nbFiles, 1, verbose);
                motion_correction(epiRetinoMCfolder, '*epi*.nii.gz', 'reffile') %motion correct the epi first
                motion_correction(epiRetinoMCfolder, '*gems*.nii.gz', 'reffile',fullfile(epiRetinoMCfolder,'ref_vol.nii.gz'),1) %motion correct the epi second, using the same 
                %ref volume which should be the newly created ref_vol.nii.gz
                check_files(epiRetinoMCfolder,'*_mcf.nii.gz', nbFiles, 1, verbose);
                check_files(epiRetinoMCfolder,'*_mcf.par', nbFiles, 1, verbose);
                dispi(' --------------------------  retino epi: end of motion correction  ----------------------------------------', verbose)
            %   7. retino epi: artefact removal
            %   8. retino epi/gems: fix nifti headers
            %   9. retino epi/gems: initialization of mrVista session
            %   10. retino epi/gems: alignment of inplane and volume
            %   11. retino epi: segmentation installation
            %   12. retino epi: pRF model
            %   13. retino epi: mesh visualization of pRF values
            %   14. retino epi: extraction of flat projections
            %   15. exp epi/gems: nifti conversion
            %   16. exp epi/gems: motion correction and MC parameter check
            %   17. exp epi: artefact removal
            %   18. exp epi/gems: fix nifti headers
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

    
