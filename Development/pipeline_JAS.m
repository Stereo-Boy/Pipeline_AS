function pipeline_JAS(stepList2run, subj_dir, subjID, notes_dir, verbose, optionalArg)
% ------------------------------------------------------------------------
% Automated fMRI analysis pipeline for mrVista analysis
% pipeline_JAS(stepList2run, subj_dir, subjID, notes_dir, verbose)
%
% stepList2run is a list of numbers corresponding to the possible steps to
% run. If stepList2run is not defined, it shows this help.
%
% Steps available to run:
%   0. All of the below steps
%   1. mprage: nifti conversion (dcm2niix from MRIcron)
%   2. mprage: segmentation (Freesurfer)
%   3. mprage: correction of gray mesh irregularities (itkGray)
%   4. mprage: nifti header repair
%   5. retino epi/gems: nifti conversion and removal of ''pRF dummy'' frames (dcm2niix from MRIcron)
%   6. retino epi/gems: motion correction (FSL)
%   7. retino epi: MC parameter check and artefact removal (FSL)
%   8. retino epi/gems: nifti header repair
%   9. retino epi/gems: initialization of session (mrVista)
%   10. retino epi/gems: alignment of inplane and volume (FSL/mrVista)
%   11. retino epi: segmentation installation (mrVista)
%   12. retino/epi: mesh creation (mrVista)
%   13. retino epi: pRF model (mrVista)
%   14. retino epi: mesh visualization of pRF values (mrVista)

% THE FOLLOWING STEPS ARE NOT IMPLEMENTED YET
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
%  TO USE GLM INSTEAD OF pRF
% ------------------------------
%  The pipeline can be used to pre-process data for GLM or anything else than retinotopy. Do as for retinotpy, but just don't run 
%  pRF-specific step like 13-14). 
%  In that case, you will also need to issue .par files manually and assign them manually too. For that, in the mrVista session, copy
%  your par files in the Stimuli/Parfiles folder. Then either run run_glm or do GLM>assign parfiles to scans. You also need to group scan together in 
%  GLM>grouping>group scans. Check if it is all correct with GLM>show parfiles/scan group.
%
% Other inputs:
% --------------
% - subj_dir: directory path for subject analysis (string) - root of all other folders for that subject
% - subjID: [optional] subject id (string, if not provided, will guess from the name of the subject folder)
% - notes_dir: [optional] directory path to save command output (string),   default is 'notes'
% - verbose: [optional] if verbose = verboseOFF, none of the disp function will give an
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
    clear global %to avoid troubles between sessions that use global vars like HOMEDIR
    
