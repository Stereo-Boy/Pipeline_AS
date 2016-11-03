function pRF_model(mr_dir, epi_dir, n_dum, params, overwrite)
% pRF_model(mr_dir, epi_dir, n_dum, params, overwrite)
%
% Inputs:
% mr_dir: string directory containing mrSESSION.mat file
% epi_dir: string directory containing epi*.nii* files (default epi*.nii*
% files in mr_dir/nifti)
% n_dum: number of frames to remove from beginning of epi scans (default: 5)
% params: structure of parameters for pRF model (default: see below)
% overwrite: boolean true/false to overwrite any previous work
% 
% Outputs:
% none
%
% params default:
%     params.analysis = struct('fieldSize',9.1,...
%             'sampleRate',.28);
%     params.stim(1) = struct('stimType', '8Bars',...
%              'stimSize', 9.1,...
%             'stimWidth', 213.6264,...
%               'nCycles', 1,...
%            'nStimOnOff', 4,...
%            'nUniqueRep', 1,...
%       'prescanDuration', 5,...
%           'framePeriod', 1.8000,...
%               'nFrames', 130,...
%            'fliprotate', [0 0 0],...
%      'orientationOrder', [2,1,4,7,3,8,5,6],...
%             'nOffBlock', 6.5,...
%             'hrfType','two gammas (SPM style)',...
%             'hrfParams',{{[1.68 3 2.05],[5.4 5.2 10.8 7.35 0.35]}});
%
% Created by Justin Theiss 11/2016

% init defaults
curdir = pwd; 
if ~exist('mr_dir','var')||~exist(mr_dir,'dir'),
    mr_dir = pwd;
end
if ~exist('epi_dir','var')||~exist(epi_dir,'dir'),
    epi_dir = fullfile(mr_dir,'nifti');
end
if ~exist('n_dum','var')||isempty(n_dum),
    n_dum = 5;
end
if ~exist('params','var')||~isstruct(params),
    params.analysis = struct('fieldSize',9.1,...
            'sampleRate',.28);
    params.stim(1) = struct('stimType', '8Bars',...
             'stimSize', 9.1,...
            'stimWidth', 213.6264,...
              'nCycles', 1,...
           'nStimOnOff', 4,...
           'nUniqueRep', 1,...
      'prescanDuration', 5,...
                 'nDCT', 0,...
          'framePeriod', 1.8000,...
              'nFrames', 130,...
           'fliprotate', [0 0 0],...
               'imFile', 'None',...
           'jitterFile', 'None',...
           'paramsFile', 'None',...
             'imFilter', 'None',...
     'orientationOrder', [2,1,4,7,3,8,5,6],...
            'nOffBlock', 6.5,...
            'hrfType','two gammas (SPM style)',...
            'hrfParams',{{[1.68 3 2.05],[5.4 5.2 10.8 7.35 0.35]}});
end
if ~exist('overwrite','var')||isempty(overwrite),
    overwrite = false;
end

% get epis in epi_dir
d = dir(fullfile(epi_dir,'epi*.nii*'));
files = fullfile(epi_dir,{d.name});

% copy files to "original" folder
if ~exist(fullfile(epi_dir,'original'),'dir'),
    mkdir(fullfile(epi_dir,'original'));
elseif overwrite % delete current files and copy from original 
    copyfile(fullfile(epi_dir,'original','epi*.nii*'),epi_dir);
    delete(fullfile(epi_dir,'original','epi*.nii*'));
end
copyfile(fullfile(epi_dir,'epi*.nii*'),fullfile(epi_dir,'original'));

% remove first 5 frames of EPIs
if overwrite,
for x = 1:numel(files),
    remove_dummies(files{x}, n_dum);
end
end

% load session data
cd(mr_dir);
mrGlobals;

% check if Inplane/Averages exists
if exist(fullfile(mr_dir,'Inplane','Averages'),'dir') && ~overwrite,
    disp([fullfile(mr_dir,'Inplane','Averages') ' directory already exists.']);
elseif exist(fullfile(mr_dir,'Inplane','Averages'),'dir') && overwrite, 
    % delete current Averages dir and remove dataTYPES(end)
    rmdir(fullfile(mr_dir,'Inplane','Averages'),'s');
    load('mrSESSION.mat','dataTYPES');
    dataTYPES(end) = [];
    save('mrSESSION.mat','dataTYPES','-append');
end

% run averageTSeries
if overwrite, 
    INPLANE{1}.curDataType = 1;
    INPLANE{1} = averageTSeries(INPLANE{1}, 1:numel(files)); 
end;

% transform inplane to volume with trilinear interpolation
INPLANE{1}.curDataType = 2; % set to Averages
VOLUME{1}.curDataType = 2; % set to Averages
VOLUME{1} = ip2volTSeries(INPLANE{1},VOLUME{1},0,'linear'); 

% set retinotopic parameters
VOLUME{1}.rm.retinotopyParams = params;
params = rmDefineParameters(VOLUME{1});
params = make8Bars(params,1);
params = rmMakeStimulus(params);
VOLUME{1}.rm.retinotopyParams = params;

% run prf
rmMain(VOLUME{1},[],3);

% close figures and return to previous dir
cd(curdir);

function remove_dummies(fileName,n_dum)
% Remove dummy volumes from beginning of given file.
%
% Inputs:
% fileName - full path to file for which to remove dummy volumes
% n_dum - number of dummy volumes to remove (from beginning)
% 
% Outputs:
% none
%
% requires: readFileNifti, writeFileNifti (from vista)

% get nifti struct
ni = readFileNifti(fileName);

% remove first n_dum frames
ni.data(:,:,:,1:n_dum) = [];
 
% update dim
ni.dim = size(ni.data);

% write file
writeFileNifti(ni);

