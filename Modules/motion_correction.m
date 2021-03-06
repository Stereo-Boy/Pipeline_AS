function motion_correction(mc_dir, expr, type, varargin)
% motion_correction(mc_dir, expr, type, ...)
% 
% Inputs:
% mc_dir: string directory containing files to motion correct (default is pwd)
% expr: string expression for files to motion correct (default is *.nii*)
% type: cell array for type of reference for motion correction, one of
% the following:
%   'reffile' - uses reference 3d file. additional inputs can be specific
%               filename (or index of files) and index of TR to create image 
%               (default is middle file and middle TR, respectively)
%   'refvol'  - uses reference TR of each input file. additional inputs
%               can be index of TR (default is n/2)
%   'meanvol' - uses mean volume across TRs of each input file. additional 
%               input can be a file to create a mean reference volume 
%               (default is mean volume across TRs of each input)
% varargin: other options to input for mcflirt (e.g., '-plots','-report', etc.)
% 'verboseON': string option to turn on verbose printout (default is 'verboseOFF')
%
% Outputs created:
% *_mcf.nii.gz files are the motion corrected files
% *_mcf.par files contain the motion parameters
% 
% Example 1: motion correct all files in pwd using epi03 (default to middle TR bc no 3d arg in the {}) as reference
% motion_correction(pwd, [], {'reffile', 'epi03_retino_14.nii.gz'})
%
% Example 2: motion correct epi nifti files to the middle vol of each input file
% motion_correction(pwd, 'epi*.nii*', 'refvol','verbose',true)
%
% Example 3: motion correct gems file to mean of a specific file
% motion_correction(pwd, 'gems*.nii*', {'meanvol', 'epi03_retino_14.nii.gz'})
%
% Example 4: motion correct all nifti files in pwd using middle TR of
% middle epi
% motion_correction(pwd,'*.nii*','reffile','-plots','-report','-cost mutualinfo','-smooth 16')
%
% Created by Justin Theiss 11/2016

% init defaults
if ~exist('mc_dir','var')||~exist(mc_dir,'dir'),
    mc_dir = pwd;
end
if ~exist('expr','var')||isempty(expr),
    expr = '*.nii*';
end
if ~exist('type','var')||isempty(type),
    type = 'reffile';
end
if ~iscell(type), type = {type}; end;
if isempty(varargin), fsl_arg = ''; end;

% get verbose
if any(strncmp(varargin,'verbose',7)),
    verbose = varargin{strncmp(varargin,'verbose',7)}; if iscell(verbose); verbose=verbose{1}; end%otherwise does not work
    varargin(strcmp(varargin,verbose)) = [];
else % default on
    verbose = 'verboseON';
end

% display inputs
dispi(mfilename,'\nmc_dir: ',mc_dir,'\nexpr: ',expr,'\ntype: ',type,...
    '\nvarargin: ',varargin{:},verbose);

% get files
d = dir(fullfile(mc_dir,expr));
files = fullfile(mc_dir,{d.name});

% switch type 1
switch type{1}
    case 'reffile'
        if numel(type)==1, % default takes the middle epi
            dispi('Using middle epi as a reference (default)',verbose)
            n_file = round(numel(files) / 2);
            ni = readFileNifti(files{n_file});
        elseif isnumeric(type{2}), % index of files
            ni = readFileNifti(files{type{2}});
        else % load from varargin{1}
            ni = readFileNifti(type{2});
        end
        % if no second arg, default is TR n/2
        if numel(type) < 3 || isempty(type{3}),
            dispi('Using middle TR as a reference (default)',verbose)
            n_vol = round(ni.dim(end) / 2);
        else % otherwise set to varargin{2}
            n_vol = type{3};
        end
        % set data using n_vol
        ni.data = ni.data(:,:,:,n_vol);
        ni.dim = size(ni.data);
        ni.ndim = numel(ni.dim);
        % write ref_vol
        ni.fname = fullfile(mc_dir,'ref_vol.nii.gz');
        writeFileNifti(ni);
        % set fsl_arg
        fsl_arg = ['"' ni.fname '"'];
    case 'refvol'
        % using vol within file (default is middle vol)
        if numel(type) > 1,
            fsl_arg = num2str(type{2});
        end
    case 'meanvol'
        % if input, create mean of input file
        if numel(type) > 1,
            % change type to reffile
            type{1} = 'reffile';
            % get nifti structure of input file
            ni = readFileNifti(type{2});
            % take mean across TRs
            ni.data = mean(ni.data, 4);
            ni.dim = size(ni.data);
            ni.ndim = numel(ni.dim);
            % write ref_vol
            ni.fname = fullfile(mc_dir,'ref_vol.nii.gz');
            writeFileNifti(ni);
            % set fsl_arg
            fsl_arg = ['"' ni.fname '"'];
        end
    otherwise % error
        error('Unknown option');
end

% run mcflirt 
for x = 1:numel(files),
    % set sys_arg
    sys_arg = sprintf('%s ','mcflirt','-in',['"',files{x},'"'],['-',type{1}],fsl_arg,varargin{:});
    % display sys_arg
    dispi(sys_arg,verbose);
    % run system
    system(sys_arg);
end