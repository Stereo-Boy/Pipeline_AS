function fixHeader(fix_dir, expr, varargin)
% fixHeader(fix_dir, expr, 'field', 'value',...,['verboseOFF'])
% 
% Inputs:
% fix_dir: string directory containing nifti files to correct headers
% (default is pwd)
% expr: string expression to find files in fix_dir (default is '*.nii*')
% varargin: header fields to fix followed by value to use
% 'verboseOFF': turn off verbose printout (default is 'verboseON')
%
% Outputs:
% nifti files saved with fixed header fields
%
% Example:
% fixHeader(fullfile(pwd,'05_nifti_fixed'),'epi*.nii.gz',...
%          'freq_dim',1,'phase_dim',2,'slice_dim',3)
%
% Created by Justin Theiss

% init defaults
if ~exist('fix_dir','var')||~exist(fix_dir,'dir'), fix_dir = pwd; end;
if ~exist('expr','var')||isempty(expr), expr = '*.nii*'; end;

% get verbose
if any(strncmp(varargin,'verbose',7)),
    verbose = varargin(strncmp(varargin,'verbose',7));
    varargin(strcmp(varargin,verbose)) = [];
else % default on
    verbose = 'verboseON';
end

% get fields and values from varargin
fields = varargin(1:2:end);
values = varargin(2:2:end);

% set vars for displaying
if ~isempty(fields) && ~isempty(values),
    vars = cellfun(@(x,y){{x,': ',y,'\n'}},fields,values);
    vars = cat(2,vars{:});
else % set vars to empty
    vars = {};
end

% display inputs
dispi(mfilename,'\nfix_dir: ',fix_dir,'\nexpr: ',expr,'\n',vars{:},verbose);

% get files
d = dir(fullfile(fix_dir,expr));
files = fullfile(fix_dir,{d.name});

% for each file, set headers
for x = 1:numel(files),
    % get nifti
    clear ni;
    ni = readFileNifti(files{x});
    % for each varargin, set header field
    for n = 1:numel(fields),
        ni.(fields{n}) = values{n};
    end
    % display file and nifti structure
    dispi('File ',x,': ',files{x},'\n',ni,verbose);
    % check qto
    ni = niftiCheckQto(ni);
    % write out nifti
    writeFileNifti(ni);
end
end