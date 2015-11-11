restoredefaultpath
cd ~/Desktop/
%randomizing internal state for randomness for rand and randn?
rng('shuffle');
disp('Randomizing randomness')
%%%%%%%%%%%%%%%%%%%%%%%%%
%randomizing internal state for randomness
%rand('state',sum(100*clock)); %for compatibility?
%randn('state',sum(100*clock));

%EXPERIMENT PATH
 path(path,genpath('/Users/adrienchopin/Desktop/google drive/recherches partiel/2013_RoAD_Relative_or_Absolute_Disparities'))
 disp('Loaded path to your experiments: ROAD')
 path(path,'/Users/adrienchopin/Desktop/google drive/recherches partiel/2014_STaM_Stereo_Training_and_MRI/fMRI - stimulation')
 path(path,genpath('/Users/adrienchopin/Desktop/google drive/recherches partiel/2014_STaM_Stereo_Training_and_MRI/JST - Jian Stereo Training/'))
 path(path,genpath('/Users/adrienchopin/Desktop/google drive/recherches partiel/2014_STaM_Stereo_Training_and_MRI/ERDS - Eyetracked Random Dot Stereotest/'))
 disp('Loaded path to your experiments: STAM - fMRI / JST / ERDS')
 functionPath = genpath('~/Desktop/google drive/fonctions_MATLAB/');
 path(path, functionPath);
 disp('Loaded path to your personal libraries.')
 clear all

% VISTASOFT AND CO - Here, we give the choice between loading vsitasoft 2011 or vistasoft 2015
disp('[vistaPathStart] Which vistasoft toolbox would you like to use?')
disp('1. the 2011 version (megavista)')
version = str2double(input('2. the 2015 version (Pipeline_AS)  ','s'));

%Add Freesurfer path to the path
fshome = '/Applications/freesurfer';
fsfasthome = '/Applications/freesurfer/fsfast';
fsmatlab = sprintf('%s/matlab', fshome);
fsSubjects = sprintf('%s/subjects', fshome);
fsPerl = sprintf('%s/mni/Library/Perl/Updates/5.10.0', fshome);
fsfasttoolbox = sprintf('%s/toolbox',fsfasthome);
if (exist(fshome,'dir') ~= 7); error('Startup - Freesurfer home folder does not exist'); end
if (exist(fsfasthome,'dir') ~= 7); error('Startup - Freesurfer fast home folder does not exist'); end
if (exist(fsmatlab,'dir') ~= 7); error('Startup - Freesurfer matlab folder does not exist'); end
if (exist(fsSubjects,'dir') ~= 7); error('Startup - Freesurfer subjects folder does not exist'); end
if (exist(fsPerl,'dir') ~= 7); error('Startup - Freesurfer Perl folder does not exist'); end
if (exist(fsfasttoolbox,'dir') ~= 7); error('Startup - Freesurfer fast toolbox folder does not exist'); end
setenv('FREESURFER_HOME', fshome);
setenv('SUBJECTS_DIR', fsSubjects);
setenv('PERL5LIB', fsPerl);
setenv('FSFAST_HOME',fsfasthome);
path(fsfasttoolbox, path);
path(fsmatlab, path);
disp('Freesurfer paths and ENV variables fully configurated (loaded on top)')
setenv('PERL5LIB', '/Applications/freesurfer/mni/Library/Perl/Updates/5.10.0');

%quick sanity checks
    spmPath = '~/Desktop/spm12';
    knkPath = '~/Desktop/KNK';
    segmPath = '~/Desktop/Segmentation';
    mricron = '~/Desktop/mricron';
    
    if (exist(spmPath,'dir') ~= 7); error('Startup - spm does not exist'); end
    if (exist(knkPath,'dir') ~= 7); error('Startup - KNK does not exist'); end
    if (exist(segmPath,'dir') ~= 7); error('Startup - segmentation folder does not exist'); end
    if (exist(mricron,'dir') ~= 7); error('Startup - mricron does not exist'); end
    
