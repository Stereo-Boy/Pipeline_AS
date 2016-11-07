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
%   5. retino epi: nifti conversion and removal of ''pRF dummy'' frames
%   6. retino epi: motion correction and MC parameter check
%   7. retino epi: artefact removal
%   8. retino epi: fix nifti headers
%   9. retino epi: initialization of mrVista session
%   10. retino epi: alignment of inplane and volume
%   11. retino epi: segmentation installation
%   12. retino epi: pRF model
%   13. retino epi: mesh visualization of pRF values
%   14. retino epi: extraction of flat projections
%   15. exp epi: nifti conversion
%   16. exp epi: motion correction and MC parameter check
%   17. exp epi: artefact removal
%   18. exp epi: fix nifti headers
%   19. exp epi: initialization of mrVista session
%   20. exp epi: alignment of inplane and volume
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
    
    %check for subj_dir
    if ~exist('subj_dir','var')||~exist(subj_dir, 'dir'), 
        subj_dir = uigetdir(pwd, 'Choose folder for analysis:'); 
    end;
    
    cd(checkFolder(subj_dir, 1, verbose));
    
    %check for subjID
    if ~exist('subjID','var'), [~, subjID] = fileparts(subj_dir); end;
    
    %check for notes_dir
    if exist('notes_dir','var') 
        % creates notes_dir if necessary and start diary
        record_notes(checkFolder(notes_dir,0, verbose))
    end

    dispi(dateTime, verbose)
    dispi('Subject folder root is: ', subj_dir, verbose)
    dispi('Subject ID is: ', subjID, verbose)
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
        if stepList2run==0
           stepList2run=1:24; 
        end
    else
        error('The step starter accepts only numeric descriptions.')
    end
    
    %defines standard folders for each step
    mprageDICOMfolder = '01a_mprage_DICOM';
    epiRetinoDICOMfolder = '01b_epi_retino_DICOM';
    epiExpDICOMfolder = '01c_epi_exp_DICOM';
    epiExpPARfolder = '01d_epi_exp_PAR';
    mprageNiftiFolder = '02_mprage_nifti';
    
    dispi(' --------------------------  End of pipeline initialization  ----------------------------------------', verbose)
    
% ---------- PIPELINE STEPS --------------------------------------------------------------------------------------------------
    dispi('Start to run pipeline steps', verbose)
    for step=1:numel(stepList2run)
        switch step
            case {1}
            %   1. mprage: nifti conversion
                %basic checks
                dispi('DICOM mprage files (and only them) should be in a folder called ',mprageDICOMfolder, ' in the subject root folder',verbose)
                checkFolder(mprageDICOMfolder, 0, verbose);
                check_files(mprageDICOMfolder,'*.dcm', param.mprageSliceNb, 1, verbose);
                removePrevious(mprageNiftiFolder, verbose);
                checkFolder(mprageNiftiFolder,0, verbose);
                dispi(' -------  Starting nifti conversion with dcm2niix from ',mprageDICOMfolder, ' to ', mprageNiftiFolder, verbose)
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
                
            %   2. mprage: fix nifti header
            %   3. mprage: segmentation using FSL
            %   4. mprage: correction of gray mesh irregularities
            %   5. retino epi: nifti conversion and removal of ''pRF dummy'' frames
            %   6. retino epi: motion correction and MC parameter check
            %   7. retino epi: artefact removal
            %   8. retino epi: fix nifti headers
            %   9. retino epi: initialization of mrVista session
            %   10. retino epi: alignment of inplane and volume
            %   11. retino epi: segmentation installation
            %   12. retino epi: pRF model
            %   13. retino epi: mesh visualization of pRF values
            %   14. retino epi: extraction of flat projections
            %   15. exp epi: nifti conversion
            %   16. exp epi: motion correction and MC parameter check
            %   17. exp epi: artefact removal
            %   18. exp epi: fix nifti headers
            %   19. exp epi: initialization of mrVista session
            %   20. exp epi: alignment of inplane and volume
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
        record_notes('off');
        rethrow(err);
    catch err2
        rethrow(err2);
    end
end

    
