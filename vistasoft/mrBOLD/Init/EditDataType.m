function [dataType,ok] = EditDataType(dataType)
% Edit the fields of the dataType structure
%
%    dataType = EditDataType(dataType);
%
% The user edits blockedAnalysisParams and eventAnalysisParams.
% scanParams are listed but not editable.
%
% djh, 9/2001 (modified from EditSession)
% ras, 2/2003 (Rory's local version: bigger fields/fonts, for longer scan
% descriptions)
% arw, 06/15/15 Modify to cope with graphic handle behavior in R2014b onwards



% The following cell arrays determine the field names to
% display, their descriptive label, and whether or not they are
% to be editable. Each row of the array has the form:
% {field name, label, edit flag}.

topFields = { ...
        'name', 'Data type', 0; ...
    };

scanFields = { ...
        'annotation', 'Description', 1; ...
        'nFrames', 'Number of temporal frames', 0; ...
        'parfile','.par/.prt file',1; ...
        'framePeriod', 'Frame interval (s)', 0; ...
    };
        
blockFields = { ...
        'blockedAnalysis', 'Perform blocked analysis?', 1; ...
        'detrend', 'Detrend option', 1; ...
        'inhomoCorrect', 'Correct for spatial inhomogeneity?', 1; ...
        'nCycles', 'Number of cycles/scan', 1; ...
        'framesToUse', 'Frames to use for coranal', 1; ...        
    };

eventFields = { ...
        'eventAnalysis', 'Perform event analysis?', 1; ...
        'detrend','Detrend option', 1; ...
        'detrendFrames','Detrend frames? (if opt=1)', 1; ...
        'inhomoCorrect','Correct for spatial inhomogeneity?', 1; ...
        'timeWindow','Time Course Time Window',1;...
        'peakPeriod','Time Course Peak Period',1;...
        'bslPeriod','Time Course Baseline Period',1;...
        'normBsl','Normalize baseline period?',1;...
        'glmHRF','GLM HRF option [help er_getParams]?',1;...
        'glmWhiten','Determine Noise when applying GLMs?',1;...
        'snrConds','Conditions to use to compute SNR / HRF',1;...
    };

% Create the top-level fields
if isunix,   fontSize = 9;
else         fontSize = 9;
end
titleFontSize = 10; butWidth=15; marginFields = 11; topMargin = 1.2;
versionLength = 25;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% scale factors for x and y axis coordinates %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xs = 1.45;  
ys = 1.6;
height = 1 * ys;
vSkip = 0.10 * ys;
dy = (height + vSkip);
x = 1 * xs;

iScan = 1;
topData = CreateEditData(topFields, dataType);
scanData = CreateEditData(scanFields, dataType.scanParams(iScan));
blockData = CreateEditData(blockFields, dataType.blockedAnalysisParams(iScan));
eventData = CreateEditData(eventFields, dataType.eventAnalysisParams(iScan));

% add extra space for the annotation field in the scanData struct
scanData(1).width = 100;
nTopFields = length(topData);
nScanFields = length(scanData);
nBlockFields = length(blockData);
nEventFields = length(eventData);
numFields = nTopFields + nScanFields + nBlockFields + nEventFields; 
maxWidth = max([topData.width, scanData.width, blockData.width, eventData.width]);

%%%%%%%%%%%%%%%%%%%%%%
% Create the figure: %
%%%%%%%%%%%%%%%%%%%%%%
topH = figure(...
    'MenuBar', 'none', ...
    'Units', 'Normalized', ...
    'Position', [.2 .1 .6 .7], ...
    'Resize','on', ...
    'Name', 'Data Type Editor', ...
    'NumberTitle', 'off' ...
    );
bkColor = get(topH, 'color');

if (verLessThan('matlab','8.4')) % New object/handle behavior for graphics objects in 2014b
    tHandle=topH;
else
    tHandle=topH.Number;
end

topHS = num2str(tHandle);

