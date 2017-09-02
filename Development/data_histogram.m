function outfile = data_histogram(infile, outfile, varargin)
% outfile = data_histogram(infile, outfile, ...)
% Display histogram, median, etc. for data
% Inputs:
% infile - string, nifti file containing data
% outfile - (optional) string, output filename to save figure
%   [default []]
% Additional options:
% 'maskfile' - string, nifti file to mask data
%   [default [], includes all data]
% 'metric' - string, name of metric for displaying
%   [default 'signal']
% 'thr' - numeric, number by which to threshold for displaying
%   "good voxels"
%   [default 0]
%
% Outputs:
% outfile - output .fig file (or empty)
%
% Example:
% infile = fullfile(pwd,'glm','R2.nii');
% outfile = fullfile(pwd,'glm','R2.fig');
% maskfile = fullfile(pwd,'glm','mask.nii');
% outfile = data_histogram(infile, outfile, 'maskfile', maskfile,...
% 'metric', 'variance explained', 'thr', 0.75)
%
% Median variance explained: 0.735
% Percent of good voxels (with variance explained >0.75): 34.8%
% Number of good voxels (with variance explained >0.75): 7722
% Average variance explained for the greatest 50% of voxels: 0.771
% Average variance explained for the greatest 5% of voxels: 0.839
%
% outfile =
% 
% /Users/glm/R2.fig
% 
% Created by Justin Theiss

% init infile, outfile
if ~exist('infile','var')||isempty(infile), error('No infile input.'); end;
if ~exist('outfile','var')||isempty(outfile), outfile = []; end;

% init defaults
vars = {'maskfile','metric','thr'};
vals = {[],'signal',0};
n_idx = ~ismember(vars, varargin(1:2:end));
defaults = cat(1, vars(n_idx), vals(n_idx));
varargin = cat(2, varargin, defaults(:)');

% set options
for x = 1:2:numel(varargin),
    eval([varargin{x} '= varargin{x+1};']);
end

% load nifti
ni = readFileNifti(infile);
data = single(ni.data);

% maskfile
if ~isempty(maskfile), 
    ni_mask = readFileNifti(maskfile);
    mask = logical(ni_mask.data);
else
    mask = true(size(data));
end
% get data within mask
data = data(mask);

% print median, number/percent of good voxels
fprintf('Median %s: %.3g\n', metric, median(data(:)));
fprintf('Percent of good voxels (with %s >%g): %.3g%%\n',...
        metric, thr, 100*sum(data(:)>thr)./numel(data(:)));
fprintf('Number of good voxels (with %s >%g): %g\n',...
        metric, thr, sum(data(:)>thr));
fprintf('Average %s for the greatest 50%% of voxels: %.3g\n',...
        metric, mean(data(data(:)>median(data(:)))));
% print metric for best 5%
limit = quantile(data(:), .95);
fprintf('Average %s for the greatest 5%% of voxels: %.3g\n',...
        metric, mean(data(data(:)>limit)));
    
% display histogram, 
f = figure('position', [360,500,800,800]);
subplot(2,2,1);
hist(data(:));
title(['Histogram of ', metric]);
xlabel(metric);
ylabel('Number of voxels');

% display boxplot
subplot(2,2,2);
boxplot(data(:));
title(['Boxplot of ', metric]);
ylabel(metric);

% best voxels
bestVox = sort(data(:),1,'descend');
n = round(0.05 * numel(data(:)));
subplot(2,2,3);
plot(1:n, bestVox(1:n));
title([metric, ' of best 5% of voxels']);
ylabel(metric);

% save figure
if ~isempty(outfile),
    savefig(f, outfile);
end
end