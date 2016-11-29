function pRF_model(mr_dir, epi_dir, params, overwrite, verbose)
% pRF_model(mr_dir, epi_dir, n_dum, params, overwrite)
%
% Inputs:
% mr_dir: string directory containing mrSESSION.mat file
% epi_dir: string directory containing epi*.nii* files (default epi*.nii*
% files in mr_dir/nifti)
% params: structure of parameters for pRF model (default: see below)
% overwrite: boolean true/false to overwrite any previous work
% 
% Outputs saved:
% retModel*Fit.mat files that contain results from pRF model
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
%                  'nDCT', 0,...
%           'framePeriod', 1.8000,...
%               'nFrames', 130,...
%            'fliprotate', [0 0 0],...
%                'imFile', 'None',...
%            'jitterFile', 'None',...
%            'paramsFile', 'None',...
%              'imFilter', 'None',...
%      'orientationOrder', [2,1,4,7,3,8,5,6],...
%             'nOffBlock', 6.5,...
%             'hrfType','two gammas (SPM style)',...
%             'hrfParams',{{[1.68 3 2.05],[5.4 5.2 10.8 7.35 0.35]}});
%
% Created by Justin Theiss 11/2016

% init defaults
curdir = pwd; 
if ~exist('verbose','var'), verbose='verboseON'; end
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
    dispi('No parameters detected for pRF_model (should be in separate parameter files): loading default', verbose)
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

% load session data
cd(mr_dir); %necessary when using initHiddenInplane function!
%mrGlobals
vw = initHiddenInplane;
vol = initHiddenGray;
%loadSession

% check if Inplane/Averages exists
if exist(fullfile(mr_dir,'Inplane','Averages'),'dir') && ~overwrite,
    dispi(fullfile(mr_dir,'Inplane','Averages'), ' directory already exists.', verbose);
elseif exist(fullfile(mr_dir,'Inplane','Averages'),'dir') && overwrite, 
    % delete current Averages dir and remove dataTYPES(end)
    dispi('Removing previous Inplane average and average dataType', verbose)
    remove_previous(fullfile(mr_dir,'Inplane','Averages'), verbose);
    load('mrSESSION.mat','dataTYPES');
    dataTYPES(end) = [];
    save('mrSESSION.mat','dataTYPES','-append');
    dispi('Removing previous Gray/Averages and retino model files', verbose)
    remove_previous(fullfile(mr_dir,'Gray','Averages'), verbose);
end

% run averageTSeries
if overwrite, 
    vw.curDataType = 1;
    vw = averageTSeries(vw, 1:numel(files)); 
end;

% transform Inplane to volume with trilinear interpolation
vw.curDataType = 2; % set to Averages
vol.curDataType = 2; % set to Averages
vol = ip2volTSeries(vw,vol,0,'linear'); 

% set retinotopic parameters
vol.rm.retinotopyParams = params;
params = rmDefineParameters(vol);
params = make8Bars(params,1);
params = rmMakeStimulus(params);
vol.rm.retinotopyParams = params;

% run prf
rmMain(vol,[],3);

% close figures and return to previous dir
cd(curdir);
close all;