% center the figure in the screen (ras, 03/06):
centerOnscreen(tHandle);

%%%%%%%%%%%%%%%%%%%%%%
% Scan parameters:   %
%%%%%%%%%%%%%%%%%%%%%%
y = (numFields + marginFields - topMargin) * dy;
tmp = max([size(char(topData.label), 2), size(char(topData.label), 2)]); % Huh?
maxLabelWidth = 1.5 * tmp * xs;

% Create the top-level fields:
for iField=1:nTopFields
  labelPos = [x, y, length(topData(iField).label)*xs, height];
  h = CreateEditRow(topData(iField), labelPos, maxLabelWidth, topH, ...
      titleFontSize, 'UpdateEditDataType');
  topData(iField).handle = h;
  set(h, 'FontWeight', 'bold');
  y = y - dy;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create the scan-number selection buttons and indicator field: %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
y = y - dy;

% move to previous scan button
foo = 10; % bad variable name award: this is the left-position of the scan indicator field...
bpos = [foo - 4, y+0.25*dy, 5, height];
cString = ['IncEditDataType(', topHS, ', -1);'];
uicontrol( ...
    'Style', 'pushbutton', ...
    'String', '<<', ...
    'Units', 'char', ...
    'Position', bpos, ...
    'FontWeight', 'bold', ...
    'Callback', cString ...
    );

% scan indicator field
cString = ['IncEditDataType(', topHS, ', 0);'];
hScan = uicontrol( ...
    'Style', 'edit', ...
    'Units', 'char', ...
    'String', '1', ...
    'BackgroundColor', [1, 1, 1], ...
    'Position', [foo, y+0.25*dy, 3*xs+1, height], ...
    'HorizontalAlignment', 'center', ...
    'FontSize', fontSize, ...
    'FontWeight', 'bold', ...
    'Callback', cString ...
    );

% move to next scan button
bpos = [foo + 4, y+0.25*dy, 5, height];
cString = ['IncEditDataType(', topHS, ', 1);'];
uicontrol( ...
    'Style', 'pushbutton', ...
    'String', '>>', ...
    'Units', 'char', ...
    'Position', bpos, ...
    'FontWeight', 'bold', ...
    'Callback', cString ...
    );

% copy to later scans button
bpos = [foo + 10, y+0.25*dy, 8, height];
cString = ['DupEditDataType(', topHS, ');'];
uicontrol( ...
    'Style', 'pushbutton', ...
    'String', 'Copy>>', ...
    'Units', 'char', ...
    'Position', bpos, ...
    'FontWeight', 'bold', ...
    'Callback', cString ...
    );

% copy (select scans) button
bpos = [foo + 20, y+0.25*dy, 20, height];
cString = ['EditDataType_CopyFields(', topHS, ');'];
uicontrol( ...
    'Style', 'pushbutton', ...
    'String', 'Copy (select scans)', ...
    'Units', 'char', ...
    'Position', bpos, ...
    'FontWeight', 'bold', ...
    'Callback', cString ...
    );

y = y - dy;


%%%%%%%%%%%%%%%%
% Scan Params: %
%%%%%%%%%%%%%%%%
y = y - dy;
titleStr = 'Scan Params';
uicontrol( ...
    'Style', 'text', ...
    'Units', 'char', ...
    'String', titleStr, ...
    'BackgroundColor', bkColor, ...
    'Position', [0, y, length(titleStr)*xs*1.5, height*1.2], ...
    'HorizontalAlignment', 'left', ...
    'FontWeight', 'bold', ...
    'FontSize', titleFontSize ...
    );

% start edit field after the largest label
maxLabelWidth = 1.1 * max([size(char(scanData.label), 2), ...
	size(char(scanData.label), 2)]) * xs; 
y = y - dy;

% Create the top-level fields:
for iField=1:nScanFields
  labelPos = [x, y, 200, height];
  h = CreateEditRow(scanData(iField), labelPos, maxLabelWidth, tHandle, ...
      fontSize, 'UpdateEditDataType', 40);
  scanData(iField).handle = h;
  y = y - dy;