% ---------- INITIALIZATION --------------------------------------------------------------------------------------------------
    %show help when no argument given
    if nargin==0;         help(mfilename);         return;    end   
    
    %if verbose is set to verboseOFF, it will mute all dispi functions.
    if ~exist('verbose', 'var')||isempty(verbose); verbose='verboseON'; end
    if ~exist('optionalArg', 'var'); optionalArg=[]; end
     
    %check for subj_dir and open an interactive window if not defined or empty
    if ~exist('subj_dir','var')||~exist(subj_dir, 'dir');   dispi('subj_dir not defined: prompt', verbose);  subj_dir = uigetdir(pwd, 'Choose folder for analysis:');     end;
    cd(check_folder(subj_dir, 1, verbose));
    
    %check for subjID
    if ~exist('subjID','var')||isempty(subjID); dispi('subjID not defined: we deduce it from directory.');[~, subjID] = fileparts(subj_dir); end;
    
    %check for notes_dir
    if ~exist('notes_dir','var')||isempty(notes_dir)==0; notes_dir='notes'; end
        % creates notes_dir if necessary and starts diary
        record_notes(check_folder(notes_dir,0, verbose),'pipeline_JAS')


    % MENU
    while (~exist('stepList2run', 'var')|isempty(stepList2run)|isnumeric(stepList2run)==0|stepList2run<=0|stepList2run>14)
        help(mfilename);
        stepList2run=input('Enter the numbers of the desired steps, potentially between brackets: ');
    end
    
    dispi('Running pipeline_JAS with additionnal arguments: notes_dir: ', notes_dir,' /optionalArg: ', optionalArg,verbose)
    dispi('Subject ID is: ', subjID,' and subject folder is: ', subj_dir, verbose)
    dispi('Steps to run: ',stepList2run, verbose)
    dispi(' --------------------------  Pipeline initialization:', dateTime,' ----------------------------------------', verbose)
    
    % Add spm files to the path - adding it here rather than in the startup file avoids bugs and
    % conflict with spm functions in vistasoft folder
    spmPath = '~/Desktop/spm12'; % update this with your path
    if (exist(spmPath,'dir') ~= 7); warning('spm does not exist!'); end
    path(path, spmPath); %path to your spm folder BUT not all subfolders because it is not recommended
    disp('Loaded path to spm folder at the bottom of the search path list.')

    %load subject parameters
    paramFile=fullfile(subj_dir, 'parameterFile.m');
    if strcmp(which('parameterFile.m'),paramFile)==0; erri('Incorrect parameter file to load');
    else       dispi('Loading parameter file: ', which('parameterFile.m'),verbose); param=parameterFile(subj_dir, verbose);
        cellfun(@(x,y)assignin('caller', x, y), fieldnames(param),struct2cell(param)); %this will assign each field in param to a variable with the same name
    end

        % Previous version list to remove: For each step, the following array should contain one cell with either a folder name or a
        % list of folder names in a cell: before each step, it will check whether that folder exists, and if yes, will remove it.
        % If no folder should be removed for that step, enter an empty cell ('' or {} or []). The order of the cells should follow the 
        % step numbers. All paths should be absolute paths.
        %             step     1          2         3        4              5           6       7           8           9
        foldersByStep = {mpr_ni_dir, mpr_segm_dir, '', mpr_niFixed_dir, ret_ni_dir, ret_mc_dir, '', ret_mcFixed_dir, ret_mr_dir,...
            '', '', ret_mr_mesh_dir, fullfile(ret_mr_dir,'Gray','Averages'), ''};
        %   10  11       12                        13                        14   
 
       %here is where optionalArg may be loaded to the variable it may replace
            % a = optionalArg;
            
    dispi(' --------------------------  End of pipeline initialization  ----------------------------------------', verbose)
    
