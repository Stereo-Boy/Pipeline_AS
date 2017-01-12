function slc_files = slice_timing(files, tr, slc_n, verbose, varargin)
% slc_files = slice_timing(files, tr, slc_n, ...)
% Run SPM's slice timing correction on files
%
% Inputs:
% files - cellstr, files to be slice time corrected
% tr - number, repetition time for files
% slc_n - number, number of slices for files
% verbose - 'verboseOFF' or 'verboseON' (default)
% varargin - other arguments for spm_slice_timing:
%     'sliceorder' - order slices were acquired (default [1:2:slc_n, 2:2:slc_n]) 
%     'refslice' - reference slice for time 0 (default 1)
%     'timing' - timing parameters based on TR, TA (see spm_slice_timing for default)
%     'prefix' - character to prepend to output files (default 'a')
% 
% Outputs:
% slc_files - cellstr, files created by spm_slice_timing with prepended
% prefix
%
% Note: Files that are gzipped (.gz) will be unzipped and re-gzipped after
% slice timing since SPM does not work with .gz files.
%
% Example:
% files = {'epi_retino_11.nii.gz', 'epi_retino_12.nii.gz'};
% slc_files = slice_timing(files, 1.8, 24, 'verboseON', 'prefix', 'slc_')
%
% slc_files = 
% 
%     'slc_epi_retino_11.nii.gz'    'slc_epi_retino_12.nii.gz'
%
% Created by Justin Theiss

% init vars
slc_files = {};
if ~exist('files','var')||isempty(files), return; end;
if ~exist('tr','var')||isempty(tr), return; end;
if ~exist('slc_n','var')||isempty(slc_n), return; end;
if ~exist('verbose','var')||isempty(verbose), verbose = 'verboseON'; end;

% display inputs
dispi(mfilename,'\nfiles:\n',files,'\ntr:\n',tr,'\nslc_n:\n',slc_n,verbose);

% get extra arguments
cellfun(@(x,y)assignin('caller', x, y), varargin(1:2:end), varargin(2:2:end));

% get extension
[path,nifiles,ext] = cellfun(@(x)fileparts(x), files, 'UniformOutput', 0);

% gunzip if .gz
gz = strcmp(ext, '.gz');
if any(gz),
    % get gz files
    gzfiles = files(gz);
    % loop feval gunzip
    loop_feval(@gunzip, gzfiles(:), verbose);
    % set files to nifiles
    files(gz) = fullfile(path(gz),nifiles(gz));
end

% set P to files
P = char(cellstr(files));
% init spm_slice_timing variables
if ~exist('sliceorder','var'),
    sliceorder = [1:2:slc_n, 2:2:slc_n];
end
if ~exist('refslice','var'),
    refslice = 1;
end
if ~exist('timing','var'),
    ta = tr - (tr / slc_n);
    timing(1) = ta / (slc_n - 1);
    timing(2) = tr - ta;
end
if ~exist('prefix','var'),
    prefix = 'a';
end

% run spm slicetiming
loop_feval(@spm_slice_timing, P, sliceorder, refslice, timing, prefix, verbose);

% set output files
[path,sfiles,ext] = cellfun(@(x)fileparts(x), files, 'UniformOutput', 0);
slc_files = cellfun(@(x,y,z){fullfile(x, [prefix, y, z])}, path, sfiles, ext);

% gzip if .gz
if any(gz),
    % delete previous gz files
    delete(gzfiles{:});
    % get gz files
    gzfiles = slc_files(gz);
    % loop feval gzip
    loop_feval(@gzip, gzfiles(:), verbose);
    % delete previous nii files
    delete(files{gz});
    % set files with .gz
    slc_files(gz) = cellfun(@(x){[x, '.gz']}, slc_files(gz));
end
end