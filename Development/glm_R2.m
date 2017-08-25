function  outfile = glm_R2(data_files, resMS_file, outfile, varargin)
% outfile = glm_R2(data_files, resMS_file, outfile, ...)
% Calculate R-squared of GLM
%
% Inputs:
% data_files: cellstr, filenames of data used in GLM
% resMS_file: string, filename of resMS.nii (error variance)
% outfile: string, filename to output R-squared nifti (none saved if empty)
%   [default []]
% optional arguments:
% 'maskfile': string, filename used to mask data
%   [default [], includes all data]
% 'plotfun': function, function used to plot data (saved to outfig)
%   [default @hist]
% 'outfig': string, filename to save figure
%   [default []]
% 
% Outputs:
% outfile: string, filename of R-squared nifti
%
% Example: calculate R-squared for GLM
% data_files = fullfile(pwd,'nifti',arrayfun(@(x){sprintf('repi_%.2d.nii',x)}, 1:8));
% resMS_file = fullfile(pwd,'glm','ResMS.nii');
% outfile = fullfile(pwd,'glm','R2.nii');
% maskfile = fullfile(pwd,'glm','mask.nii');
% outfile = glm_R2(data_files, resMS_file, outfile, 'maskfile', maskfile)
%
% outfile =
% 
% /Users/glm/R2.nii
%
% Note: calculation of R-squared is based on following equation:
% var(Y) = var(Yhat) + var(E)
% R2 = var(Yhat)/var(Y) = (var(Y) - var(E))/var(Y) = 1 - (var(E) / var(Y))
% http://www.brainvoyager.com/bvqx/doc/UsersGuide/StatisticalAnalysis/TheGeneralLinearModel.html
%
% Created by Justin Theiss

% init data_files, resMS_file, outfile
if ~exist('data_files','var')||isempty(data_files), error('No data_files input.'); end;
if ~exist('resMS_file','var')||isempty(resMS_file), error('No resMS_file input.'); end;
if ~exist('outfile','var')||isempty(outfile), outfile = []; end;

% init vars
vars = {'maskfile', 'plotfun', 'outfig'};
vals = {[], @hist, []};
n_idx = ~ismember(vars, varargin(1:2:end));
defaults = cat(1, vars(n_idx), vals(n_idx));
varargin = cat(2, varargin, defaults(:)');

% set defaults
for x = 1:2:numel(varargin),
    eval([varargin{x} '= varargin{x+1};']);
end

% load data and calculate variance
for x = 1:numel(data_files),
    ni = readFileNifti(data_files{x});
    var_y(:,:,:,x) = var(single(ni.data), 0, 4);
end
% take mean variance of data
varY = mean(var_y, 4);

% get error variance (resMS)
ni = readFileNifti(resMS_file);
varE = ni.data;

% calculate R-squared (see link below)
% http://www.brainvoyager.com/bvqx/doc/UsersGuide/StatisticalAnalysis/TheGeneralLinearModel.html
% var(Y) = var(Yhat) + var(E)
% R2 = var(Yhat)/var(Y) = (var(Y) - var(E))/var(Y) = 1 - (var(E) / var(Y))
R2 = 1 - varE ./ varY;

% load mask
if ~isempty(maskfile),
    ni = readFileNifti(maskfile);
    mask = logical(ni.data);
%     R2 = R2 .* single(mask);
else % otherwise set to true
    mask = true(size(R2));
end

% if function, feval
if ~isempty(plotfun),
    feval(plotfun, R2(mask));
    % save figure
    if ~isempty(outfig), 
        savefig(gcf, outfig);
    end
end

% output file
if ~isempty(outfile),
    ni.fname = outfile;
    ni.data = R2 .* mask;
    writeFileNifti(ni);
end
end