% ---------- PIPELINE STEPS --------------------------------------------------------------------------------------------------
    dispi('Starts to run pipeline steps', verbose)
    for step=stepList2run     
        dispi(repmat('-',1,20),'Running step ', step,repmat('-',1,20),verbose);
        dispi('Attempts to remove previous version of that step, if necessary:')
        remove_previous(foldersByStep{step}, verbose);
       % dispi('Attempts to create folders for that step, if they do not exist:')
        check_folder(foldersByStep{step}, 0, verbose);
        switch step
            case {1}   %   1. mprage: nifti conversion (dcm2niix)
                dispi(repmat('*',1,20),' Description of the step ',step, ': Nifti conversion with dcm2niix from ',mpr_dicom_dir, ' to ', mpr_ni_dir, verbose)
                dispi('DICOM mprage files should be in a folder itself in a folder called ',mpr_dicom_dir, ' in the subject folder',verbose)
                checkSourceFolders(mpr_dicom_dir, verbose)
                dcm2niiConvert(mpr_dicom_dir, '*/', 1, mprageSliceNb, mpr_ni_dir, verbose)    %at the moment, only works with one mprage folder     
                    
           case {2}        %  2. mprage: segmentation using Freesurfer
                 dispi(repmat('*',1,20),' Description of the step ',step, ': Freesurfer segmentation from ',mpr_ni_dir, ' to ', mpr_segm_dir, verbose)
                 checkSourceFolders(mpr_ni_dir, verbose)
                 check_files(mpr_ni_dir,'*mprage*.nii.gz', 1, 1, verbose); %looking for 1 mprage nifti file
                 segmentation(subjID, mpr_ni_dir,mpr_segm_dir, verbose);                 %outputs{step} = get_dir(mpr_ni_dir,'t1_class.nii.gz');
                 
           case {3}    %   3. mprage: correction of gray mesh irregularities (itkGray)
                dispi(repmat('*',1,20),' Description of the step ',step, '. Mprage: checking for correction of gray mesh irregularities', verbose)
                dispi(' This step has to be done manually on a Windows computer with itkGray', verbose)
                dispi(' Edited class file should contain the word (edited) in a folder called: ',mpr_segm_dir,verbose);
                checkSourceFolders(mpr_segm_dir, verbose)
                if itkgray_skip==1
                    dispi('However, you decided to skip that step',verbose);
                    success=check_files(mpr_segm_dir,'*edited*.nii.gz', 1, 0, verbose); %looking for 1 edited nifti file
                    if success==0
                       dispi('and the edited file is missing, therefore we will simply rename the unedited file adding edited in name',verbose);
                       check_files(mpr_segm_dir,'*class*.nii.gz', 1, 1, verbose); 
                       t1classFile=get_dir(mpr_segm_dir, '*class*.nii.gz', 1); [a b c]=fileparts(t1classFile); editedFile=fullfile(a,['edited_',b,c]);
                       [success,message]=copyfile(t1classFile, editedFile);
                       if success; dispi('Renamed to ', editedFile, verbose);else erri('Renaming to: ',editedFile,' failed: ', message); end
                       check_files(mpr_segm_dir,'*edited*.nii.gz', 1, 1, verbose); %looking for 1 edited nifti file
                    end
                else
                    check_files(mpr_segm_dir,'*edited*.nii.gz', 1, 1, verbose); %looking for 1 edited nifti file
                end
           case {4}        %   4. mprage: fix nifti header
               dispi(repmat('*',1,20),' Description of the step ',step, ': Repair of mprage nifti headers from ',mpr_segm_dir, ' to ', mpr_niFixed_dir, verbose)
               if nifti_fix_skip; warni('This step should be skipped because nifti_fix_skip = 1 but we proceed anyway', verbose); end
               checkSourceFolders(mpr_segm_dir, verbose)
               expr = '*nu_RAS_NoRS*.nii*'; %expression to select isometric mprage file
               check_files(mpr_segm_dir,expr, 1, 1, verbose); %looking for 1 mprage file
               fixHeader(mpr_segm_dir,expr,mpr_niFixed_dir,1,...
                    'freq_dim',freq_dim,'phase_dim',phase_dim,'slice_dim',slice_dim,...
                    'slice_end',mpr_slice_end,'slice_duration',mpr_slice_duration);
               check_files(mpr_niFixed_dir,'headers_FIXED.txt', 1, 1, verbose); %looking for 1 txt file called headers_FIXED
               
            case {5}     %   5. retino epi/gems: nifti conversion (dcm2niix) and removal of ''pRF dummy'' frames
                dispi(repmat('*',1,20),' Description of the step ',step, ': retino epi/gems: nifti conversion (dcm2niix) and removal of pRF dummy frames', verbose)
                dispi('For each epi and gems, DICOM should be in separate folders inside ',ret_dicom_dir, ' in the subject folder',verbose)
                dispi('Each epi folder should contain the word epi or gems.', verbose)
                checkSourceFolders(ret_dicom_dir, verbose)
                dcm2niiConvert(ret_dicom_dir, {'*epi*/','*gems*/'}, [retinoEpiNb,retinoGemsNb], [retinoEpiTRNb,retinoGemsSliceNb], ret_ni_dir, verbose)
                dispi(repmat('-',1,20),' Removing dummy pRF frames ',repmat('-',1,20), verbose)
                [list_ni_epis, ni_epi_n]=get_dir(ret_ni_dir, '*epi*.nii*');
                dispi('Now removing frames for ', ni_epi_n, ' epi nifti files')
                if numel(list_ni_epis)==0; erri('There is no epi files found and consequently, no dummy frame will be removed. To avoid further issues, we exit here. Please check.');end
                for i=1:numel(list_ni_epis); remove_frames(list_ni_epis{i}, pRFdummyFramesNb, verbose);    end  
                 
            case {6}    %   6. retino epi/gems: motion correction (FSL)
                dispi(repmat('*',1,20),' Description of the step ',step, ': retino epi/gems: FSL motion correction from ',ret_ni_dir, ' to  ', ret_mc_dir,'---', verbose)
                checkSourceFolders(ret_ni_dir, verbose)

                copy_files(ret_ni_dir, '*.nii.gz', ret_mc_dir, verbose) %copy all nifti files to MC folder
                dispi('Check that we have all our nifti files in MC folder', verbose)
                [~, nbFiles]=check_files(ret_mc_dir,'*.nii.gz', retinoEpiNb+retinoGemsNb, 0, verbose); %we know we have nbFiles now
                
