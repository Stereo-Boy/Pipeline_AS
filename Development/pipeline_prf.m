function params = pipeline_prf(steps, subj_dir, subjID, params, notes_dir, varargin)
% params = pipeline_prf(steps, subj_dir, subjID, params, notes_dir, ['verboseOFF'], ['errorON'])
% 
% Inputs:
% steps - number or numberic array of steps to run (default is all, see below)
% subj_dir - string subject directory (default is pwd)
% subjID - string subject id (default is '')
% params - structure containing fields used as variables in the pipeline;
% to see defaults, type pipeline_prf without arguments
% notes_dir - string directory to save notes (default is ''; none)
% 'verboseOFF' - prevent displays in command window (default is 'verboseON')
% 'errorON' - throw error if checks prior to each step fail (default is 'errorOFF')
%
% Outputs: 
% params - structure containing fields used as variables in the pipeline
% params.output{step} will contain any outputs from each step run
%
% Steps available to run:
%   0.  All of the below steps
%   1.  nifti conversion
%   2.  nifti header repair
%   3.  correction of gray mesh irregularities
%   4.  segmentation using freesurfer
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
    params = local_getparams(struct, 1:15, 'defaults'); 
    fields = fieldnames(params); values = struct2cell(params);
    disp('Default params:');
    cellfun(@(x,y)dispi('    ', x, ': ', y), fields, values);
    return; 
end;
% if steps==0, set to all
if ~exist('steps','var')||all(steps==0), steps = 1:15; end;
if ~exist('params','var')||isempty(params), % set params if none
    params = local_getparams(struct, steps, 'set'); 
elseif ischar(params), % load params if char
    load(params);
end; % set notes_dir, verbose, err
if ~exist('notes_dir','var')||isempty(notes_dir), notes_dir = ''; end;
if ~any(strcmp(varargin,'verboseOFF')), verbose = 'verboseON'; end;
if ~any(strcmp(varargin,'errorON')), err = 'errorOFF'; end;

% get defaults from params based on steps
params = local_getparams(params, steps, 'defaults');

% set params as variables within function
fields = fieldnames(params);
values = struct2cell(params);
cellfun(@(x,y)assignin('caller', x, y), fields(:), values(:));

% set outputs in params
if ~isfield(params,'outputs'), params.outputs = cell(max(steps),1); end;
if ~iscell(params.outputs), params.outputs = {params.outputs}; end;
params.outputs(steps) = {[]};

% init subj_dir, subjID
if ~exist('subj_dir','var')||isempty(subj_dir), subj_dir = pwd; end;
if ~exist('subjID','var')||isempty(subjID), subjID = ''; end;

% run record_notes
if ~isempty(notes_dir),
    % get full path or append to subj_dir
    notes_dir = local_fullfile(subj_dir,notes_dir);
    % check notes_dir exists
    check_exist(notes_dir, verbose);
    % record notes
    record_notes(notes_dir,mfilename);
end

% display inputs
dispi(mfilename,'\nsteps:\n',steps,'\nsubj_dir:\n',subj_dir,'\nsubjID:\n',...
    subjID,'\nparams:\n',params,'\nerror:\n',err,verbose);