end

% Blocked Analysis Params:
y = y - dy;
titleStr = 'Traveling Wave Analysis Params';
uicontrol( ...
    'Style', 'text', ...
    'Units', 'char', ...
    'String', titleStr, ...
    'BackgroundColor', bkColor, ...
    'Position', [0, y, length(titleStr)*xs*1.5, height*1.2], ...
    'HorizontalAlignment', 'left', ...
    'FontWeight', 'bold', ...
    'FontSize', titleFontSize ...
    );
y = y - dy;

% Create the scan-related fields:
for iField=1:nBlockFields
  labelPos = [x, y, length(blockData(iField).label)*xs, height];
  h = CreateEditRow(blockData(iField), labelPos, maxLabelWidth, tHandle, fontSize, 'UpdateEditDataType');
  blockData(iField).handle = h;
  y = y - dy;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Event Analysis Params: %
%%%%%%%%%%%%%%%%%%%%%%%%%%
y = y - dy;
titleStr = 'Event Analysis Params';
uicontrol( ...
    'Style', 'text', ...
    'Units', 'char', ...
    'String', titleStr, ...
    'BackgroundColor', bkColor, ...
    'Position', [0, y, length(titleStr)*xs*1.5, height*1.2], ...
    'HorizontalAlignment', 'left', ...
    'FontWeight', 'bold', ...
    'FontSize', titleFontSize ...
    );
y = y - dy;
% Create the scan-related fields:
for iField=1:nEventFields
  labelPos = [x, y, length(eventData(iField).label)*xs, height];
  h = CreateEditRow(eventData(iField), labelPos, maxLabelWidth, tHandle, fontSize, 'UpdateEditDataType');
  eventData(iField).handle = h;
  y = y - dy;
end

% Build the UI data structure and attach it to the figure:
uiData.dataType = dataType;
uiData.original = dataType;
uiData.topData = topData;
uiData.scanData = scanData;
uiData.blockData = blockData;
uiData.eventData = eventData;
uiData.hScan = hScan;
uiData.iScan = iScan;
set(topH, 'UserData', uiData);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Finally, install the file-control buttons %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
y = y - dy/2;
butWidth = 11;
bpos = [x, y, butWidth, height*1.2];
uicontrol( ...
    'Style', 'pushbutton', ...
    'String', 'Accept', ...
    'Units', 'char', ...
    'HorizontalAlignment', 'center', ...
    'Position', bpos, ...
    'Callback', 'uiresume', ...
    'FontSize', titleFontSize ...
    );
x = x + butWidth + 1;
bpos = [x, y, butWidth, height*1.2];
uicontrol( ...
    'Style', 'pushbutton', ...
    'String', 'Revert', ...
    'Units', 'char', ...
    'HorizontalAlignment', 'center', ...
    'Position', bpos, ...
    'FontSize', titleFontSize, ...
    'Callback', ['RevertEditDataType(', topHS, ');'] ...
    );
x = x + butWidth + 1;
bpos = [x, y, butWidth, height*1.2];
uicontrol( ...
    'Style', 'pushbutton', ...
    'String', 'Cancel', ...
    'Units', 'char', ...
    'HorizontalAlignment', 'center', ...
    'Position', bpos, ...
    'FontSize', titleFontSize, ...
    'Callback', ['CancelEdit(', topHS, ');'] ...
    );

% Wait until we get a uiresume, then perform an update. Repeat
% this cycle until the update reports no errors.
ok = 0;
while ~ok
  uiwait(topH);
  uiData = get(topH, 'UserData');
  if isfield(uiData, 'cancel')
    ok=0;
    close(topH);
    return
  end
  ok = UpdateEditDataType(topH);
end

% After the update is successful, unpack the data into the output
% into the session structure and clean up.
uiData = get(topH, 'UserData');
dataType = uiData.dataType;
close(topH);
