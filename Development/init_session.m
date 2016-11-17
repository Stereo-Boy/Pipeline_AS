function init_session(mr_dir, nifti_dir, varargin)
% init_session(mr_dir, nifti_dir, 'param1', 'value1', ...)
% Initiate mrvista session
% 
% Inputs:
% mr_dir: string directory where the mrvista session will exist (default is pwd)
% nifti_dir: string directory where relevant nifti files exist (default is 
% mr_dir/nifti)
% other parameters: parameters to set or update (see below for defaults)
%   'inplane': file to set as inplane (default is nifti_dir'/gems.nii.gz')
%   'functionals': functional epi files (default is nifti_dir'/epi*.nii*')
%   'vAnatomy': file to set for anatomical (default is nifti_dir'/mprage.nii.gz')
%   'sessionDir': directory where mrvista session will exist (default is mr_dir)
%   'parfile': *.par files containing parameters for fmri scans (default is none)
%
% See mrInitDefaultParams for other parameters to set.
%
% Outputs saved:
% mrInit_params.mat file will be created/updated in mr_dir
%
% Example 1: initiate mrSESSION/dataTYPES with parfiles
% % set mr_dir and nifti_dir
% mr_dir = pwd;
% nifti_dir = fullfile(pwd, 'nifti');
% % initiate mrSESSION and dataTYPES
% init_session(mr_dir, nifti_dir, 'subject', 'MV40', 'parfile', fullfile(mr_dir,'Stimuli','Parfiles','*.par'));
%
% Note: if mrInit_params.mat file exists, params will be updated with given
% inputs, otherwise params will be initiated with mrInitDefaultParams and
% any inputs.
%
% Created by Justin Theiss 11/2016

% init params
if ~exist('mr_dir','var')||~exist(mr_dir,'dir'),
    mr_dir = pwd;
end
if ~exist('nifti_dir','var')||~exist(nifti_dir,'dir'),
    nifti_dir = fullfile(mr_dir,'nifti');
end
if isempty(varargin),
    % set defaults
    varargin = cell(1,8);
    varargin(1,1:2:end) = {'inplane','functionals','vAnatomy','sessionDir'};
    varargin(1,2:2:end) = {fullfile(nifti_dir,'*gems*.nii.gz'),...
        fullfile(nifti_dir,'epi*.nii*'),fullfile(nifti_dir,'*mprage*.nii.gz'),...
        mr_dir};
end
% get verbose
if any(strncmp(varargin,'verbose',7)),
    verbose = varargin{strncmp(varargin,'verbose',7)};
    varargin(strcmp(varargin,verbose)) = [];
else % default on
    verbose = 'verboseON';
end

% display inputs
dispi(mfilename,'\nmr_dir: ',mr_dir,'\nnifti_dir: ',nifti_dir,...
    '\nparams:\n',varargin(1:2:end)','\nvalues:\n',varargin(2:2:end)','\n',...
    verbose);

% get params from mrInit_parmas, if exists
if exist(fullfile(mr_dir,'mrInit_params.mat'),'file'),
    load(fullfile(mr_dir,'mrInit_params.mat'));
else % set default
    params = mrInitDefaultParams;
end

% set parameters using varargin
for x = 1:2:numel(varargin),
    % if *, set from dir
    if any(strfind(varargin{x+1},'*')),
        % if a directory is included, use that dir when searching
        tmp_dir = fileparts(varargin{x+1});
        % if no directory included, set to nifti_dir
        if isempty(tmp_dir), tmp_dir = nifti_dir; end;
        % get files using dir
        clear d; d = dir(fullfile(tmp_dir,varargin{x+1}));
        if ~isempty(d), 
            params.(varargin{x}) = fullfile(tmp_dir,{d.name}); 
        end;
    else % set directly
        params.(varargin{x}) = varargin{x+1};
    end
end

% display params
dispi(params, verbose);

% initialize the session
initialDir=pwd;
cd(mr_dir);
mrInit(params);
cd(initialDir);
return;