try
% run each step
for x = steps
    % display step
    dispi(repmat('-',1,20),'Running step ', x,repmat('-',1,20),verbose);
    
    % get fields for previous steps and current step
    [~, fields] = local_getparams(params, 1:x-1, 'defaults');
    [~, newfields] = local_getparams(params, x, 'defaults');
     
    % append dir to subj_dir with local_fullfile
    dir_fields = regexp([fields, newfields],'.*_dir$','match');
    dir_fields = [dir_fields{:}];
    if ~isempty(dir_fields), % evaluate dir_fields in current context
        if ~iscell(dir_fields), dir_fields = {dir_fields}; end;
        cellfun(@(x)assignin('caller',x,local_fullfile(subj_dir,eval(x))),dir_fields);
    end
    
    % check fields prior to step
    local_stepchecks(fields, err, verbose);
    % check fields for current step
    local_stepchecks(newfields, verbose);
    
    % switch step
    switch x
        case 1 % nifti conversion
            % get dcm dirs
            dcm_dirs = get_dir(dcm_dir,dcm_expr); 
            % run dcm2niix
            loop_system('dcm2niix','-z y','-f %f','-o',ni_dir,dcm_dirs(:),verbose);
        case 2 % nifti header repair
            dispi('Copying ',fullfile(ni_dir,nifix_expr),' to ',nifix_dir,verbose);
            copyfile(fullfile(ni_dir,nifix_expr),nifix_dir);
            fixHeader(nifix_dir,nifix_expr,'freq_dim',1,'phase_dim',2,'slice_dim',3);
        case 3 % segmentation using freesurfer
            segmentation(subjID,ni_dir,seg_dir,verbose);
        case 4 % correction of gray mesh irregularities
            %%%%%
        case 5 % removal of ''pRF dummy'' frames
            % get epis
            epis = get_dir(nifix_dir,nifix_expr);
            % remove frames
            loop_feval(@remove_frames,epis(:),dummy_n,verbose);
        case 6 % motion correction
            % copy files
            dispi('Copying ',fullfile(nifix_dir,nifix_expr),' to ',mc_dir,verbose);
            copyfile(fullfile(nifix_dir,nifix_expr),mc_dir);
            % get gems file
            gems = get_dir(ref_dir,ref_expr,1);
            % motion correction
            motion_correction(mc_dir,nifix_expr,{'reffile',gems,1},...
                '-plots','-report','-cost mutualinfo','-smooth 16',verbose);
        case 7 % motion outliers
            params.outputs{x} = motion_outliers(mc_dir,mc_expr,'--nomoco','--dvars');
            dispi('Outliers:\n', params.outputs{x}, verbose);
        case 8 % initialization of mrVista session
            % get gems, mprage
            gems = get_dir(ni_dir,ref_expr,1);
            mprage = get_dir(seg_dir,vol_expr,1);
            % init session
            close all;
            init_session(mr_dir,mc_dir,'inplane',gems,'functionals',epi_expr,...
                'vAnatomy',mprage,'sessionDir',mr_dir,'subject',subjID);
        case 9 % alignment of inplane and volume
            % get gems, mprage, ipath
            ref = get_dir(ni_dir,ref_expr,1);
            vol = get_dir(seg_dir,vol_expr,1);
            ipath = get_dir(dcm_dir,i_expr,1);
            % run alignment
            xform = alignment(mr_dir,vol,ref,ipath,align_n);
            dispi('Resulting xform matrix:\n',xform,verbose);
            % extract performance
            [avgcorr, sumrmse] = extractAlignmentPerfStats(mr_dir,ref_slc_n,verbose);
            params.outputs{x} = {avgcorr, sumrmse};
            close('all');
        case 10 % segmentation installation
            install_segmentation(mr_dir,seg_dir,ni_dir,verbose);
        case 11 % mesh creation
            t1_file = get_dir(seg_dir,t1_expr,1);
            create_mesh(mr_dir,mesh_dir,t1_file,iter_n,gray_n,verbose);
        case 12 % pRF model
            pRF_model(mr_dir,epi_dir,epi_expr,prf_params,true,verbose);
        case 13 % mesh visualization of pRF values
        case 14 % extraction of flat projections
        case 15 % exp epi: actual GLM model
        otherwise % unknown step
            warning_error('Step ',x,' not understood',verbose);
    end
end
catch err % if error, return
    getReport(err, 'extended', 'hyperlinks', 'off');
    record_notes('off');
    return;
end

% display done
dispi(repmat('-',1,20),'Pipeline finished ',dateTime,repmat('-',1,20),verbose);

% turn off record notes
record_notes('off');
end

function [params, fields, values] = local_getparams(params, steps, type)
% set or get defaults from parameters for each step in steps
%
% input params will be not be overwritten. 
% fields from each step will be set using create_params if type is 'set'. 
% fields from each step will be set with defaults if type is 'defaults'

