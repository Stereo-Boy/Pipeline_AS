function xform = alignment(sessionDir, vol, ref, ipath, steps, verbose)
% xform = alignment(sessionDir, vol, ref, ipath, steps)
%
% Automated alignment:
% 1. run fsl brain extraction
% 2. run mrvista coarse alignment
% 3. run mrvista fine alignment 
% 4. run mrvista Nestares fine alignment
%
% Inputs:
% sessionDir : string full path to mrvista session directory (default is pwd)
% vol : string full path to volume file (e.g. MV40_nu_RAS_NoRS.nii.gz file)
% ref : string full path to reference file (e.g. gems.nii.gz file)
% ipath : string full path to folder containing .dcm files for ref file
% steps : [optional] numeric array corresponding to the above steps to be run [default=1:4]
%
% Outputs:
% xform : realignment transformation matrix (also saved to mrSESSION.mat file)
%
% Created by Justin Theiss 10/16
%(adapted from mrvista rxFineMutualInf and rxFineNestares)

% init vars
if ~exist('sessionDir','var')||isempty(sessionDir), sessionDir = pwd; end;
if ~exist('vol','var')||isempty(vol),
    [f,p] = uigetfile('*.nii.gz','Choose volume:');
    vol = fullfile(p,f);
end;
if ~exist('ref','var')||isempty(ref),
    [f,p] = uigetfile('*.nii.gz','Choose reference:');
    ref = fullfile(p,f);
end;
if ~exist('steps','var')||isempty(steps), steps = 1:4; end;
if ~exist('verbose','var')||isempty(verbose), verbose = 'verboseON'; end;
if ~any(steps==2),
  ipath = [];
elseif any(steps==2) && (~exist('ipath','var')||isempty(ipath)),
    ipath = uigetdir(cd,['Choose I*.dcm folder path for ' ref]);
end;
xform = [];

%% 1. run fsl brain extraction
if any(steps==1),
% create filenames with _brain appended
[p,f,e] = fileparts(vol);
[~,f,e2] = fileparts(f);
vol_b = fullfile(p,[f '_brain' e2 e]);
[p,f,e] = fileparts(ref);
[~,f,e2] = fileparts(f);
ref_b = fullfile(p,[f '_brain' e2 e]);

% run fsl brain extraction
system(['bet "' vol '" "' vol_b '" -R;'...
    'bet "' ref '" "' ref_b '" -R;']);

% get vol_data as rxAlign does
[vol_data, volVoxelSize] = readVolAnat(vol_b);

% get ref_data as rxAlign does
vw = loadAnat(struct('viewType','Inplane'),ref_b);
ref_data = viewGet(vw,'Anatomy Data');
refVoxelSize = viewGet(vw,'Voxel Size');
else % if not running bet
% get vol_data as rxAlign does
[vol_data, volVoxelSize] = readVolAnat(vol);

% get ref_data as rxAlign does
vw = loadAnat(struct('viewType','Inplane'),ref);
ref_data = viewGet(vw,'Anatomy Data');
refVoxelSize = viewGet(vw,'Voxel Size');
end;

%% 2. spm_coreg (coarse alignment; taken from rxFineMutualInf)
if any(steps==2),
    dispi('Step 2', verbose)
% get ref and vol data as uint8
VG.uint8 = uint8(ref_data);
VF.uint8 = uint8(vol_data);

% get xform to scanner coords (some serious voodoo in that last line)
xformToScanner = computeXformFromIfile(ipath);
xformToScanner = inv( xformToScanner );
xformToScanner(1:3,4) = xformToScanner([1:3],4) + [10 -20 -20]';

% set ref mat
VG.mat = xformToScanner;

% set volume mat
hsz = size(vol_data) ./ 2;
res = volVoxelSize;
VF.mat = [0 0 res(3) -hsz(3); ...
          0 -res(2) 0 hsz(1); ...
          -res(1) 0 0 hsz(2); ...
          0 0 0 1];

% set flag
flags.sep = [8 4 2];

% get rot/trans from spm_coreg
rotTrans = spm_coreg(VG, VF, flags);

% build alignment matrix
xform = VF.mat \ spm_matrix(rotTrans) * VG.mat;

% apply axial flip
shift = [eye(3) -size(ref_data)'./2; 0 0 0 1];
xform = shift * xform / shift;
[trans, rot] = affineDecompose(xform);
scale = [-1,1,1] .* refVoxelSize ./ volVoxelSize;
xform = affineBuild(trans,rot,scale,[0,0,0]);
xform = shift \ xform * shift;
end;

%% 3. Mutual Information (fine alignment; taken from rxFineMutualInf)
if any(steps==3),
    dispi('Step 3', verbose)
    % set sep to [4,2]
    flags.sep = [4,2];
    % set tolerances for rotations and translations
    flags.tol = [0.005 0.005 0.005 0.001 0.001 0.001];
    % set params in flags to account for coarse alignment
    revAlignment = spm_imatrix(VF.mat * xform / VG.mat);
    flags.params = revAlignment(1:6);
    % run spm_coreg
    rotTrans = spm_coreg(VG, VF, flags);
    % build alignment matrix
    xform = VF.mat \ spm_matrix(rotTrans) * VG.mat;
end;

%% 4. Nestares (further fine alignment; taken from rxFineNestares)
if any(steps==4),
    dispi('Step 4', verbose)
% switch rows and columns because mrvista is terrible
% flip to (x,y,z) instead of (y,x,z):
xform(:,[1 2]) = xform(:,[2 1]);
xform([1 2],:) = xform([2 1],:);

% set params for regVolInp
coarseIterations = 4; % number of coarse iterations
gradFunction = 'regEstFilIntGrad'; % func. to estimate intensity gradient
pbyp = 0;  % Plane by Plane flag = 0 (=>works globaly)
A = xform(1:3,1:3);
b = xform(1:3,4)';
scaleFac(1,:) = 1./refVoxelSize;  % inverse voxel size for reference and
scaleFac(2,:) = 1./volVoxelSize; % prescribed volumes
rot = diag(1./scaleFac(2,:))*A*diag(scaleFac(1,:)); % rot matrix
trans = b ./ scaleFac(2,:);         % translation factors

% ensure the volumes are double-precision: the Nestares code requires this
if ~isa(vol_data, 'double'), vol_data = double(vol_data); end;
if ~isa(ref_data, 'double'), ref_data = double(ref_data); end;

% run registration
[rot, trans] = regVolInp(vol_data, ref_data, scaleFac, rot, trans, coarseIterations, gradFunction, pbyp);

% convert into a 4x4 affine xform matrix
A = diag(scaleFac(2,:)) * rot * diag(1./scaleFac(1,:));
b = (scaleFac(2,:) .* trans)';
xform = zeros(4,4);
xform(1:3,1:3)=A;
xform(1:3,4)=b;
xform(4,4)=1;

% switch rows and columns because mrvista is terrible
% flip to (x,y,z) instead of (y,x,z):
xform(:,[1 2]) = xform(:,[2 1]);
xform([1 2],:) = xform([2 1],:);
end;

    dispi('Saving...', verbose)
% save to mrSESSION.mat
if exist(fullfile(pwd,'mrSESSION.mat'), 'file'),
load(fullfile(pwd, 'mrSESSION.mat'), 'mrSESSION');
mrSESSION.alignment = xform;
save(fullfile(pwd, 'mrSESSION.mat'), 'mrSESSION', '-append');
dispi('The found xform was saved as the current mrSESSION alignment', verbose)
end;
