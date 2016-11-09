function motion_correction(mc_dir, expr, type, varargin)
% motion_correction(mc_dir, expr, type, ...)
% 
% Inputs:
% mc_dir: string directory containing files to motion correct (default is pwd)
% expr: string expression for files to motion correct (default is *.nii*)
% type: string option for type of reference for motion correction, one of
% the following:
%   'reffile' - uses reference 3d file. additional inputs can be specific
%               filename and index of volume to create image (default is
%               middle file and middle volume, respectively)
%   'refvol'  - uses reference volume of each input file. additional inputs
%               can be index of volume (default is n/2)
%   'meanvol' - uses mean volume of each input file. additional input can
%               be a file to create a mean reference volume (default is
%               mean volume of each input)
% 
% Outputs created:
% *_mcf.nii.gz files are the motion corrected files
% *_mcf.par files contain the motion parameters
% 
% Example 1: motion correct all files in pwd using epi03 as reference
% motion_correction(pwd, [], 'reffile', 'epi03_retino_14.nii.gz')
%
% Example 2: motion correct epi nifti files to the middle vol of each input file
% motion_correction(pwd, 'epi*.nii*', 'refvol')
%
% Example 3: motion correct gems file to mean of a specific file
% motion_correction(pwd, 'gems*.nii*', 'meanvol', 'epi03_retino_14.nii.gz')
%
% Example 4: motion correct all nifti files in pwd using middle TR of
% middle epi
% motion_correction(pwd, '*.nii*', 'reffile')

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
if isempty(varargin), fsl_arg = ''; end;

% get files
d = dir(fullfile(mc_dir,expr));
files = fullfile(mc_dir,{d.name});

switch type
    case 'reffile'
        if isempty(varargin), % default takes the middle epi
            n_file = round(numel(files) / 2);
            ni = readFileNifti(files{n_file});
        else % load from varargin{1}
            ni = readFileNifti(varargin{1});
        end
        % if no second arg, default is TR n/2
        if numel(varargin) < 2,
            n_vol = round(ni.dim(end) / 2);
        else % otherwise set to varargin{2}
            n_vol = varargin{2};
        end
        % set data using n_vol
        ni.data = ni.data(:,:,:,n_vol);
        ni.dim = size(ni.data);
        ni.ndim = numel(ni.dim);
        % write ref_vol
        ni.fname = fullfile(mc_dir,'ref_vol.nii.gz');
        writeFileNifti(ni);
        %copy_files(cd,'ref_vol.nii.gz',mc_dir,'verboseOFF')
        % set fsl_arg
        fsl_arg = ['"' ni.fname '"'];
        
    case 'refvol'
        % using vol within file (default is middle vol)
        if ~isempty(varargin),
            fsl_arg = num2str(varargin{1});
        else
            disp('what happens here?')
        end
    case 'meanvol'
        % if input, create mean of input file
        if ~isempty(varargin),
            % change type to reffile
            type = 'reffile';
            % get nifti structure of input file
            ni = readFileNifti(varargin{1});
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
    system(['mcflirt -' type ' ' fsl_arg ' -plots -report -cost mutualinfo'...
    ' -smooth 16 -in "' files{x},'"']);
end
