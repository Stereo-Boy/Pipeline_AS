function bad_trs = motion_parameters(mc_dir, varargin)
% bad_trs = motion_parameters(mc_dir, ...)
% Find bad TRs based on motion parameters and plot motion absolute
% translations across all runs.
% 
% Inputs:
% mc_dir: string directory containing motion correction .par files (default is pwd)
% other parameters:
%       'vox_factor' - use difference between TRs to find motion outliers
%           additional input can be number to multiply by voxel dimensions 
%           as criteria for bad TRs (default is 0.5)
%       'fsl' - run fsl_motion_outliers to find motion outliers. additional
%           inputs can be any fsl_motion_outliers option (see example)
%
% Outputs:
% bad_trs: array with first column containing epi indices and second column
%          containing bad TRs relative to epi
% motion_params.png image saved
% if 'fsl' is used, 'file_confound' files are saved containing matrix to be
% included in glm design t
%
% Created by Justin Theiss 11/2016

% init vars
if ~exist('mc_dir','var')||~exist(mc_dir,'dir'),
    mc_dir = pwd;
end
if ~exist('vox_factor','var'),
    vox_factor = 0.5;
end
if ~exist('verbose','var'),    verbose = 'verboseON';end

% get files
d = dir(fullfile(mc_dir,'epi*.par'));
files = fullfile(mc_dir,{d.name});
dispi('Working on ', numel(files),' EPI detected .par files (not gems)', verbose)

% get first epi nifti
clear d; d = dir(fullfile(mc_dir,'epi*.nii*'));
nifile = fullfile(mc_dir,d(1).name);

% get volume and voxel dims
ni = readFileNifti(nifile);
vox_dims = ni.pixdim(1:3);
vol_dims = ni.dim(1:3) .* vox_dims;

% params are rot x, y, z and trans x, y, z 
params = [];
for x = 1:numel(files),
    tmp = load(files{x}); 
    n_trs = size(tmp,1);
    params = cat(1,params,tmp);
end

% get absolute differences between trs
pdiff = abs(diff(params,1));

% create rotation matrix for each tr and find max abs changes
for t = 1:size(pdiff,1),
    % build matrix
    rot_mat = affineBuild([0,0,0], pdiff(t,1:3), [1,1,1], [0,0,0]);
    % remove 4th row and column
    rot_mat = rot_mat(1:3,1:3);
    % multiply by brain dims
    rot_delta = rot_mat * diag(vol_dims);
    % find max delta in each dim, transpose
    delta = max(abs(diag(vol_dims) - rot_delta), [], 2)';
    % add delta to translation params
    trans(t,:) = pdiff(1,4:end) + delta;
end

% find bad TRs
vox_arr = repmat(vox_dims * vox_factor, size(trans,1),1);
bool_tr = trans > vox_arr; 

% bad TRs are one index ahead since diff subtracts 2nd - 1st etc.
bad_trs(:,2) = find(any(bool_tr, 2)) + 1;

% plot translations
plot(2:(size(trans,1)+1), trans); hold on; h = gcf; %align TR parameters plots with bad TRs
ylabel('Abs Max Translation (mm)');
xlabel('Time (TR)'); 
if ~isempty(bad_trs),
    plot(bad_trs(:,2), max(trans(:)), 'kx');
    legend('X','Y','Z','Bad TRs');
else
    legend('X','Y','Z');
end
%show the threshold lines
plot(vox_arr, '--');
% save plot
saveas(h,fullfile(mc_dir,'Motion_params'),'png');

% find epis and relative TR indices
bad_trs(:,1) = ceil(bad_trs(:,2) / n_trs);
bad_trs(:,2) = mod(bad_trs(:,2), n_trs);

