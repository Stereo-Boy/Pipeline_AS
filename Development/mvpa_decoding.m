function mvpa_decoding(mr_dir, nbRuns, dtName, mvpa_dir, mvpa_analysis, gray_flag, notes_dir, predictors, verbose)
% mvpa_decoding(mr_dir, nbRuns, dtName, mvpa_dir, mvpa_analysis, gray_flag,notes_dir, verbose)
% script to apply mvpa on brain images using the TDT
% mr_dir: the directory for the mr vista session
% You first need to run a separate GLM for each scan (run) with the two labels you want to decode
% as two predictors. The resulting betamaps should be stored in the folder Inplane/GLMs/RawMaps
% under the names betas_predictor1 and betas_predictor2 (standard) (or Gray folder if gray_flag is 1)
% Be sure that no other GLMs has been run before or after because it wants to load
% the first nbRuns items in those structures and consider them as the different runs maps.
% The best is to have a separate dataType name (dtName) to avoid mistakes.
% mvpa_dir is the place where to store the final mrVista decoding results
% mvpa_analysis are the values for cfg.analysis - like 'searchlight' or 'wholebrain' (default)
% gray_flag is a flat restricting the analysis to gray voxels - the flag is needed because mrVista does
% not work with the same dimensions then
% if your brain is not 90x90x38, then we have to add a size parameter (or read it in a way)
% notes_dir is where we save notes from record_notes (default is notes)
% predictors - which beta predictors maps to load for decoding? (default is first and second predictors only)

%show help when no argument given
    if nargin==0;         help(mfilename);         return;    end  
    
% check inputs and records
    if ~exist('verbose','var')||isempty(verbose), verbose = 'verboseON'; dispi('[mvpa_decoding] empty verbose defaulted to verboseON'); end;
    
%check for notes_dir
    if ~exist('notes_dir','var')||isempty(notes_dir)==0; notes_dir=fullfile(mr_dir,'notes'); end
        % creates notes_dir if necessary and starts diary
        record_notes(check_folder(notes_dir,0, verbose),'mvpa_decoding')


    if ~exist('mr_dir','var')||isempty(mr_dir), mr_dir = cd; dispi('[mvpa_decoding] empty mr_dir defaulted to ',mr_dir, verbose); end;
    if ~exist('nbRuns','var')||isempty(nbRuns), nbRuns = 1; dispi('[mvpa_decoding] empty nbRuns defaulted to ',nbRuns, verbose); end;
    if ~exist('mvpa_dir','var')||isempty(mvpa_dir), mvpa_dir = fullfile(mr_dir,'mvpa'); dispi('[mvpa_decoding] empty mvpa_dir defaulted to ',mvpa_dir, verbose); end;
    if ~exist('mvpa_analysis','var')||isempty(mvpa_analysis), mvpa_analysis = 'wholebrain'; dispi('[mvpa_decoding] empty mvpa_analysis defaulted to ',mvpa_analysis, verbose); end;
    if ~exist('gray_flag','var')||isempty(gray_flag), gray_flag = 0; dispi('[mvpa_decoding] empty gray_flag defaulted to ',gray_flag, verbose); end;
    if ~exist('dtName','var')||isempty(dtName), dtName = 'GLM_default'; dispi('[mvpa_decoding] empty dtName defaulted to ',dtName, verbose); end;
    if ~exist('predictors','var')||isempty(predictors), predictors = [1,2]; warni('[mvpa_decoding] empty predictors defaulted to ',predictors, ' only. It is important that you choose the correct ones here', verbose); end;

% first check for existence of directories
    dispi('We are running a ', mvpa_analysis,' MVPA with ', nbRuns,' runs from a dataType called: ', dtName, verbose)
    dispi('Our mrVista session is: ', mr_dir, verbose)
    check_folder(mr_dir, 1, verbose); %needs to exist
    dispi('and the mvpa folder is :', mvpa_dir, verbose)
    check_folder(mvpa_dir, 0, verbose); %is created if does not exist
    
    if gray_flag==1, dispi('We run the MVPA on gray voxels only', verbose)
    else dispi('We run the MVPA on all voxels', verbose)
    end
    
