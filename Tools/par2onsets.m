function output = par2onsets(parFile, column_names,varargin)
% filename = par2onsets(parFile,'param1','value1','param2','value2',...)
% Create onsets (.mat) file from par (.par) file (but any text file should 
% work). The onsets file can be used in SPM software. Durations certainly need to be provided
% in a separate parameter given mrVista PAR file typically do not provide the events or epoch durations
% Alternately, provide the special code 'specialCode' for the parameter 'durations' to be able to deduce
% the duration from the code column (fill the section below)
% 
% Inputs:
% parFile - string filename of par (or any text file) containing paradigm - it can also be a cell array
% of par filenames (one for each run), in which case they will be all opened and concatenated 
% as one big matrix. In that case, you need to provide the total duration of a run (runDuration) so that 
% we can adapt the event onset times (which should be relative to the run and needs to be relative
% to the experiment)
% 'column_names' - cell array of the column names of the parFile text file
% Options
% onsets, durations, and (conditions) names except if there are provided in the optional parameter below
% 'onsets' (optional) - (seconds or TR) cell array of onsets for manual input
% 'durations' (optional) - (seconds or TR) cell array of durations for manual input / could be specialCode to use the
% parameters defined below - in that case, codes have to be defined for each event (either provided as a 
% parameter or given as a column in parFile)
% 'names' (optional) - cell array of names for manual input
% 'runDuration' (optional) - total duration of a run (they have to be all the same) in the units
% of the onsets and durations (seconds or TR)
% 'output' (optional) - string filename to output for .mat file 
%   [default is parFile with .mat ending] (first cell is cell array)
% 
%
% Outputs:
% filename - string filename of saved .mat file containing onsets,
%   durations, and names to be used with SPM.
%
% Note: the text within the parFile should be organized as rows and tabbed
% columns. also if 'durations' is not listed in column_names, durations
% will be calculated by the sorted difference across onsets.
%
% Ex of use: par2onsets({'epi01.par','epi02.par'},'durations','specialCode','output','epi_sots',...
%  'runDuration', 259)
% Created by Justin Theiss

% set column names
if exist('column_names','var')==0;
    disp('Please enter colum_names')
end
% set onsets manually 
if any(strcmp(varargin, 'onsets')), 
    onsets = varargin{find(strcmp(varargin,'onsets'),1)+1};
end
% set durations manually
total_durations=[];
if any(strcmp(varargin, 'durations'))
    durationsList = varargin{find(strcmp(varargin,'durations'),1)+1};
    if strcmp(durationsList,'specialCode') %deduce the durations from the code column with the following mapping:
        % (replace with your experiment values) - careful code and idx of durations are off by 1
        duration(1) = 15.6996;    % code == 0
        duration(2) = 15.6996/28; % code == 1
        duration(3) = 15.6996/28; % code == 2
        duration(4) = 15.6996/28; % code == 3
        duration(5) = 15.6996/28; % code == 4
        duration(6) = 15.6996/28; % code == 5
        durationFlag=1;
    else
        total_durations = durationsList;
    end
end
% set names manually
if any(strcmp(varargin, 'names')), 
    names = varargin{find(strcmp(varargin,'names'),1)+1};
end
if any(strcmp(varargin, 'runDuration')), 
    runDuration = varargin{find(strcmp(varargin,'runDuration'),1)+1};
end
% set output filename manually
if any(strcmp(varargin, 'output')), 
    output = varargin{find(strcmp(varargin,'output'),1)+1};
else
    outtmpname=parFile;
    if iscell(parFile)
        outtmpname=parFile{1};
    end
    [~,~,ext] = fileparts(outtmpname);
    output = strrep(outtmpname, ext, '.mat');
end


if exist('parFile','var')==0; error('Input needed'); end

% localize column of each event info
onsets_idx = find(strcmp(column_names,'onsets'),1);
durations_idx = find(strcmp(column_names,'durations'),1);
names_idx = find(strcmp(column_names,'names'),1);
codes_idx = find(strcmp(column_names,'codes'),1);

% loading data
if iscell(parFile)==1
    dispi('Loading ', numel(parFile),' files of data');
    lines=[];
    startTime=0;
    for i=1:numel(parFile)
        linesTmp=extractFile(parFile{i},startTime,onsets_idx);
        lines=[lines;linesTmp];
        startTime=startTime+runDuration;
    end
else
    dispi('Loading one file of data');   
    lines=extractFile(parFile,0,onsets_idx);
end
dispi('We loaded ',numel(lines), ' lines of event data')

lines

% get name, onset and duration of all events
    if ~isempty(onsets_idx),
        total_onsets = cell2mat(lines(:,onsets_idx))';
    end
    if ~isempty(durations_idx),
        total_durations = str2double(lines(:,durations_idx))';
    end
    if durationFlag==1
            code=str2double(lines(:,codes_idx));
            total_durations = duration(code+1)';
    end
    if ~isempty(names_idx),
        total_names = lines(:,names_idx)';
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
    onsets{x} = total_onsets(idxs)';
%     % if no durations_idx, create from difference of each onset
%     if isempty(total_durations),
%         total_durations = arrayfun(@(x){x}, diff([total_onsets{:}]));
%     end
     durations{x} = total_durations(idxs);
end

%save file
save(output, 'onsets', 'durations', 'names');
end


function lines=extractFile(parFile, startTime,onsets_idx)

    % get text from file
    txt = fileread(parFile);

    % split into lines and columns
    lineTmp = regexp(txt, '\n', 'split');
    lineTmp = regexp(lineTmp, '\t', 'split');

    % remove lines with less than max
    counts = cellfun('size', lineTmp, 2);
    lineTmp(counts < max(counts)) = [];
    lines=[];
    for i=1:numel(lineTmp)
        line=lineTmp{i};
        line(onsets_idx)={str2double(line{onsets_idx})+startTime};
        lines=[lines;line];
    end
end