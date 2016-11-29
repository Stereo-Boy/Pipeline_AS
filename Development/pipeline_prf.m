function params = pipeline_prf(steps, subj_dir, subjID, params, verbose)
% params = pipeline_prf(steps, params, verbose)
% 
% Inputs:
% steps - number or numberic array of steps to run (see below)
% params - structure containing fields used as variables in the pipeline;
% to see defaults, type pipeline_prf without arguments
% verbose - 'verboseON' (default) or 'verboseOFF' to not display anything
% in the command window
% 
% Outputs: 
% params - structure containing fields used as variables in the pipeline
%
% Steps available to run:
%   0.  All of the below steps
%   1.  nifti conversion
%   2.  segmentation using freesurfer
%   3.  correction of gray mesh irregularities
%   4.  nifti header repair
%   5.  removal of ''pRF dummy'' frames
%   6.  motion correction
%   7.  motion outliers
%   8.  initialization of mrVista session
%   9.  alignment of inplane and volume
%   10. segmentation installation
%   11. mesh creation
%   12. pRF model
%   13. mesh visualization of pRF values
%   14. extraction of flat projections
%   15. exp epi: actual GLM model
%
% Written Nov 2016
% Justin Theiss and Adrien Chopin
% Legacy Adrien Chopin, Sara Popham late Aug 2015
% From the work made by Eunice Yang, Rachel Denison, Kelly Byrne, Summer
% Sheremata

% init vars
if nargin==0, 
    help(mfilename); 
    % get default params
    params = local_getparams(struct, 15, 'defaults'); 
    fields = fieldnames(params); values = struct2cell(params);
    disp('Default params:');
    cellfun(@(x,y)dispi('    ', x, ': ', y), fields, values);
    return; 
end;
if ~exist('steps','var')||steps==0, steps = 1:15; end;
if ~exist('params','var'), params = local_getparams(struct, steps, 'set'); end;
if ~exist('verbose','var'), verbose = 'verboseON'; end;

% get defaults from params based on steps
params = local_getparams(params, steps, 'defaults'); % verbose

% set params as variables within function
fields = fieldnames(params);
values = struct2cell(params);
cellfun(@(x,y)assignin('caller', x, y), fields(:), values(:));

% run record_notes
if exist('notes_dir','var'),
    % record notes
    record_notes(notes_dir,mfilename);
end

% display inputs
dispi(mfilename,'\nsteps:\n',steps,'\nparams:\n',params,verbose);

% run each step
for x = steps
    % display step
    dispi('Running step ', x, verbose);
    
    % get fields for previous steps and current step
    [~, fields] = local_getparams(params, x-1, 'defaults');
    [~, newfields] = local_getparams(params, x);
    
    % check fields prior to step and new fields
    local_stepchecks(params, fields, 'errorON', verbose);
    local_stepchecks(params, newfields, verbose);
    
    % switch step
    switch x
        case 1 % nifti conversion
            % get dcm dirs
            dcm_dirs = get_dir(dcm_dir, dcm_expr);
            % run dcm2niix
            loop_system('dcm2niix','-z y','-f %f','-o',dcm_dirs(:),verbose);
        case 2 % segmentation using freesurfer
            segmentation(subjID, ni_dir, fullfile(subj_dir,'Segmentation'), verbose);
        case 3 % correction of gray mesh irregularities
        case 4 % nifti header repair
            fixHeader(fix_dir,fix_expr); % 
        case 5 % removal of ''pRF dummy'' frames
            % get epis
            epis = get_dir(ni_dir, epi_expr);
            % remove frames
            loop_feval(@remove_frames, epis(:), dummy_n, verbose);
        case 6 % motion correction
            % get gems file
            gems = get_dir(ni_dir, ref_expr, 1);
            % motion correction
            motion_correction(mc_dir, epi_expr, {'reffile', gems, 1},...
                   '-plots','-report','-cost mutualinfo','-smooth 16',verbose);
        case 7 % motion outliers
            % fsl_motion_outliers
            bad_trs = motion_outliers(ni_dir, '-p', fullfile(ni_dir,'motion_params.png'), '--dvars');
            dispi('Outliers:\n', bad_trs, verbose);
        case 8 % initialization of mrVista session
            % get gems, mprage
            gems = get_dir(fullfile(mr_dir,ni_dir), gems_expr, 1);
            mprage = get_dir(fullfile(mr_dir,seg_dir), mprage_expr, 1);
            % init session
            close all;
            init_session(mr_dir,fullfile(mr_dir,'nifti'),'inplane',gems,...
                'functionals',epi_expr,'vAnatomy',mprage,...
                'sessionDir',mr_dir,'subject', subjID);
        case 9 % alignment of inplane and volume
            % get gems, mprage, ipath
            vol = get_dir(fullfile(mr_dir,ni_dir), vol_expr, 1);
            ref = get_dir(fullfile(mr_dir,seg_dir), ref_expr, 1);
            ipath = get_dir(dcm_dir, vol, 1);
            % run alignment
            xform = alignment(mr_dir, vol, ref, ipath);
            dispi('Resulting xform matrix:\n', xform, verbose);
            % extract performance
            extractAlignmentPerfStats(mr_dir, ref_slc_n, verbose);
        case 10 % segmentation installation
            initialPath = pwd; cd(mr_dir);
            install_segmentation(mr_dir, fullfile(mr_dir,seg_dir),...
                fullfile(mr_dir,ni_dir), verbose);
            cd(initialPath);
        case 11 % mesh creation
            initialPath = pwd; cd(mr_dir);
            create_mesh(fullfile(mr_dir,mesh_dir), 600, verbose);
            cd(initialPath);
        case 12 % pRF model
        case 13 % mesh visualization of pRF values
        case 14 % extraction of flat projections
        case 15 % exp epi: actual GLM model
        otherwise % unknown step
            dispi('Step ', x, ' not understood', verbose);
    end