% load the beta maps, one voxel on each column and concatenates the predictors on each line
% and issues the resulting betamps, chunks and labels variables
    if gray_flag==1
        betamap_dir=fullfile(mr_dir,'Gray',dtName,'RawMaps');
    else
        betamap_dir=fullfile(mr_dir,'Inplane',dtName,'RawMaps');
    end
    betamaps=[];
    chunks=[];
    labels=[];

    
    for beta=predictors
        %check that nbRuns is as expected. This is because GLMs are added serially to the map array
        % and it cannot be suppressed, so if one makes an error, you obtained extra slots in the array
        % If this happens, you should delete the map completely (or the GLM) and runs it without error
        currentBetaFile= fullfile(betamap_dir,['betas_predictor',num2str(beta)]) ;
        load(currentBetaFile) %this one loads map and mapName
        dispi('We load: ',currentBetaFile,verbose)
        %careful here: the run predictor is added as last betas_predictor and the first ones are your other 
        % predictors. Fixation (code 0 in the model) is never a predictor
        if numel(map)~=nbRuns
           errori('Map size is incorrect: it should be ', nbRuns, ' and it is ', numel(map), verbose)
        end

        for i=1:nbRuns
            this_run_map = map{i};
            betamaps = [betamaps;this_run_map(:)'];
            chunks=[chunks;i];
            labels=[labels;beta];
        end

        clear map
    end
    
    dispi('We are now running the decoding MVPA on betamaps of size ',size(betamaps), verbose)
    dispi('Run structure is:', verbose); disp(chunks);
    dispi('Labels structure is:', verbose); disp(labels)

% builds the cfg structure from default and our passed data
    n_voxel= size(betamaps, 2);
    cfg = decoding_defaults();
    tdt_dir = cfg.toolbox_path;
    cfg.results.dir=fullfile(tdt_dir,'decoding_results');
    cfg.analysis = mvpa_analysis;
    cfg.results.overwrite = 1;
    cfg.results.output = {'accuracy', 'accuracy_minus_chance'};

    cfg.files.chunk=chunks;
    cfg.files.label=labels;
    all_chunks = unique(cfg.files.chunk);
    all_labels = unique(cfg.files.label);

    % save a description
    ct = zeros(length(all_labels),length(all_chunks));
    for ifile = 1:length(cfg.files.label)
        curr_label = cfg.files.label(ifile);
        curr_chunk = cfg.files.chunk(ifile);
        f1 = all_labels==curr_label; f2 = all_chunks==curr_chunk;
        ct(f1,f2) = ct(f1,f2)+1; %that is simply a counter for items in that chunck/class
        cfg.files.name(ifile) = {sprintf('label%i_run%i_%i', curr_label, curr_chunk, ct(f1,f2))};
    end
    dispi('Label / Run counter gives:')
    disp(ct)

    % add an empty mask
    cfg.files.mask = '';

    % Prepare data for passing
    passed_data.data = betamaps;
    passed_data.mask_index = 1:n_voxel; % use all voxels
    passed_data.files = cfg.files;
    passed_data.hdr = ''; % we don't need a header, because we don't write img-files as output (but mat-files)
    passed_data.dim = [n_voxel, 1, 1]; % add dimension information of the original data

    %%import design and regressor names from spm dir
    %regressor_names = design_from_spm(beta_dir); % beta_dir is directory of SPM model
    %cfg = decoding_describe_data(cfg,{'left','right'},[1 -1],regressor_names,beta_dir);   % 1 -1 are arbitrary label numbers for red & green

    %creates cross-validation with leave-1-out design
    cfg.design = make_design_cv(cfg);
    dispi('This is a leave-one-run-out design for cross validation', verbose)
    %dispi('This is NOT a leave-one-run-out design for cross validation but ', verbose)
    %dispi('a leave-two-runs-out design', verbose)
    %cfg.design = transform_L1O_into_L2O(cfg.design);

    dispi(cfg)
    dispi(cfg.decoding)
    dispi(cfg.results)
    
% run mvpa
    %results = decoding(cfg);
    [results, cfg] = decoding(cfg, passed_data);

% export results in a map readable for mr_vista
    load(fullfile(cfg.results.dir, 'res_accuracy_minus_chance.mat'))
    
    switch cfg.analysis
        case('wholebrain')
            dispi('Resulting accuracy for whole brain, compared to chance level was ', results.accuracy_minus_chance.output, '%', verbose)
            dispi('Result is not saved in a map but in a file called wholebrain_Res', verbose)
            accuracy_minus_chance = results.accuracy_minus_chance.output;
            save(fullfile(mvpa_dir,'wholebrain_Res'), 'accuracy_minus_chance');
        case('searchlight')
                figure()
                hist(results.accuracy_minus_chance.output,14)
                resultPos=results.accuracy_minus_chance.output;
                resultPos(resultPos<0)=0;
            if gray_flag==1
                map={results.accuracy_minus_chance.output'};
                mapPos={resultPos'};
            else
                map={reshape(results.accuracy_minus_chance.output,[90 90 38])};
                mapPos={reshape(resultPos,[90 90 38])};
            end
            mapName='acc_chance_searchlight';
            save(fullfile(mvpa_dir,'acc_chance_searchlight'), 'map','mapName','mapPos');
    end
    
