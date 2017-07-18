function run_glm(mr_dir, TR, epi_nb, par_dir, event_analysis, tr_by_block, newDTname, grayFlag, notes_dir, verbose)

% run_glm(mr_dir, TR, epi_nb, par_dir, tr_by_block, newDTname, grayFlag, notes_dir, verbose)
%
% This function runs a separate GLM for each run in the Original dataType.
% It will assume that all parfiles are in par_dir folder in the right order
%
% mr_dir is the mrVista folder for that subject
% TR duration in sec is required
% verbose should be either verboseON (default) or verboseOFF
% par_dir is where you have your par files stored (paradigm files)
% epi_nb is the number of runs of data
% if event_analysis (default=0) is 1, tr_by_block is defaulted to 0 and
% tr_by_block is the number of TR by blocks in case of blocked design (0 if event-related)
% grayFlag describes whether to run the GLM on all voxels (0) or only on the gray voxels (1)
% If you use this flag, be sure to have transformed the time Series firts in Gray>Xform>Inplane>Volume>tSeries (all scans)
% newDTname is the name to give to the dataType - providing a name REALLY avoids mistakes, so please do

%show help when no argument given
    if nargin==0;         help(mfilename);         return;    end  
    
% check inputs and records
    if ~exist('verbose','var')||isempty(verbose), verbose = 'verboseON'; dispi('[run_glm] empty verbose defaulted to verboseON', verbose); end;

%check for notes_dir
    if ~exist('notes_dir','var')||isempty(notes_dir)==0; notes_dir=fullfile(mr_dir,'notes'); end
        % creates notes_dir if necessary and starts diary
        record_notes(check_folder(notes_dir,0, verbose),'run_glm')

    if ~exist('TR','var')||isempty(TR),  error('[run_glm] TR value required'); end;
    if ~exist('mr_dir','var')||isempty(mr_dir), mr_dir = pwd; dispi('[run_glm] empty mr_dri defaulted to ', mr_dir, verbose); end;
    if ~exist('par_dir','var')||isempty(par_dir), par_dir = fullfile(mr_dir,'Stimuli/Parfiles/'); dispi('[run_glm] empty par_dir defaulted to ', par_dir, verbose); end;
    if ~exist('epi_nb','var')||isempty(epi_nb), epi_nb = 1; dispi('[run_glm] empty epi_nb defaulted to ', epi_nb, verbose); end;
    if ~exist('event_analysis','var')||isempty(event_analysis), event_analysis = 0; dispi('[run_glm] empty event_analysis defaulted to ', 0, verbose); end;
    if ~exist('tr_by_block','var')||isempty(tr_by_block), if event_analysis==1; tr_by_block = 0; else tr_by_block=7; end; dispi('[run_glm] empty tr_by_block defaulted to ', tr_by_block, verbose); end;
    if ~exist('grayFlag','var')||isempty(grayFlag), grayFlag = 0; dispi('[run_glm] empty grayFlag defaulted to ', grayFlag, verbose); end;
    if ~exist('newDTname','var')||isempty(newDTname), newDTname = 'GLM_default'; dispi('[run_glm] empty newDTname defaulted to ', newDTname, verbose); end;
    
  
% check for existence of directories
    dispi('We are running a GLM with ', epi_nb,' runs, TR=',TR,' in a new dataType called: ', newDTname, verbose)
    dispi('Our mrVista session is: ', mr_dir, verbose)
    check_folder(mr_dir, 1, verbose);
    dispi('Our par file folder is: ', par_dir, verbose)
    check_folder(par_dir, 1, verbose);

    if tr_by_block>0,    dispi('The block design has ', tr_by_block, ' TR by block', verbose)
    else    dispi('This is an event-related design', verbose); 
    end
    if grayFlag==1, dispi('We run the GLM on gray voxels only', verbose)
    else dispi('We run the GLM on all voxels', verbose)
    end

% call for global mrVista variables
    cd(mr_dir);
    mrGlobals;

% initialize inlane/gray view and dataType
    if grayFlag==1
        view = initHiddenGray;
    else
        view = initHiddenInplane;
    end

    if view.curDataType~=1, dispi('[run_glm] dataType set to Original',verbose);view.curDataType=1; end
% select par files
    list_par_files = list_files(par_dir, '*.par', 1);
    
        params = er_defaultParams;
% runs through scans
    for scan=1:epi_nb
        view.curScan= scan;                                         % assign current scan
        dispi('Scan ', scan)
        % see option description here: http://web.stanford.edu/group/vista/cgi-bin/wiki/index.php/MrVista_1_conventions#eventAnalysisParams
        params.framePeriod = TR;
        params.detrend= -1; %linear
        params.eventAnalysis=1;
        params.eventsPerBlock=tr_by_block;
        params.snrConds = [1 2]; %all non-fixation (not used but could be for calculating SNR and HRF)
        params.normBsl = 0; %no baseline normalization
        params.glmHRF = 2; %boyton
        params.ampType = 'betas';
        params.inhomoCorrect=1; %divide intensity by the mean at that voxel
        er_setParams(view, params, scan);
        %dataTYPES(1).scanParams(scan).parfile=list_par_files{scan}; % assign parfile / could use er_assignParfilesToScans instead
        view = er_assignParfilesToScans(view, scan, list_par_files(scan)); 
        dispi('Parfile: ', dataTYPES(1).scanParams(scan).parfile)
        view = er_groupScans(view,scan,2,1);                        % assign scan group 
        dispi('Scangroup: ', dataTYPES(1).scanParams(scan).scanGroup)

        % run GLM
        applyGlm(view,1, scan, params, newDTname)
    end
    
    if grayFlag==1,  glm_success(fullfile(mr_dir,'Gray',newDTname));
    else glm_success(fullfile(mr_dir,'Inplane',newDTname));     end
    