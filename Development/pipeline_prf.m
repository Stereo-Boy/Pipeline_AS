function params = pipeline_prf(steps, subj_dir, subjID, params, notes_dir, varargin)
% params = pipeline_prf(steps, subj_dir, subjID, params, notes_dir, ['verboseOFF'], ['errorON'], ['overwrite'])
% 
% Inputs:
% steps - number or numberic array of steps to run (default is 0, see below)
% subj_dir - string subject directory (default is pwd)
% subjID - string subject id (default is '')
% params - structure containing fields used as variables in the pipeline;
% to see defaults, type pipeline_prf without arguments
% notes_dir - string directory to save notes (default is ''; none)
% 'verboseOFF' - prevent displays in command window (default is 'verboseON')
% 'errorON' - throw error if checks prior to each step fail (default is 'errorOFF')
% 'overwrite' - overwrite previous output files/folders
%
% Outputs: 
% params - structure containing fields used as variables in the pipeline
% params.outputs{step} will contain any outputs from each step run
%
% Usage: 
%
% Steps available to run:
%   0.  All of the below steps
%   1.  nifti conversion
%   2.  segmentation using freesurfer
%   3.  correction of gray mesh irregularities 
%   4.  nifti header repair 
%   5.  removal of ''pRF dummy'' frames
%   6.  slice timing correction
%   7.  motion correction
%   8.  motion outliers
%   9.  initialization of mrVista session
%   10. alignment of inplane and volume
%   11. segmentation installation
%   12. mesh creation
%   13. pRF model
%
% Written Nov 2016
% Justin Theiss and Adrien Chopin
% Legacy Adrien Chopin, Sara Popham late Aug 2015
% From the work made by Eunice Yang, Rachel Denison, Kelly Byrne, Summer
% Sheremata

% init step_names
step_names = {'1.  nifti conversion',...
  '2.  segmentation using freesurfer',...
  '3.  correction of gray mesh irregularities',...
  '4.  nifti header repair',... 
  '5.  removal of dummy frames',...
  '6.  slice timing correction',...
  '7.  motion correction',...
  '8.  motion outliers',...
  '9.  initialization of mrVista session',...
  '10. alignment of inplane and volume',...
  '11. segmentation installation',...
  '12. mesh creation',...
  '13. pRF model'};

% if no inputs, return and display all defaults
if nargin==0, 
    help(mfilename); 
    % display default params
    disp('Default params:');
    for x = 1:numel(step_names),
        clear params fields values;
        dispi(step_names{x});
        params = local_getparams(struct, x, 'defaults'); 
        fields = fieldnames(params); values = struct2cell(params);
        cellfun(@(x,y)dispi(' ', x, ': ', y), fields, values);
    end
    % return all defaults
    params = local_getparams(struct, 1:numel(step_names), 'defaults');
    return; 
end

% if steps==0, set to all
if ~exist('steps','var')||all(steps==0), steps = 1:numel(step_names); end;
if ~exist('params','var')||isempty(params), % set params and return if none
    params = local_getparams(struct, steps, 'set'); 
    params = local_getparams(params, steps, 'defaults');
    return;
elseif ischar(params) && exist(params,'file'), % load params if char and file
    % copy params file
    tmpfile = tempname(pwd);
    params_file = params;
    copyfile(params, [tmpfile,'_params.mat']);
    disp(['Parameters copied in temporary file: ', tmpfile, '_params.mat']);
    load(params);
elseif isa(params, 'function_handle'), % load using params function
    params = feval(params);
end

% get original fields
orig_fields = fieldnames(params);

% set notes_dir, verbose, err
if ~exist('notes_dir','var')||isempty(notes_dir), notes_dir = ''; end;
if ~any(strcmp(varargin,'verboseOFF')), verbose = 'verboseON'; else verbose = 'verboseOFF'; end;
if ~any(strcmp(varargin,'errorON')), err = 'errorOFF'; else err = 'errorON'; end;
if ~any(strcmp(varargin,'overwrite')), overwrite = false; else overwrite = true; end;

% get defaults from params based on steps
params = local_getparams(params, steps, 'defaults');

