function rx = rxAlignManual(vol_data, ref_data, volVoxelSize, refVoxelSize, varargin)
%
% rx = rxAlignManual(session,varargin)
%
% Manual version of rxAlign that does not use globals and needs a vol and a ref as a result.
% Interface to use mrRx to perform alignments
% on mrVista sessions.
%
% The argument can either be the path to a mrVista
% session directory, or a view from an existing
% directory. If omitted, it assumes you're already
% in the session directory and starts up a hidden
% inplane view.
%
% To save the alignment, you'll want to use the
% following menu in the control figure:
%
% File | Save ... | mrVista alignment
%
% ras 03/05.


%vol_data = readVolAnat(vol);
vol_data = double(vol_data);
ref_data = double(ref_data);

% call mrRx
rx = mrRx(vol_data, ref_data, 'volRes', volVoxelSize, 'refRes', refVoxelSize);

% open a prescription figure
rx = rxOpenRxFig(rx);

% % check for a screen save file
% if exist('Raw/Anatomy/SS','dir')
% %     rxLoadScreenSave;
%     openSSWindow;
% end

% % check for an existing params file
% paramsFile = fullfile(HOMEDIR,'mrRxSettings.mat');
% if exist(paramsFile,'file')
%     rx = rxLoadSettings(rx,paramsFile);
%     rxRefresh(rx);
% else
	% add a few decent defaults
    %hmsg = msgbox('Adding some preset Rxs ...');
    rx = rxMidSagRx(rx);
    rx = rxMidCorRx(rx);
    rx = rxObliqueRx(rx);
    %close(hmsg);
%end

% % load any existing alignment
% if isfield(mrSESSION,'alignment')
%     rx = rxLoadMrVistaAlignment(rx,'mrSESSION.mat');
% end


return
