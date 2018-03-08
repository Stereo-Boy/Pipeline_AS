function filename = par2onsets(parFile, varargin)
% filename = par2onsets(parFile,'param1','value1','param2','value2',...)
% Create onsets (.mat) file from par (.par) file (but any text file should 
% work). The onsets file can be used in SPM software. Durations certainly need to be provided
% in a separate parameter given mrVista PAR file typically do not provide the events or epoch durations
% Alternately, provide the special code 'specialCode' for the parameter 'durations' to be able to deduce
% the duration from the code column (fill the section below)
% 
% Inputs:
% parFile - string filename of par (or any text file) containing paradigm
% information in rows.
% Options
% 'column_names' - cell array of column names - this will typically contain the columns
% onsets, durations, and (conditions) names except if there are provided in the optional parameter below
% 'onsets' (optional) - cell array of onsets for manual input
% 'durations' (optional) - cell array of durations for manual input
% 'names' (optional) - cell array of names for manual input
% 'filename' (optional) - string filename to output for .mat file 
%   [default is parFile with .mat ending]
%
% Outputs:
% filename - string filename of saved .mat file containing onsets,
%   durations, and names to be used with SPM.
%
% Note: the text within the parFile should be organized as rows and tabbed
% columns. also if 'durations' is not listed in column_names, durations
% will be calculated by the sorted difference across onsets.
%
% Created by Justin Theiss

% set column names
if any(strcmp(varargin,'column_names')),
    column_names = varargin{find(strcmp(varargin,'column_names'),1)+1};
end
% set onsets manually 
if any(strcmp(varargin, 'onsets')), 
    onsets = varargin{find(strcmp(varargin,'onsets'),1)+1};
end
% set durations manually
if any(strcmp(varargin, 'durations')), 
    durations = varargin{find(strcmp(varargin,'durations'),1)+1};
end
% set names manually
if any(strcmp(varargin, 'names')), 
    names = varargin{find(strcmp(varargin,'names'),1)+1};
end
% set filename manually
if any(strcmp(varargin, 'filename')), 
    filename = varargin{find(strcmp(varargin,'filename'),1)+1};
end

if strcmp(durations,'specialCode') %deduce the durations from the code column with the following mapping:
    % (replace with your experiment values) - careful code and idx of durations are off by 1
    duration(1) = 15.6996;    % code == 0
    duration(2) = 15.6996/28; % code == 1
    duration(3) = 15.6996/28; % code == 2
    duration(4) = 15.6996/28; % code == 3
    duration(5) = 15.6996/28; % code == 4
    duration(6) = 15.6996/28; % code == 5
    durationFlag=1;
    durations=[];
end

% get text from file
txt = fileread(parFile);

% split into lines and columns
lines = regexp(txt, '\n', 'split');
lines = regexp(lines, '\t', 'split');

% remove lines with less than max
counts = cellfun('size', lines, 2);
lines(counts < max(counts)) = [];

% for each line, get name and onset
onsets_idx = find(strcmp(column_names,'onsets'),1);
durations_idx = find(strcmp(column_names,'durations'),1);
names_idx = find(strcmp(column_names,'names'),1);
codes_idx = find(strcmp(column_names,'codes'),1);
total_durations=[];

% for each line, get total onsets, druations, and names
for x = 1:numel(lines),
    if ~isempty(onsets_idx),
        total_onsets{x} = str2double(lines{x}{onsets_idx});
    end
    if durationFlag==1
            code=str2double(lines{x}{codes_idx});
            total_durations{x} = duration(code+1);
    end
    if ~isempty(durations_idx),
        total_durations{x} = str2double(lines{x}{durations_idx});
    end
    if ~isempty(names_idx),
        total_names{x} = lines{x}{names_idx};
    end
end

% get unique names
if ~exist('names','var'),
    names = unique(total_names);
end

% set onsets and durations
for x = 1:numel(names),
    % get indices for name
    clear idxs;
    idxs = strcmp(total_names, names{x});
    if ~exist('onsets','var')|| x > numel(onsets),
        onsets{x} = [total_onsets{idxs}]';
    end
    % if no durations_idx, create from difference of each onset
    if isempty(total_durations),
        total_durations = arrayfun(@(x){x}, diff([total_onsets{:}]));
    end
    if (~exist('durations','var'))|| durationFlag==1
        durations{x} = [total_durations{idxs}]';
    end
end
% save file
if ~exist('filename','var'),
    [~,~,ext] = fileparts(parFile);
    filename = strrep(parFile, ext, '.mat');
end
save(filename, 'onsets', 'durations', 'names');
end