% set params as variables within function
fields = fieldnames(params);
values = struct2cell(params);
cellfun(@(x,y)assignin('caller', x, y), fields(:), values(:));

% display fields set as default
diff = ~ismember(fields, orig_fields);
if any(diff),
    dispi('Defaults set:', verbose);
    cellfun(@(x,y)dispi(x, ': ', y, verbose), fields(diff), values(diff));
end

% set outputs in params
if ~isfield(params,'outputs'), params.outputs = cell(max(steps),1); end;
if ~iscell(params.outputs), params.outputs = {params.outputs}; end;

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
    record_notes(notes_dir, mfilename);
end

% display inputs
dispi(mfilename,'\nsteps:\n',steps,'\nsubj_dir:\n',subj_dir,'\nsubjID:\n',...
    subjID,'\nparams:\n',params,'\nerror:\n',err,verbose);

try
% run each step
for x = steps
    % display step
    dispi(repmat('-',1,20),'Running step ', step_names{x},' ',repmat('-',1,20),verbose);
    
    % get fields and values for current step
    [~, fields] = local_getparams(params, x, 'defaults');
    
    % append dir to subj_dir with local_fullfile
    dir_idx = ~cellfun('isempty',regexp(fields,'.*_dir$'));
    if any(dir_idx), % set directors to values in current context
        for n = find(dir_idx)
            tmp = local_fullfile(subj_dir,eval(fields{n}));
            eval([fields{n} '= tmp;']);
        end
    end
    
    % delete previous outputs if overwriting
    if overwrite && numel(params.outputs) >= x,
        remove_dir(params.outputs{x}, 's', verbose);
    end
    
    % check fields prior to step
    local_stepchecks(fields, err, verbose);
    
    % switch step
    switch x
        case 1 % nifti conversion
            % get dcm dirs
            dcm_dirs = get_dir(dcm_dir,dcm_expr); 
            % run nifti_convert
            params.outputs{x} = nifti_convert(dcm_dirs,'-o',ni_dir,dcm_args{:},verbose);
        case 2 % segmentation using freesurfer
            segmentation(subjID,ni_dir,seg_dir,verbose);
            % set outputs
            params.outputs{x} = get_dir(seg_dir,'*.nii*');
        case 3 % correction of gray mesh irregularities
            % check for t1_class_edited file
            if ~check_exist(seg_dir,t1_expr,1,err,verbose),
                if check_exist(seg_dir,'*t1*.nii*',1,err,verbose),
                    % rename t1_file with "_edited" appended
                    t1_file = get_dir(seg_dir, '*t1*.nii*', 1);
                    t1_edit_file = strrep(t1_file, '.nii', '_edited.nii');
                    copyfile(t1_file, t1_edit_file);
                    % throw warning that user should check t1_file
                    warning_error('Renaming ', t1_file, ' as "_edited" for later steps.\n',...
                        'However, this file should be manually checked for irregularities.',...
                        verbose);
                end
            else % set t1_edit_file to get_dir(seg_dir,t1_expr)
                t1_edit_file = get_dir(seg_dir, t1_expr, 1);
            end
            % set outputs
            params.outputs{x} = t1_edit_file;
        case 4 % nifti header repair TODO: switch with step 5
            dispi('Copying ',fullfile(ni_dir,nifix_expr),' to ',nifix_dir,verbose);
            copyfile(fullfile(ni_dir,nifix_expr),nifix_dir);
            % fix headers
            fixHeader(nifix_dir,nifix_expr,...
                'freq_dim',1,'phase_dim',2,'slice_dim',3,...
                'slice_end','eval(ni.dim(3)-1)',...
                'slice_duration','eval((numel(ni.pixdim)>3)*ni.pixdim(end)/ni.dim(3))');
            % set outputs
            params.outputs{x} = get_dir(nifix_dir,nifix_expr);
        case 5 % removal of ''pRF dummy'' frames TODO: need separate folder?
            % get epis
            epis = get_dir(epi_dir,epi_expr);
            % remove frames
            loop_feval(@remove_frames,epis(:),dummy_n,verbose);
            % set outputs
            params.outputs{x} = epis;
        case 6 % slice timing correction TODO: need separate folder
            % get epis
            epis = get_dir(epi_dir,epi_expr);
            % run slice time correction
            params.outputs{x} = slice_timing(epis, tr, slc_n, verbose, slc_args{:});
        case 7 % motion correction
            % copy files
            dispi('Copying ',fullfile(epi_dir,slc_expr),' to ',mc_dir,verbose);
            copyfile(fullfile(epi_dir,slc_expr),mc_dir);
            % switch ref_type for inputs
            clear mc_type;
            mc_type{1} = ref_type; 
            switch ref_type,
                case 'reffile' % get reference file
                    mc_type{2} = get_dir(ref_dir,ref_expr,1);
                    mc_type{3} = ref_n; 
                case 'refvol' % use each file as reference
                    mc_type{2} = ref_n;
                case 'meanvol' % mean volume
                    if ~isempty(ref_expr),
                        mc_type{2} = get_dir(ref_dir,ref_expr,1);
                    end
            end
            % motion correction
            motion_correction(mc_dir,slc_expr,mc_type,mc_args{:},verbose);
            % set outputs
            params.outputs{x} = get_dir(mc_dir,mc_expr);
        case 8 % motion outliers
            params.outputs{x} = motion_outliers(mc_dir,mc_expr,mo_args{:});
            dispi('Outliers:\n', params.outputs{x}, verbose);
        case 9 % initialization of mrVista session
            % get gems, mprage
            gems = get_dir(nifix_dir,gems_expr,1);
            mprage = get_dir(seg_dir,vol_expr,1);
            % init session
            close all;
            init_session(mr_dir,mc_dir,'inplane',gems,'functionals',mc_expr,...
                'vAnatomy',mprage,'sessionDir',mr_dir,'subject',subjID);
            % set outputs
            params.outputs{x} = get_dir(mr_dir,'mr*.mat');
        case 10 % alignment of inplane and volume
            % get gems, mprage, ipath
            ref = get_dir(nifix_dir,gems_expr,1);
            vol = get_dir(seg_dir,vol_expr,1);
            ipath = get_dir(dcm_dir,i_expr,1);
            % run alignment
            xform = alignment(mr_dir,vol,ref,ipath,align_n);
            dispi('Resulting xform matrix:\n',xform,verbose);
            % extract performance
            [avgcorr, sumrmse] = extractAlignmentPerfStats(mr_dir,ref_slc_n,verbose);
            params.outputs{x} = {avgcorr, sumrmse};
            close('all');
        case 11 % segmentation installation
            install_segmentation(mr_dir,seg_dir,epi_dir,verbose);
            % set outputs
            params.outputs{x} = get_dir(epi_dir,'*t1_class*.nii*'); 
        case 12 % mesh creation
            t1_file = get_dir(seg_dir,t1_expr,1);
            create_mesh(mr_dir,mesh_dir,t1_file,iter_n,gray_n,verbose);
            % set outputs
            params.outputs{x} = get_dir(mesh_dir,'*.mat');
        case 13 % pRF model
            params.outputs{x} = pRF_model(mr_dir,mc_dir,mc_expr,prf_type,prf_params,stim_fun,true,verbose);
        case 14 % mesh visualization of pRF values
        case 15 % extraction of flat projections
        case 16 % exp epi: actual GLM model
        otherwise % unknown step
            warning_error('Step ',x,' not understood',verbose);
    end
