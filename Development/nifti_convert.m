function ni_files = nifti_convert(fld, varargin)
% ni_files = nifti_convert(fld, 'field', 'value',... [,'verboseOFF']) 
% 
% Inputs:
% fld - string or cellstr of path(s) of directories containing dicom files
% to convert
%
% Other inputs for dcm2niix:
%   -b : BIDS sidecar (y/n, default n)
%   -f : filename (%a=antenna  (coil) number, %c=comments, %d=description,
% %e echo number, %f=folder name, %i ID of patient, %m=manufacturer, 
% %n=name of patient, %p=protocol, %s=series number, %t=time, 
% %u=acquisition number, %z sequence name)
%   -m : merge 2D slices from same series regardless of study time, echo, 
% coil, orientation, etc. (y/n, default n)
%   -o : output directory (omit to save to input folder)
%   -s : single file mode, do not convert other images in folder (y/n, default n)
%   -t : text notes includes private patient details (y/n, default n)
%   -v : verbose (y/n, default n)
%   -x : crop (y/n, default n)
%   -z : gz compress images (y/i/n, default y) [y=pigz, i=internal, n=no]
%
% Other inputs:
% 'verboseOFF' - Turn off command prompt text (default is 'verboseON')
%
% Outputs:
% ni_files - cell array of paths to newly created nifti files
%
% Example:
% dcm_dirs = fullfile('/Users/Raw_DICOM',{'ep01','ep02','t1_mprage_03'});
% ni_files = nifti_convert(dcm_dirs, '-o', '/Users/Nifti', '-f', {'epi_1','epi_2','mprage'})
%
% Created by Justin Theiss

% init vars
if ~exist('fld','var')||isempty(fld), fld = pwd; end;
if ~iscell(fld), fld = {fld}; end;
if ~any(strncmp(varargin,'verbose',7)),
    verbose = 'verboseON';
else % verboseOFF and remove
    verbose = varargin{strncmp(varargin,'verbose',7)};
    varargin(strncmp(varargin,'verbose',7)) = [];
end

% get out directories
if ~any(strcmp(varargin,'-o')),
    out_dir = fld;
else
    out_dir = varargin{find(strcmp(varargin,'-o'))+1};
    if ~iscell(out_dir), out_dir = {out_dir}; end;
end

% run dcm2niix with loop_system
loop_system('dcm2niix',varargin{:},fld(:),verbose);

% return newly created files
ni_files = cell(size(out_dir));
for x = 1:numel(out_dir),
    ni_files{x} = get_dir(out_dir{x}, '*.nii*');
end
ni_files = [ni_files{:}];
end