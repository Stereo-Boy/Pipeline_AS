function params = make8Bars(params,id)
% Make moving (8) bar visual field mapping stimulus
%
%   params = make8Bars(stimparams,stimulus_id);
%
% We use bars of eight different orientations, moving through the visual
% field, to estimate pRFs.  This function creates the set of stimulus
% apertures corresponding to these moving, flickering, contrast bars.
%
% These apertures are then used by the pRF modeling software to estimate
% the pRF.
% 
% params: A retinotopy model parameter structure
% stimulus_id: Which scan is associated with this stimulus
% 
%
% (largely copied from makeRetinotopyStimulus_bars (v1.1)) 
% 
% See also: makeWedges.m
%
% Example:
%    
%
% Edited by Justin Theiss theissjd@berkeley.edu 9/14/16:
%
% These edits allow users to have "off" or "mean luminence" blocks with a
% non-integer number of frames. Furthermore, we calculate the number of
% frames per "on" or "stimulus" blocks by using only the number of frames
% during those blocks and dividing by eight. Finally, the frames between
% "on" and "off" blocks are weighted by the remainder of the number of
% frames of "off" blocks (if needed). For example, if you have "off" blocks
% comprised of 6.75 frames each, the last frame in the "off" block (7th) is
% weighted by .25 in the location of the bar stimulus. Furthermore, the
% location of the following frame accounts for the correct difference given
% there was only .25 frame time change. Likewise, the last "on" frame
% preceding an "off" block would be weighted by .75 since the bar is
% present for .75 of the frame.
%
% Users should add a field to params.stim(id) for the orientation order of
% the bar as params.stim(id).orientationOrder where a value 1 through 8
% correpsonds to the counter clockwise orientation of 1=Right, 2=...
%
% Users should also enter the number of frames for the "off" blocks as
% params.stim(id).nOffBlock. See example.
%

 
%% 2006/06 SOD: wrote it.
%% 2016/09 JDT: edited for use in Silver lab.

if notDefined('params');     error('Need params'); end;
if notDefined('id');         id = 1;                   end;

% initialize aperture radius, bar width, number of frames, and aperture grid
outerRad   = params.stim(id).stimSize;
ringWidth  = outerRad .* params.stim(id).stimWidth ./ 360;
numImages  = params.stim(id).nFrames ./ params.stim(id).nCycles;
mygrid = -params.analysis.fieldSize:params.analysis.sampleRate:params.analysis.fieldSize; 	 
[x,y]=meshgrid(mygrid,mygrid);
r          = sqrt (x.^2  + y.^2);

%% we need to update the sampling grid to reflect the sample points used
% ras 06/08: this led to a subtle bug in which (in rmMakeStimulus) multiple
% operations of a function would modify the stimulus images, but not the
% sampling grid. These parameters should always be kept very closely
% together, and never modified separately.
params.analysis.X = x(:);
params.analysis.Y = y(:);

% loop over different orientations and make checkerboard
% first define which orientations
orientations = [0:45:360]./360*(2*pi); % degrees -> rad
% Note: since our order could not be achieved by flipping or rotating, we
% added this variable field. We then removed the remake_xy variable since
% it is not needed in the way we've edited the for loop below. (JDT 9/16)
if ~isfield(params.stim(id),'orientationOrder'),
%     orientationOrder = [1 6 3 8 5 2 7 4]; % original
    orientationOrder = eval(['[',cell2mat(inputdlg('Enter orientation order for 8 bars')),']']);
else
    orientationOrder = params.stim(id).orientationOrder;
end
% if greater than number of orientations, throw error
if any(orientationOrder > numel(orientations)), 
    error('Orientations must be between 1 and %d',numel(orientations));
end
% set orientations
orientations = orientations(orientationOrder);
original_x   = x;
original_y   = y;

% step size of the bar determined by onBlock frames (JDT 9/16)
nStimOnOff = params.stim(id).nStimOnOff;
if ~isfield(params.stim(id),'nOffBlock'), 
    nOffBlock = str2double(cell2mat(inputdlg('Enter number of frames per fixation block'))); 
