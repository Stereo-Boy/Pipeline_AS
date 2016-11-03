function record_notes(varargin)
% record_notes(...)
% 
% Inputs:
% 'on': turn diary on (or back on after suspension)
% 'off': turn diary off
% notes_dir: directory to store notes (default is pwd)
% filename: filename for saved .txt file in notes_dir directory (default
% will create date_time.txt file)
% 
% Outputs saved:
% file within notes_dir saved as date_time_filename.txt containing command
% window output
% 
% Example:
% record_notes(pwd,'preprocessing');
% disp('Preprocessing...');
% record_notes('off');
% disp('this is not recorded');
% record_notes('on');
% disp('this is recorded');
% record_notes('off');
%
% Note: if 'on' or 'off' are input, only diary(input) will be run.
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
                notes_dir = varargin{1};
            else
                % set filename 
                [~,filename] = fileparts(varargin{x});
            end
    end
end

% init other vars
if ~exist('filename','var'), filename = ''; end;
if ~exist('notes_dir','var'), notes_dir = pwd; end;

% get date and time
datetime = sprintf('%02.f_',fix(clock));

% set fullpath file
notes_path = fullfile(notes_dir,[datetime filename '.txt']);

% start diary
diary(notes_path);
return;