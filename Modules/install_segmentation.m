function install_segmentation(mr_dir, seg_dir, ni_dir, verbose, n_gray)
% install_segmentation(mr_dir, seg_dir, ni_dir, ...)
% Installs volume anatomy and an existing cortical segmentation into an existing mrSESSION
%
% Inputs:
% mr_dir - string path of mrVista session folder
%   [default pwd]
% seg_dir - string path of directory containing t1_class edited files
%   [default fullfile(pwd, 'segmentation')]
% ni_dir - string path of directory to move t1_class edited files
%   [default fullfile(pwd, 'nifti')]
% additional arguments:
% 'verbose' - 'verboseON' or 'verboseOFF', display or supress output
%   [default 'verboseON']
% 'n_gray' - number of gray layers to grow on white segmentation
%   [default 5]
%
% Note: To avoid errors, all paths should be fullfile
%
% Adrien Chopin - 2015
% Adapted from kb_installSeg.m
% Kelly Byrne | Silver Lab | UC Berkeley | 2015-09-27 
% modified from code written by the Winawer lab and available at: https://wikis.nyu.edu/display/winawerlab/Install+segmentation
%
% requires the VISTA Lab's Vistasoft package - available at: https://github.com/vistalab/vistasoft

% init vars
if ~exist('mr_dir','var')||isempty(mr_dir), 
    mr_dir = pwd; 
    dispi('empty mr_dri in install_segmentation defaulted to ', mr_dir); 
end
if ~exist('seg_dir','var')||isempty(seg_dir), 
    seg_dir = fullfile(pwd,'segmentation'); 
    dispi('empty seg_dir in install_segmentation defaulted to ', seg_dir);
end
if ~exist('ni_dir','var')||isempty(ni_dir), 
    ni_dir = fullfile(pwd,'nifti'); 
    dispi('empty ni_dir in install_segmentation defaulted to ', ni_dir);
end
if ~exist('verbose','var')||isempty(verbose), 
    verbose = 'verboseON'; 
end
if ~exist('n_gray','var')||isempty(n_gray), 
    n_gray = 5; 
    dispi('empty n_gray in install_segmentation defaulted to ', n_gray);
end

% % init defaults
% vars = {'verbose', 'n_gray'};
% defaults = {'verboseON', 5};
% 
% % set defaults if needed
% n_idx = ~ismember(vars, varargin(1:2:end))
% addvars = cat(1, vars(n_idx), defaults(n_idx))
% varargin = cat(2, varargin, addvars(:)')
% for x = 1:2:numel(varargin),
%     eval([varargin{x} '= varargin{x+1};']);
% end

% set initial dir
initialDir = pwd;

% check for mr_dir
check_folder(mr_dir, 1, verbose);

% cd to mr dir
cd(mr_dir);

% installSegmentation parameters:
query = []; % should trigger volume, gray or flat coords calculation if missing
keepAllNodes = true; % for more flexibility
disp(seg_dir)

check_exist(seg_dir, '*edited*', 1, 'errorON', verbose);
dispi('Copying ',fullfile(seg_dir,'*edited*'),' to ',ni_dir,verbose);
copyfile(fullfile(seg_dir, '*edited*'), ni_dir);
seg_file = get_dir(ni_dir, '*edited*', 1);

% needs following structure: left class, right class, empty gray left, empty right gray 
segFilePaths = {seg_file, seg_file, '', ''};

% display parameters
dispi('@installSegmentation parameters:', verbose);
dispi('query: ', query, verbose);
dispi('keepAllNodes: ', keepAllNodes, verbose);
dispi('classificationPath: ', segFilePaths, verbose);
dispi('Having a list with two files and two empty string is normal', verbose)
dispi('n_gray: ', n_gray, verbose);

% install segmentation
initHiddenInplane;
dispi('Installing Segmentation...',verbose);
installSegmentation(query, keepAllNodes, segFilePaths, n_gray);

% return to initial dir
cd(initialDir);
end