else
    nOffBlock = params.stim(id).nOffBlock;
end;
if nStimOnOff == 0, nOffBlock = 0; end;

% step_nx calculated from number of on block frames (JDT 9/16)
step_nx      = (numImages-(nOffBlock*nStimOnOff))/numel(orientations); 
step_x       = (2*outerRad) ./ step_nx;
step_startx  = (step_nx-1)./2.*-step_x - (ringWidth./2);

% initialize images variable
images = zeros(prod([size(x,2) size(x,1)]),numImages);

% create weights based on TR fractions and shifts in blocks (JDT 9/16)
% set onOffOrder of 1s for on blocks and 0s for off blocks 
onOffOrder = repmat([ones(1,ceil(numel(orientations)/nStimOnOff)),zeros(1,ceil(nStimOnOff/numel(orientations)))],1,nStimOnOff);
% init wts, startBlock, and shft
wts = []; startBlock = []; shft = 0; 
for o = onOffOrder,
    % if on, set n to # stimulus block frames; if off, set to # off block frames
    if o, startBlock(end+1) = numel(wts)+1; n = step_nx; else n = nOffBlock; end;
    % set weights based on previous shift if needed, then 1s or 0s, then remainder if on block
    wts = [wts, shft*ones(1,ceil(o*shft)), o*ones(1, floor(n-shft)), mod(n-shft,1)*ones(1,ceil(o*mod(n-shft,1)))];
    % calculate current shift for next block
    shft = mod(1-abs(mod(n,1)-shft), 1); 
end;

% set imgOrder to allow for imgNum to repeat shared TRs (JDT 9/16)
imgOrder = 1:numel(wts);
for i = 1:numel(wts), if mod(wts(i),1) > 0 && wts(i-1) == wts(i), imgOrder(i:end) = imgOrder(i:end)-1; end; end;

% create images using weights (JDT 9/16)
for i = find(wts > 0)
    % set imgNum
    imgNum = imgOrder(i);
    
    % reset img
    img = zeros(size(x,2),size(x,1));
    
    % for each new onBlock (JDT 9/16)
    if any(startBlock==i),
        % get onBlock number by dividing relative on block frame by number
        % of on block frames per block (JDT 9/16)
        b = find(startBlock==i);
        % set x and y to appropriate orientation (using orientations rather
        % than remake_xy JDT 9/16)
        x = original_x .* cos(orientations(b)) - original_y .* sin(orientations(b));
        % reset starting point based on the weight (e.g. if stimulus starts
        % at .25 TR [.75 weight], subtract step_startx by step_x * 1.25 [2-.75])
        % (JDT 9/16)
        loX = step_startx - (step_x * (2-wts(i)));
    end;

    % find coordinates within aperture to set weights for stimulus
    loX   = loX + step_x;
    hiX   = loX + ringWidth;
    window = ( (x>=loX & x<=hiX) & r<outerRad);
    
    % set weighted values of stimulus (JDT 9/16)
    img(window) = wts(i);
    
    % flip or rotate image if indicated in fliprotate variable/gui
    if isfield(params.stim(id),'fliprotate'),
        if params.stim(id).fliprotate(1),
            img = fliplr(img);
        end;
        if params.stim(id).fliprotate(2),
            img = flipud(img);
        end;
        if params.stim(id).fliprotate(3)~=0,
            img = rot90(img,params.stim(id).fliprotate(3));
        end;
    end;
    
    % set result to images; if two bars share TR, add together (JDT 9/16)
    images(:,imgNum) = images(:,imgNum) + img(:);
end

% repeat across cycles
clear img;
img    = repmat(images,[1, params.stim(id).nCycles]);

% Note: changed preimg to be blank (same as offBlock) (JDT 9/16)
preimg = zeros(size(images,1),params.stim(id).prescanDuration);
params.stim(id).images = cat(2,preimg,img);
return;
  


