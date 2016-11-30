function fslresample(infile, outfile, varargin)
% fslresample(infile, outfile, ...)
%
% resample infile using parameters such as volume/voxel size or the shape
% of a reference file
%
% Inputs:
% infile: string fullpath of file to resample
% outfile: string fullpath of resampled file (default is infile)
% optional inputs:
%   '-ref': file to use as reference file (for volume/voxel shape)
%   '-init': file containing transformation matrix to apply
%   'vol_sz': 3 parameters for volume size (as x, y, z)
%   'vox_sz': 3 parameters for voxel size (as x, y, z)
%   'verboseOFF': option to not display functions called
%
% Outputs:
% outfile saved from resampled infile
%
% Example 1: resample file to voxel/volume size of different file
% fslresample('gems.nii.gz', 'gems_resampled.nii.gz', '-ref', 'epi.nii.gz')
%
% flirt -in "gems.nii.gz" -out gems_resampled.nii.gz -ref "epi.nii.gz" -applyxfm
%
% Example 2: resample file to specific volume size but maintain voxel size
% fslresample('gems.nii.gz', 'gems_resampled.nii.gz', 'vol_sz', [90, 90, 24])
%
% fslcreatehd 90  90  24 1 0.75        0.75        2.32 1 0 0 0 4 tmpvol
% 
% flirt -in "gems.nii.gz" -out "gems_resampled.nii.gz" -ref tmpvol -applyxfm  
% 
% Example 3: resample file and apply transformation matrix without verbose
% fslresample('gems.nii.gz', 'gems_resampled.nii.gz', '-init', 'xform.mat', 'verboseOFF')
%
% Created by Justin Theiss 11/2016

% init vars
if ~exist('infile','var')||isempty(infile), return; end;
if ~exist('outfile','var')||isempty(outfile), outfile = infile; end;
if isempty(varargin), return; end;
args = {'',''};

% get verbose
if any(strncmp(varargin,'verbose',7)),
    verbose = varargin{strncmp(varargin,'verbose',7)};
    varargin(strcmp(varargin,verbose)) = [];
else % default on
    verbose = 'verboseON';
end

% switch varargin
for x =  1:2:numel(varargin),
    switch varargin{x}
        case '-ref' % reference file
            reffile = varargin{x+1};
        case '-init' % transformation matrix
            args = {'-init',varargin{x+1}};
        case 'vol_sz' % volume params
            vol_sz = varargin{x+1};
        case 'vox_sz' % voxel params
            vox_sz = varargin{x+1};
    end
end

% set reffile to infile if doesnt exist
if ~exist('reffile','var'), reffile = infile; end;

% if vol_sz or vox_sz, create tmpvol as reffile 
if exist('vol_sz','var') || exist('vox_sz','var'),
    % get nifti struct from reffile
    ni = readFileNifti(reffile); 
    % set vol_sz or vox_sz as needed
    if ~exist('vol_sz','var'), vol_sz = ni.dim(1:3); end;
    if ~exist('vox_sz','var'), vox_sz = ni.pixdim(1:3); end;
    % set reffile
    reffile = 'tmpvol';
    % run fslcreatehd
    loop_system('fslcreatehd',vol_sz,1,vox_sz,1,0,0,0,4,'tmpvol',verbose);
end

% run flirt
loop_system('flirt','-in',['"',infile,'"'],'-out',outfile,'-ref',reffile,'-applyxfm',args{:},verbose);

% delete tmpvol if exists
if exist('tmpvol.nii.gz', 'file'), delete('tmpvol.nii.gz'); end;
end
