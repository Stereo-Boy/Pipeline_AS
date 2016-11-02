function record_notes(varargin)
% record_notes(...)
% 
% Inputs:
% 'on': turn diary on (or back on after suspension)
% 'off': turn diary off
% notes_dir: directory to store notes (as notes_dir/[date]/filename.txt)
% filename: filename for saved .txt file in notes_dir/[date] directory
% 
% Outputs:
% none
% 
% Example:
% record_notes(pwd,'preprocessing');
% disp('Preprocessing...');
% record_notes('off');
%
% Note: if 'on' or 'off' are input, only diary(input) will be run.
% Furthermore, notes_dir and filename must both be input in order to create
% the appropriate file.
%
% Created by Justin Theiss 11/2016

% init varargins
for x = 1:nargin,
    switch varargin{x}
        case {'on','off'}
            % set diary off and return
            diary(varargin{x});
            return;
        otherwise
            if ~exist('notes_dir','var') && exist(varargin{x},'dir'),
                % set notes_dir
                notes_dir = fullfile(varargin{x}, date);
                % mkdir if needed
                if ~exist(notes_dir, 'dir'), mkdir(notes_dir); end;
            else
                % set filename 
                [~,filename] = fileparts(varargin{x});
            end
    end
end

% init other vars
if ~exist('filename','var'), return; end;
if ~exist('notes_path','var'), notes_path = pwd; end;

% set fullpath file
notes_path = fullfile(notes_dir, filename);

% if another file has been created, append with number
apnd = numel(dir([notes_path '*.txt']));
if apnd == 0, apnd = ''; else apnd = num2str(apnd); end;

% start diary
diary([notes_path apnd '.txt']);
return;