%                 motion_correction(ret_mc_dir, '*epi*.nii.gz', 'reffile') %motion correct the epi first
%                   %ref volume which should be the newly created ref_vol.nii.gz
%                 motion_correction(ret_mc_dir, '*gems*.nii.gz', 'reffile',fullfile(ret_mc_dir,'ref_vol.nii.gz'),1) %motion correct the gems second, using the same 
                
                % reference values:
                % 1. gems downsampled at epi resolution - gems is corrected
                % 2. gems at original resolution - epi will be upsampled to gems resolution - gems is corrected
                % 3. first epi, first TR - gems is uncorrected
                % 4. first epi, first TR - gems is corrected  
                % 5. first epi, middle TR - gems is uncorrected
                exprMC='*epi*.nii*';
                nExpectedMCfiles=nbFiles-1; %should be nb of epi -1 bc we do not correct our gems
                refTR=1;
                switch reference
                    case {1}
                        dispi('Ref1: We want mcFLIRT to motion correct the epis to the downsampled resolution GEMS') 
                        dispi('In that version, the EPIs will not be resampled at high resolution')
                        epis = list_files(ret_mc_dir, '*epi*.nii.gz', 1);
                        gems = list_files(ret_mc_dir, '*gems*.nii.gz', 1);
                        refFile=fullfile(ret_mc_dir,'gemRef90.nii.gz'); %should not contain the word gems to avoid latter mistakes
                        fslresample(gems{1},refFile, '-ref', epis{1}, verbose)
                    case {2} % 2. gems at original resolution - epi will be upsampled to gems resolution 
                        dispi('Ref2: We want mcFLIRT to motion correct the epis to the higher resolution GEMS') 
                        dispi('In that version, we will align the EPIs to the high resolution GEMS, which means EPIS will be resampled at high resolution')
                        listGEMS = list_files(ret_mc_dir, '*gems*.nii.gz', 1);
                        refFile=listGEMS{1};
                   case {3} % 3. first epi, first TR - gems is uncorrected
                        dispi('Ref3: We want mcFLIRT to motion correct the epis to the first TR of the first epi') 
                        dispi('In that version, GEMS remains unaligned')
                        epis = list_files(ret_mc_dir, '*epi*.nii.gz', 1);
                        refFile= epis{1};
                   case {4} % 4. first epi, first TR - gems is corrected
                        dispi('Ref4: We want mcFLIRT to motion correct the epis to the first TR of the first epi') 
                        dispi('In that version, GEMS is also aligned but then upsampling back to high resolution')
                        epis = list_files(ret_mc_dir, '*epi*.nii.gz', 1);
                        gems = list_files(ret_mc_dir, '*gems*.nii.gz', 1); %find its name before MC files arrive for later upsampling
                        refFile= epis{1};
                        exprMC='*.nii.gz';
                        nExpectedMCfiles=nbFiles;
                   case {5} % 5. first epi, middle TR - gems is uncorrected 
                        dispi('Ref5: We want mcFLIRT to motion correct the epis to the middle TR of the first epi') 
                        dispi('In that version, GEMS remains unaligned')
                        epis = list_files(ret_mc_dir, '*epi*.nii.gz', 1);
                        refFile= epis{1};
                        refTR=[];
                end                    
                %motion correct the epi to the higher resolution gems (as a ref file)
                dispi('Motion-correcting all epis to the following reference file: ', refFile, verbose);
                motion_correction(ret_mc_dir, exprMC, {'reffile', refFile, refTR}, '-plots','-report','-cost mutualinfo','-smooth 16',verbose) 
                if reference==4; dispi('Upsampling the MC gems back to its original resolution',verbose);
                    mcf_gems = list_files(ret_mc_dir, '*gems*mcf*.nii.gz', 1);
                    fslresample(mcf_gems{1},mcf_gems{1}, '-ref', gems{1}, verbose);
                end 
                dispi('Check that we have all our MC files in MC folder', verbose)
                check_files(ret_mc_dir,'*_mcf.nii.gz', nExpectedMCfiles, 1, verbose); 
                check_files(ret_mc_dir,'*_mcf.par', nExpectedMCfiles, 1, verbose);
                 
          case {7}   %   7. retino epi: MC parameter check and artefact removal (FSL)
                dispi(repmat('*',1,20),' Description of the step ',step, ': retino epi: FSL MC-parameter check and artefact removal from ',ret_ni_dir,'---', verbose)               
                %bad_trs = motion_parameters(ret_mc_dir);   %dispi('Suspicious TR detected     EPI   TR', verbose);  %disp(bad_trs)
                checkSourceFolders(ret_ni_dir, verbose)
                dispi('Removing potential previous confound files for motion parameters')
                listConfounds=list_files(ret_ni_dir, '*confound*', 1);
                if numel(listConfounds)>0; dispi('Found ', numel(listConfounds),' confound files that are deleted now', verbose); delete(listConfounds{:}); end
                dispi('Using motion_outliers code from FSL for detecting artefacts', verbose)
                bad_trs=motion_outliers(ret_ni_dir, 'epi*.nii*', '-p', fullfile(ret_ni_dir,'motion_params.png'), '--dvars', verbose);
                dispi('Suspicious TR detected are:', verbose)
                disp(bad_trs)
                % TO DO HERE:  Let's move all confounds files and images to a different folder for clarity  
                
          case {8} % 8. retino epi/gems: nifti header repair
               dispi(repmat('*',1,20),' Description of the step ',step, ': Repair of epi/gems nifti headers from ',ret_mc_dir,' to ',ret_mcFixed_dir, verbose)
               if nifti_fix_skip; warni('This step should be skipped because nifti_fix_skip = 1 but we proceed anyway', verbose); end
               checkSourceFolders(ret_mc_dir, verbose)
               % fix epi first
               exprEPI = '*epi*mcf.nii*'; %expression to select epi files
               check_files(ret_mc_dir, exprEPI, retinoEpiNb, 1, verbose); %looking for retinoEpiNb files to copy
               fixHeader(ret_mc_dir,exprEPI,ret_mcFixed_dir,retinoEpiNb, 'freq_dim',freq_dim,'phase_dim',phase_dim,'slice_dim',slice_dim,...
                        'slice_end',mpr_slice_end,'slice_duration',retinoEpi_slice_duration, verbose);
               % then fix gems 
               if reference==4 %in that case, gems is MC, so select only the mcf file
                    exprGEMS = '*gems*mcf.nii*'; %expression to select gems files
               else %otherwise, select just the gems
                    exprGEMS = '*gems*.nii*'; %expression to select gems files
               end
               check_files(ret_mc_dir, exprGEMS, retinoGemsNb, 1, verbose); %looking for retinoEpiNb files to copy
               fixHeader(ret_mc_dir,exprGEMS,ret_mcFixed_dir,retinoGemsNb,  'freq_dim',freq_dim,'phase_dim',phase_dim,'slice_dim',slice_dim,...
                        'slice_end',mpr_slice_end,'slice_duration',retinoGems_slice_duration, verbose); 
               check_files(ret_mcFixed_dir,'headers_FIXED.txt', 1, 1, verbose); %looking for 1 txt file called headers_FIXED
  
         case {9}  %   9. retino epi/gems: initialization of session (mrVista)
                dispi(repmat('*',1,20),' Description of the step ',step, ': retino epi/gems: initialization of session (mrVista) ------------------------------', verbose) 
                checkSourceFolders({ret_mcFixed_dir,mpr_niFixed_dir}, verbose)
                if nifti_fix_skip==0
                    dispi('Check that headers are corrected')
                    check_files(mpr_niFixed_dir,'headers_FIXED.txt', 1, 1, verbose); %looking for 1 txt file called headers_FIXED
                    check_files(ret_mcFixed_dir,'headers_FIXED.txt', 1, 1, verbose); %looking for 1 txt file called headers_FIXED
                end
                check_folder(ret_mr_ni_dir, 0, verbose); %will be created
                copy_files(ret_mcFixed_dir, '*epi*mcf*.nii.gz', ret_mr_ni_dir, verbose) %copy mcf nifti fixed epi to nifti mrvista folder
                check_files(ret_mcFixed_dir,'*gems*.nii.gz', 1, 1, verbose); %looking for only 1 gems file there (otherwise there is room for errors)
                copy_files(ret_mcFixed_dir, '*gems*.nii.gz', fullfile(ret_mr_ni_dir,gemsFile), verbose) %copy nifti fixed gems to nifti mrvista folder
                copy_files(mpr_niFixed_dir, '*nu_RAS_NoRS*.nii.gz', fullfile(ret_mr_ni_dir,mprageFile), verbose) %copy nifti fixed mprage to nifti mrvista folder
                check_files(ret_mr_ni_dir,'*epi*mcf*.nii.gz', retinoEpiNb, 0, verbose); %looking for all the epis
                close all;
                current_dir= pwd; cd(ret_mr_dir); %important step for mrVista session initialization to define HOMEDIR correctly
                init_session(ret_mr_dir, ret_mr_ni_dir, 'inplane',fullfile(ret_mr_ni_dir,gemsFile),'functionals','*epi*mcf*.nii*','vAnatomy',fullfile(ret_mr_ni_dir,mprageFile),...
                    'sessionDir',ret_mr_dir,'subject', subjID)
                cd(current_dir);
                %alternative: kb_initializeVista2_retino(ret_mr_dir, subjID)
                
         case {10}  %   10. retino epi/gems: alignment of inplane and volume (FSL/mrVista)
                dispi(repmat('*',1,20),' Description of the step ',step, ': retino epi/gems: alignment of inplane and volume (FSL/mrVista)  ------------------------------', verbose) 
                ipath_dir = get_dir(ret_dicom_dir, '*gems*/', 1); %this one it the DICOM GEMS folder
                checkSourceFolders({ret_mr_dir,ret_dicom_dir,ret_mr_ni_dir,ipath_dir}, verbose)
                if reference==4; dispi('Warning: here we have motion-correct the GEMS file to the first EPI so that the ipath to the GEMS dicom folder is incorrect', verbose);
                    dispi('There is no way to convert the nifti back to DICOM but it may be not a big deal given only the (untouched) header is necessary for that file', verbose)
                end
                xform = alignment(ret_mr_dir, fullfile(ret_mr_ni_dir,mprageFile), fullfile(ret_mr_ni_dir, gemsFile), ipath_dir, [1:5]);
                dispi('Resulting xform matrix:',verbose)
                disp(xform)
                [averageCorr, sumRMSE]=extractAlignmentPerfStats(ret_mr_dir, retinoGemsSliceNb, verbose);
                if isnan(averageCorr)||averageCorr<0.7, errori('Alignment failed - correlation is <0.7, please run a different alignment procedure', verbose);   end
         
        case {11}  %   11. retino epi: segmentation installation (mrVista)
             dispi(repmat('*',1,20),' Description of the step ',step, ': retino epi/gems: install of segmentation (mrVista) ------------------------------', verbose) 
             install_segmentation(ret_mr_dir, mpr_segm_dir, ret_mr_ni_dir, verbose)
               
        case {12}  %   12. retino/epi: mesh creation (mrVista)
             dispi(repmat('*',1,20),' Description of the step ',step, ': retino/epi: mesh creation / inflating (mrVista) ------------------------------', verbose) 
             initialPath=cd;             cd(ret_mr_dir);
             checkSourceFolders(ret_mr_dir, verbose)
             t1file = get_dir(mpr_segm_dir, '*edited*.nii*', 1);
             create_mesh(ret_mr_dir,ret_mr_mesh_dir, t1file, smoothingIterations, 3, verbose)

             dispi('Checking for output mesh files in Mesh folder', verbose)
             check_files(ret_mr_mesh_dir, 'lh_pial.mat', 1, verbose);
             check_files(ret_mr_mesh_dir, 'rh_pial.mat', 1, verbose);
             check_files(ret_mr_mesh_dir, 'lh_inflated.mat', 1, verbose);
             check_files(ret_mr_mesh_dir, 'rh_inflated.mat', 1, verbose);
             cd(initialPath);
  
         case {13}  %  13. retino epi: pRF model (mrVista)
             dispi(repmat('*',1,20),' Description of the step ',step, ': retino/epi: pRF model (mrVista) ------------------------------', verbose) 
             checkSourceFolders(ret_mr_dir, verbose)

             pRF_model(ret_mr_dir, ret_mr_ni_dir, '*epi*.nii*', 3, param, @make8Bars, 1, verbose)

             dispi('Check success of pRF model', verbose)
             check_files(fullfile(ret_mr_dir,'Gray/Averages'), '*fFit*', 1, verbose); %check that retino model exists
 
        case {14} %   14. retino epi: mesh visualization of pRF values (mrVista)
            dispi(repmat('*',1,20),' Description of the step ',step, ': retino epi: mesh visualization of pRF values (mrVista) ------------------------------', verbose)
            checkSourceFolders({ret_mr_dir,ret_mr_mesh_dir}, verbose)
            dispi('Check that pRF model was run', verbose)
            check_files(fullfile(ret_mr_dir,'Gray/Averages'), '*fFit*', 1, verbose); %check that retino model exists
            retinoModelFile = list_files(fullfile(ret_mr_dir,'Gray/Averages'), '*fFit*',1);          
            curdir = pwd;            cd(ret_mr_dir);
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
            vol = meshLoad(vol, fullfile(ret_mr_mesh_dir,'lh_inflated.mat'), 1); %Gray | Surface Mesh | Load and Display
            %input('Press a key when server ready')
            vol = meshColorOverlay(vol); %Gray | update mesh
           % input('Press a key to quit and close visualization')
            close_mesh_server(verbose);
            [meanvarexp, nbVarSupx] = getAverageModelAccuracy(retinoModelFile{1},10,verbose);
            cd(curdir)
             
        % THE FOLLOWING STEPS ARE NOT IMPLEMENTED YET
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

            otherwise
                dispi('Warning: this step is not recognized: ', step, verbose)
        end
        dispi(repmat('-',1,20),' End of step ', step,repmat('-',1,20),verbose);
        dispi(repmat('-',1,100), verbose);
    end
    dispi(' --------------------------  End of pipeline ',dateTime, ' -------------------------', verbose)
    record_notes('off');
    
catch err
    try
        dispi('Saving error in errorLog in folder: ', pwd, verbose);
        err_msg = getReport(err, 'extended', 'hyperlinks', 'on');
        save('errorLog', 'err','err_msg');
        dispi('Showing last known values for all variables, after error:', verbose)
        whos
        clear all
        load('errorLog', 'err_msg','err')
        dispi(err_msg)
        record_notes('off');
        rethrow(err);
    catch err2
        rethrow(err2);
    end
end
end

function checkSourceFolders(folders, verbose)
    % folders can be a cell list of folders (absolute paths prefered) or a single folder
    % If the source folder do not exist, throw an error and stops the pipeline to avoid further errors
    dispi('Check that the following source folders and files exist for that step', verbose)
    dispi('Folders: ',folders, verbose)
    check_folder(folders, 1, verbose); %check that DICOM folder exists
end