end
catch ME % if error, return with err_msg
    err_msg = getReport(ME, 'extended', 'hyperlinks', 'off');
    dispi(err_msg, verbose);
    record_notes('off');
    return;
end

% display done
dispi(repmat('-',1,20),'Pipeline finished ',dateTime,repmat('-',1,20),verbose);

% update tmpfile
if exist('params_file','var'),
    save(params_file, 'params', '-append');
end

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
            fields = cat(2, fields, {'dcm_dir','dcm_expr','dcm_args','ni_dir'}); 
            values = cat(2, values, {'Raw_DICOM', '*/', {'-f','%f'}, 'nifti'});
        case 2 % segmentation using freesurfer
            fields = cat(2, fields, {'ni_dir','seg_dir'});
            values = cat(2, values, {'nifti','Segmentation'});
        case 3 % correction of gray mesh irregularities
            fields = cat(2, fields, {'seg_dir','t1_expr'});
            values = cat(2, values, {'Segmentation','*t1_class_edited*.nii*'});
        case 4 % nifti header repair
            fields = cat(2, fields, {'ni_dir','nifix_dir','nifix_expr'});
            values = cat(2, values, {'nifti','niftiFix','*.nii*'});
        case 5 % removal of "pRF dummy" frames
            fields = cat(2, fields, {'dummy_n','epi_dir','epi_expr'});
            values = cat(2, values, {5,'niftiFix','epi*.nii*'});
        case 6 % slice timing correction
            fields = cat(2, fields, {'epi_dir','epi_expr','tr','slc_n','slc_args','slc_expr'});
            values = cat(2, values, {'niftiFix','epi*.nii*',1.8,24,{'prefix',''},'epi*.nii*'});
        case 7 % motion correction
            fields = cat(2, fields, {'epi_dir','slc_expr','mc_dir','mc_expr',...
                'ref_type','ref_dir','ref_expr','ref_n','mc_args'});
            values = cat(2, values, {'niftiFix','epi*.nii*','MoCo','*_mcf.nii*',...
                'reffile','nifti','epi*.nii*',1,{'-plots','-report','-cost mutualinfo','-smooth 16'}});
        case 8 % motion outliers
            fields = cat(2, fields, {'mc_dir','mc_expr','mo_args'});
            values = cat(2, values, {'MoCo','*_mcf.nii*',{'--nomoco','--dvars'}});
        case 9 % initialization of mrVista session
            fields = cat(2, fields, {'nifix_dir','seg_dir','mc_dir','epi_expr',...
                'mr_dir','vol_expr','gems_expr'});
            values = cat(2, values, {'niftiFix','Segmentation','MoCo','epi*_mcf.nii*',...
                'mrVista_Session','*nu_RAS*.nii*','gems*.nii*'});
        case 10 % alignment of inplane and volume
            fields = cat(2, fields, {'nifix_dir','gems_expr','seg_dir','vol_expr',...
                'dcm_dir','i_expr','mr_dir','ref_slc_n','align_n'});
            values = cat(2, values, {'niftiFix','gems*.nii*','Segmentation','*nu_RAS*.nii*',...
                'Raw_DICOM','gems*','mrVista_Session',24,1:5});
        case 11 % segmentation installation
            fields = cat(2, fields, {'mr_dir','seg_dir','epi_dir'});
            values = cat(2, values, {'mrVista_Session','Segmentation','niftiFix'});
        case 12 % mesh creation
            fields = cat(2, fields, {'seg_dir','t1_expr','mr_dir','mesh_dir','iter_n','gray_n'});
            values = cat(2, values, {'Segmentation','*t1_class_edited*.nii*','mrVista_Session','Mesh',600,3});
        case 13 % pRF model
            fields = cat(2, fields, {'mr_dir','mc_dir','mc_expr','prf_type','prf_params','stim_fun'});
            values = cat(2, values, {'mrVista_Session','MoCo','*_mcf.nii*',3,[],@make8Bars});
        case 14 % mesh visualization of pRF values
            fields = cat(2, fields, {});
            values = cat(2, values, {});
    end 
end
% get fields from params
user_fields = fieldnames(params);
% determine fields to set
def_fields = fields;
def_values = values;
values = values(~ismember(fields(:), user_fields(:)));
fields = fields(~ismember(fields(:), user_fields(:))); 
% set values to default fields
if strcmp(type,'set'), 
    fields = unique(fields);
    params = create_params(params, fields);
elseif strcmp(type,'defaults'), % return default params
    params = create_params(params, fields, values);
    % return default fields/values
    fields = def_fields;
    values = def_values;
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
    idx = idx(~cellfun(@(x)iscell(x),values(idx)));
    % check exist with dir and other fields
    check_exist(values{x}, values{idx}, verbose, err);
end
end