% init type
if ~exist('type','var')||isempty(type), type = ''; end;
% return default fields/values for each step
fields = {}; values = {};
% for each step, set default fields
for x = steps,
    switch x,
        case 1 % nifti conversion
            fields = cat(2, fields, {'dcm_dir','dcm_expr','ni_dir'}); 
            values = cat(2, values, {'Raw_DICOM', '*/', 'nifti'});
        case 2 % nifti header repair
            fields = cat(2, fields, {'nifix_dir','nifix_expr'});
            values = cat(2, values, {'niftiFix','epi*.nii*'});
        case 3 % segmentation using freesurfer
            fields = cat(2, fields, {'seg_dir'});
            values = cat(2, values, {'Segmentation'});
        case 4 % correction of gray mesh irregularities
            fields = cat(2, fields, {});
            values = cat(2, values, {});
        case 5 % removal of "pRF dummy" frames
            fields = cat(2, fields, {'dummy_n'});
            values = cat(2, values, {5});
        case 6 % motion correction
            fields = cat(2, fields, {'mc_dir','mc_expr','ref_dir','ref_expr'});
            values = cat(2, values, {'MoCo','*_mcf.nii*','nifti','gems*.nii*'});
        case 7 % motion outliers
            fields = cat(2, fields, {});
            values = cat(2, values, {});
        case 8 % initialization of mrVista session
            fields = cat(2, fields, {'mr_dir','vol_expr'});
            values = cat(2, values, {'mrVista_Session','*nu_RAS*.nii*'});
        case 9 % alignment of inplane and volume
            fields = cat(2, fields, {'vol_dir','i_expr','ref_slc_n','align_n'});
            values = cat(2, values, {'Segmentation','gems*',24,1:5});
        case 10 % segmentation installation
            fields = cat(2, fields, {});
            values = cat(2, values, {});
        case 11 % mesh creation
            fields = cat(2, fields, {'mesh_dir','t1_expr','iter_n','gray_n'});
            values = cat(2, values, {'Mesh','*t1_class_edited*.nii*',600,4});
        case 12 % pRF model
            fields = cat(2, fields, {'epi_dir','epi_expr','prf_params'});
            values = cat(2, values, {'MoCo','epi*_mcf.nii*',[]});
        case 13 % mesh visualization of pRF values
            fields = cat(2, fields, {});
            values = cat(2, values, {});
        case 14 % extraction of flat projections
            fields = cat(2, fields, {});
            values = cat(2, values, {});
        case 15 % exp epi: actual GLM model
            fields = cat(2, fields, {});
            values = cat(2, values, {});
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

function fullpath = local_fullfile(varargin)
% returns fullfile concatenation of varargin starting with first existing
% directory as follows:
% -gets paths, files, and extensions for each input,
% -finds last full path and sets as base path,
% -concatenates all inputs including and following base path. 
%
% example: 
% fullpath = local_fullfile('/Users/subj01','/Users/subj01/other','nifti')
%
% fullpath =
%
% '/Users/subj01/other/nifti'

% get paths, files, exts
[paths, files, exts] = cellfun(@(x)fileparts(x), varargin, 'UniformOutput', 0);
% get basepaths
basepaths = paths;
basepaths(cellfun('isempty',basepaths)) = [];
% find idx of last path
idx = find(strcmp(paths,basepaths{end}),1,'last');
% concatenate basepath, files, file.ext
fullpath = fullfile(basepaths{end},files{idx:end-1},[files{end},exts{end}]);
end

function local_stepchecks(fields, varargin)
% runs check_exist on dirs and files for each field with 'verboseOFF' and
% 'errorON' as optional inputs. fields with _dir ending are checked first,
% then check_exist is run with other fields that start with the same
% beginning as e.g. check_exist(field_dir, field_expr, field_n)

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
% display fields being checked
dispi('Checking fields:\n',fields(:),verbose);
% for each field, eval for value
values = cell(size(fields));
for x = 1:numel(fields),
    values{x} = evalin('caller',fields{x});
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