end

% display done
dispi(repmat('-',1,40),'Pipeline finished ',dateTime,repmat('-',1,40),verbose);

% turn off record notes
record_notes('off');
end

function [params, fields] = local_getparams(params, steps, type)
    % return default fields/values for each step
    fields = {}; values = {};
    % set subjID, subj_dir, and notes_dir
    fields = cat(2, fields, 'subjID', 'subj_dir', 'notes_dir');
    values = cat(2, values, 'Subj01', pwd, 'notes');

    % for each step, set default fields
    for x = 1:max(steps),
        switch x,
            case 1 % nifti conversion
                fields = cat(2, fields, {'dcm_dir','dcm_expr','ni_dir'}); 
                values = cat(2, values, {'Raw', '*', 'nifti'});
            case 2 % segmentation using freesurfer
                fields = cat(2, fields, {'seg_dir'});
                values = cat(2, values, {'Segmentation'});
            case 3 % correction of gray mesh irregularities
                fields = cat(2, fields, {});
                values = cat(2, values, {});
            case 4 % nifti header repair
                fields = cat(2, fields, {'nifix_dir','nifix_expr'});
                values = cat(2, values, {'niftiFixed','*.nii.gz'});
            case 5 % removal of "pRF dummy" frames
                fields = cat(2, fields, {'epi_expr','dummy_n'});
                values = cat(2, values, {'*epi*.nii.gz',5});
            case 6 % motion correction
                fields = cat(2, fields, {'mc_dir','ref_expr'});
                values = cat(2, values, {'MoCo',''});
            case 7 % motion outliers
                fields = cat(2, fields, {});
                values = cat(2, values, {});
            case 8 % initialization of mrVista session
                fields = cat(2, fields, {'mr_dir'});
                values = cat(2, values, {'08_mrVista_Session'});
            case 9 % alignment of inplane and volume
                fields = cat(2, fields, {'vol_expr','ref_slc_n'});
                values = cat(2, values, {'', 24});
            case 10 % segmentation installation
                fields = cat(2, fields, {'mr_dir','vol_expr','ref_expr'});
                values = cat(2, values, {'','',''});
            case 11 % mesh creation
                fields = cat(2, fields, {'mesh_dir'});
                values = cat(2, values, {'Mesh'});
            case 12 % pRF model
                fields = cat(2, fields, {});
                values = cat(2, values, {});
            case 13 % mesh visualization of pRF values
                fields = cat(2, fields, {});
                values = cat(2, values, {});
            case 14 % extraction of flat projections
                fields = cat(2, fields, {});
                values = cat(2, values, {});
            case 15 % exp epi: actual GLM model
                fields = cat(2, fields, {});
                values = cat(2, values, {});
            otherwise %
        end 
    end

    % get fields from params
    user_fields = fieldnames(params);

    % determine fields to set
    def_fields = fields;
    fields = fields(~ismember(fields(:), user_fields(:))); 

    % set values to default fields
    if strcmp(type,'set'), 
        params = create_params(params, fields);
    elseif strcmp(type,'defaults') % return default params
        params = create_params(params, fields, values);
        % return default fields
        fields = def_fields;
    end
end

function local_stepchecks(params, fields, varargin)
    % get verboseOFF/errorON
    if any(strncmp(varargin,'verbose',7)),
        verbose = varargin{strncmp(varargin,'verbose',7)};
    else % default on
        verbose = 'verboseON';
    end
    if any(strncmp(varargin,'error',5)),
        err = varargin{strncmp(varargin,'error',5)};
    else % default off
        err = 'errorOFF';
    end

    % check params.fields
    values = cell(size(fields));
    for x = 1:numel(fields),
        values{x} = params.(fields{x});
    end

    % check if dir exist then for files/number 
    for x = find(~cellfun('isempty',regexp(fields,'.*_dir$'))),
        % check dir exists first
        check_exist(values{x}, verbose, err);
        % find other fields with same beginning
        strfield = regexprep(fields{x},'(\w+_).*','$1');
        idx = ~cellfun('isempty',regexp(fields, ['^',strfield,'[^(dir)]+']));
        % check exist with dir and other fields
        check_exist(values{x}, values{idx}, verbose, err);
    end
end