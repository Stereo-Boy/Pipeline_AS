function [outfile, xform] = applyxform(infile, varargin)
% outfile = applyxform(infile, ...)
% Apply transformation matrix to data
% 
% Inputs:
% infile - char, filename of data to apply transformation
% additional arguments:
% 'xform' - numeric, transformation matrix to apply to data
%   [default eye(4)]
% 'interp_method' - char, interpolation method (see interp3)
%   [default 'spline']
% 'ref' - char, filename of reference data
%   [default []]
% 'dim' - numeric, matrix dimensions (overrides ref dim)
%   [default []]
% 'pixdim' - numeric, pixel dimensions (overrides ref pixdim)
%   [default []]
% 'coreg' - boolean, run @spm_coreg to obtain xform
%   [default false]
% 'flags' - struct, flags to input to @spm_coreg (see @spm_coreg for more
%   information)
%   [default [], which sets @spm_coreg defaults]
% 'reslice' - boolean, run @spm_reslice to reslice data into ref space
%   [default false]
% 'outfile' - char, filename of output to save data. 
%   [default [] (no output)]
% 
% Outputs:
% outfile - char, filename of nifti file with applied transformations
% xform - numeric, transformation applied or returned from spm_coreg
%
% Example: coregister gems to anatomical and output xform
% infile = fullfile(pwd,'nifti','gems.nii');
% reffile = fullfile(pwd,'nifti','mprage.nii');
% [~, xform] = applyxform(infile, 'ref', reffile, 'coreg', true)
% 
% SPM12: spm_coreg (v6435)
% ========================================================================
% Completed
%     0.9982   -0.0190   -0.0569   -4.8849
%     0.0170    0.9992   -0.0355   -1.9239
%     0.0575    0.0344    0.9978  -17.9937
%          0         0         0    1.0000
% 
% 
% xform =
% 
%     0.9982   -0.0190   -0.0569   -4.8849
%     0.0170    0.9992   -0.0355   -1.9239
%     0.0575    0.0344    0.9978  -17.9937
%          0         0         0    1.0000
%          
% Note: If coreg is true, reslice does not need to be run as data will
% already be resliced to ref space.
%
% Created by Justin Theiss

% defaults
vars = {'xform', 'ref', 'dim', 'pixdim', 'interp_method', 'coreg', 'flags', 'reslice', 'outfile'};
defaults = {[], [], [], [], 'spline', false, [], false, []};
n_idx = ~ismember(vars, varargin(1:2:end));
addvars = cat(1, vars(n_idx), defaults(n_idx));
varargin = cat(2, varargin, addvars(:)');

% init vars
for x = 1:2:numel(varargin),
    eval([varargin{x} '= varargin{x+1};']);
end

% load data
ni = readFileNifti(infile);
if ~isempty(ref), 
    n1 = readFileNifti(ref);
else
    n1 = ni;
end

% run spm_coreg
if coreg,
    xform = local_coreg(infile, ref, flags);
end

% apply xform
if ~isempty(xform),
    ni = local_xform(ni, n1, xform, interp_method);
end

% reslice to new space
if reslice,
    ni = local_reslice(ni, n1, interp_method, dim, pixdim);
end

% write nifti
if ~isempty(outfile),
    ni.fname = outfile;
    writeFileNifti(ni);
end
end

function xform = local_coreg(infile, ref, flags)

% run spm_coreg
VG = spm_vol(ref);
if numel(VG) > 1, VG = VG(1); end;
VF = spm_vol(infile);
if numel(VF) > 1, VF = VF(1); end;
X = spm_coreg(VG, VF, flags);
xform = spm_matrix(X);
disp(xform);
end

function ni = local_xform(n0, n1, xform, interp_method)

% load data
if n0.ndim == 4,
    data = double(n0.data(:,:,:,1)); 
else 
    data = double(n0.data);
end
data(isnan(data)) = 0;

% get coords
[x,y,z] = ind2sub(n1.dim(1:3), 1:prod(n1.dim(1:3)));
coords = cat(1, x, y, z, ones(1, prod(n1.dim(1:3))));

% apply transform to coords
coords = n0.qto_xyz \ xform * n1.qto_xyz * coords;

% interp
data = interp3(data, coords(2,:), coords(1,:), coords(3,:), interp_method, 0);

% reshape
data = reshape(data, n1.dim(1:3));

% output nifti
ni = niftiCreate('data', data, 'pixdim', n1.pixdim(1:3), 'qto_xyz', n1.qto_xyz);
end

function ni = local_reslice(n0, n1, interp_method, dim, pixdim)

if isempty(dim), dim = n1.dim(1:3); end;
if isempty(pixdim), pixdim = n1.pixdim(1:3); end;

% load data
if n0.ndim == 4,
    data = double(n0.data(:,:,:,1)); 
else 
    data = double(n0.data);
end
data(isnan(data)) = 0;

% get scale difference
scale = pixdim ./ n0.pixdim(1:3);

% resample each dim
newdims = arrayfun(@(x,y){1:x:y}, scale, n0.dim(1:3));
[xmat, ymat, zmat] = ndgrid(newdims{1}, newdims{2}, newdims{3});

% interpolate
data = interp3(data, ymat, xmat, zmat, interp_method);

% pad with zeros
padsize = round(max(dim - size(data), [0,0,0]) ./ 2);
data = padarray(data, padsize, 0, 'both');
data = data(1:dim(1), 1:dim(2), 1:dim(3));

% output nifti
ni = niftiCreate('data', data, 'pixdim', pixdim, 'qto_xyz', n0.qto_xyz, 0);
end