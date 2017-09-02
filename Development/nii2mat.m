function outfile = nii2mat(infile, varargin)
% outfile = nii2mat(infile, ...)
% Convert .nii to .mat or vice versa for mrVista viewing.
%
% Inputs:
% infile - char, input file to convert (.mat/.nii/.nii.gz)
% additional arguments:
% 'mrtype' - either 'inplane' or 'anatomical' for the mrVista format going to/from
%   [default 'anatomical']
% 'field' - string, name of variable containing data or variable to save within
%   .mat file (see examples)
%   [default 'map{1}']
% 'outfile' - char, filepath to save converted file
%   [default 'output.mat' or 'output.nii.gz']
% 'coordsfile' - char, 'coords.mat' file (e.g. for anatomical mrtype)
%   [default []]
% 'ref' - char, reference nifti file for dim/pixdim (required for converting from .mat)
%   [default infile]
% 'roi' - boolean, create roi from .mat (usually need to set field = 'coords')
%   [default false]
%
% Example: mask results based on mrVista ROI
% infile = fullfile(pwd,'results.nii');
% mrtype = 'anatomical';
% outfile = fullfile(pwd,'results.mat');
% roifile = fullfile(pwd,'roi.mat');
% outnii = fullfile(pwd,'masked_results.nii');
% outfile = nii2mat(infile, 'mrtype', mrtype, 'coordsfile', roifile,...
%                   'outfile', outfile);
% outnii = nii2mat(outfile, 'mrtype', mrtype, 'coordsfile', roifile,...
%                  'outfile', outnii)
%
% outnii = 
%
% /Users/masked_results.nii
%
% Created by Justin Theiss

% defaults
vars = {'mrtype','field','outfile','coordsfile','ref','roi'};
defaults = {'anatomical', 'map{1}', 'output', [], [], false};
n_idx = ~ismember(vars, varargin(1:2:end));
addvars = cat(1, vars(n_idx), defaults(n_idx));
varargin = cat(2, varargin, addvars(:)');

% init vars
for x = 1:2:numel(varargin),
    eval([varargin{x} '= varargin{x+1};']);
end
    
% get ext
[~,~,ext] = fileparts(infile);

% get var
var = regexp(field, '^\w+', 'match', 'once');

% if .mat infile
if strcmp(ext, '.mat'),
    % load map
    load(infile, var);
    % set data from map
    eval(['data0 = ', field, ';']);
    % load ref
    n0 = readFileNifti(ref); 
    % set dim and pixdim
    dim = n0.dim; pixdim = n0.pixdim;
    % set roi
    if roi,
        data = false(dim);
        coords = data0;
        % set indices depending on size
        if size(coords, 1)==3,
            idx = sub2ind(dim, coords(1,:), coords(2,:), coords(3,:));
        else
            idx = coords;
        end
        % set roi as true
        data(idx) = true;
    % if coords, load and use to set data
    elseif ~isempty(coordsfile),
        load(coordsfile, 'coords');
        data = zeros(dim);
        % set based on coords
        idx = sub2ind(dim, coords(1,:), coords(2,:), coords(3,:));
        data(idx) = data0;
    else % reshape data
        if numel(size(data0)) == 3, dim = size(data0); end;
        data = reshape(data0, dim);
    end
    % if data already shaped, rot90 counterclockwise and flip
    if strcmp(mrtype, 'inplane'),
        data = flip(rot90(data, -1), 1);
    elseif strcmp(mrtype, 'anatomical'), % otherwise permute
        % permute (mrvista's horribleness)
        data = ipermute(flip(flip(data, 2), 1), [3, 2, 1]);
    end
    % set outfile
    [~,~,outext] = fileparts(outfile);
    if isempty(outext), outfile = [outfile, '.nii.gz']; end;
    % create nifti
    ni = niftiCreate('fname', outfile, 'data', double(data),...
                     'pixdim', pixdim, 'qto_xyz', n0.qto_xyz);
    % write nifti
    writeFileNifti(ni);
else % nifti
    n0 = readFileNifti(infile);
    data1 = n0.data;
    % if inplane, flip and rot90
    if strcmp(mrtype, 'inplane'),
        data1 = rot90(flip(data1, 1));
    elseif strcmp(mrtype, 'anatomical'), % otherwise permute for anatomical
        % permute (mrvista's horribleness)
        data1 = flip(flip(permute(data1, [3, 2, 1]), 1), 2);
    end
    % if roi
    if roi,
        % set data to indices of data1
        idx = find(data1);
        [data(1,:), data(2,:), data(3,:)] = ind2sub(size(data1), idx);
    % load coords
    elseif ~isempty(coordsfile),
        load(coordsfile, 'coords');
        idx = sub2ind(size(data1), coords(1,:), coords(2,:), coords(3,:));
        data = data1(idx);
    else % otherwise set data as is
        data = data1;
    end
    % set outfile
    [p, mapName] = fileparts(outfile); 
    outfile = fullfile(p, [mapName, '.mat']);
    % if map already exists in outfile, load
    if exist(outfile, 'file'), load(outfile, var); end;
    % set map
    eval([field, '= double(data);']);
    % save outfile
    if exist(outfile, 'file'),
        save(outfile, var, 'mapName', '-append');
    else
        save(outfile, var, 'mapName');
    end
end
end