%Add spm files to the path
path(genpath(spmPath), path); %path to your spm folder
disp('Loaded path to spm files on top.')

%Add KNK files to the path (only required if you use the Winawer lab procedure for fine alignment)
path(genpath(knkPath),path);
disp('Loaded path to KNK files on top.')

%Add segmentation files to the path
path(segmPath, path);
disp('Loaded path to segmentation files on top.')

%Add MRIcron to the path
path(mricron, path);
disp('Loaded path to MRIcron on top.')

%the 2011 version (megavista)
if version == 1
    disp('Loading path to vista tools on top')
    path(genpath('~/Desktop/Megavista/vistasoft'), path);
    path(genpath('~/Desktop/Megavista/silverlab_vista_tools'), path);
    disp('You are using vistasoft 2011 (Megavista)')
    disp('Loading Sara''s path on top.')
    path(genpath('~/Desktop/Megavista/zUsers/Sara/'), path);
    disp('Loading personal megavista path on top (zUser/Adrien).')
    path(genpath('~/Desktop/Megavista/zUsers/Adrien/'), path);
elseif version == 2 %the 2015 version Pipeline_AS
    vistasoftPath='~/Desktop/vistasoft/';
    pipelinePath='~/Desktop/Pipeline_AS/';
    persoPath = [pipelinePath, '/Users/Adrien/'];
    
    %quick sanity checks
    if (exist(vistasoftPath,'dir') ~= 7); error('Startup - vistasoft does not exist'); end
    if (exist(pipelinePath,'dir') ~= 7); error('Startup - Pipeline_AS does not exist'); end
    if (exist(persoPath,'dir') ~= 7); error('Startup - vistasoft does not exist'); end
    
    path(genpath(vistasoftPath), path);
    disp('You are using vistasoft 2015')
    disp('Loading Fixes, Tools, Functions and Modules folders from Pipeline_AS on top')
    path(genpath([pipelinePath, '/Fixes/']), path);
    path(genpath([pipelinePath, '/Tools/']), path);
    path(genpath([pipelinePath, '/Modules/']), path);
    path(genpath([pipelinePath, '/Functions/']), path);
    disp('Loading personal path first (Adrien) on top')
    path(genpath(persoPath), path);
else
    error('Input not understood - please reload vistaPathStart.m')
end

clear version fsmatlab fsfasttoolbox fsfasthome fsPerl fsSubjects fshome fsSubjects
% %Add Freesurfer path to the path
% setenv('FREESURFER_HOME', '/Applications/freesurfer')
% fshome = getenv('FREESURFER_HOME');
% fsmatlab = sprintf('%s/matlab',fshome);
% if (exist(fsmatlab,'dir') == 7)
%     path(path,fsmatlab);
%     disp('Loaded path to Freesurfer - part 1/2')
% else
%     disp('Startup - line 46 - Freesurfer home folder does not exist')
% end
% clear fshome fsmatlab;
% fsfasthome = '/Applications/freesurfer/fsfast';
% setenv('FSFAST_HOME',fsfasthome);
% fsfasttoolbox = sprintf('%s/toolbox',fsfasthome);
% if (exist(fsfasttoolbox,'dir') == 7)
%     disp('Loaded path to Freesurfer - part 2/2')
%     path(path,fsfasttoolbox);
%  else
%     disp('Startup - line 56 - Freesurfer fast home folder does not exist')
% end
% clear fsfasthome fsfasttoolbox;
% setenv('SUBJECTS_DIR', '/Applications/freesurfer/subjects/')
% disp('Set subjects_dir variable in path')
% 
% %Add FSL to the path
% fsldir = '/usr/local/fsl'; %path to your FSL folder
% cd(fsldir) 
% setenv( 'FSLDIR', fsldir );
% fsldirmpath = sprintf('%s/etc/matlab',fsldir);
% path(path, genpath(fsldirmpath));
% disp('Loaded path to FSL/etc/matlab.')