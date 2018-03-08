function average_frames(mc_dir, expr, outliers)
% average_frames(mc_dir, expr, outliers)
% Replace outlier frames in each file with the average of the same frame
% across the other files without an outlier at the frame.
%
% Inputs: 
% mc_dir: string directory of motion corrected files (default is pwd)
% expr: string expression of files to use (default is 'epi*_mcf.nii*')
% outliers: matrix of outlying frames in each file with columns
% corresponding to each file and rows corresponding to outlying frames
%
% Outputs:
% input files are updated
%
% Example: average frames based on outliers in six scans
% outliers = cat(2,[2;52;nan],[104;nan;nan],[3;52;nan],[30;33;87],[nan;nan;nan],[23;nan;nan]);
% average_frames(pwd, 'epi*_mcf.nii*', outliers) 
%
% Created by Justin Theiss 11/2016

% init defaults
if ~exist('mc_dir','var')||~exist(mc_dir,'dir'),
    mc_dir = pwd;
end
if ~exist('expr','var'), expr = 'epi*_mcf.nii*'; end;
if ~exist('outliers','var'), return; end;

% get files
d = dir(fullfile(mc_dir,expr));
files = fullfile(mc_dir,{d.name});

% load nifti files
for f = 1:numel(files),
    ni(f) = readFileNifti(files{f});
end

% for each outlier, average trs across other niftis
for o = unique(outliers(~isnan(outliers)))',
    % find columns containing x
    [~,n] = find(outliers == o);
    % if outlier in all scans, skip
    if isempty(setxor(1:size(outliers,2),n)),
        disp(['Frame ' num2str(o) ' is an outlier in all scans and cannot be averaged.']); 
        continue;
    end
    % get tr of other nifties
    tmp = arrayfun(@(x){ni(x).data(:,:,:,o)}, setxor(1:size(outliers,2),n));
    % mean after concatenating volumes
    mean_tr = mean(cat(4, tmp{:}), 4);
    % set mean_tr for each nifti in n
    for f = n,
        ni(f).data(:,:,:,o) = mean_tr;
    end
end

% write out each nifti
for f = 1:numel(files),
    writeFileNifti(ni(f));
end
return;

