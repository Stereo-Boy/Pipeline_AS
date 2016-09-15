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
% (largely copied from makeRetinotopyStimulus_bars (v1.1))
%
% Note: Additionally, requires params.stim(id).nOffBlock to describe the number of
% frames during the offBlock. Default is 12s/TR. 
% 
% See also: makeWedges.m
%
% Example:
%    PLEASE INSERT AN EXAMPLE HERE
%

 
%% 2006/06 SOD: wrote it.

if notDefined('params');     error('Need params'); end;
if notDefined('id');         id = 1;                   end;

outerRad   = params.stim(id).stimSize;
innerRad   = 0;
ringWidth  = outerRad .* params.stim(id).stimWidth ./ 360;
numImages  = params.stim(id).nFrames ./ params.stim(id).nCycles;
mygrid = -params.analysis.fieldSize:params.analysis.sampleRate:params.analysis.fieldSize; 	 
[x,y]=meshgrid(mygrid,mygrid);
r          = sqrt (x.^2  + y.^2);
theta      = atan2 (y, x);	% atan2 returns values between -pi and pi
theta      = mod(theta,2*pi);	% correct range to be between 0 and 2*pi

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
% it is not needed in the way we've edited the for loop below. (JDT 9/14/16)
if ~isfield(params.stim(id),'orientationOrder'),
    orientationOrder = [1 6 3 8 5 2 7 4]; % original
else
    orientationOrder = params.stim(id).orientationOrder;
end
orientations = orientations(orientationOrder);
% % remake_xy    = zeros(1,numImages)-1;
% % remake_xy(1:length(remake_xy)./length(orientations):length(remake_xy)) = orientations;
original_x   = x;
original_y   = y;

% step size of the bar determined by onBlock frames (JDT 9/14/16)
if ~isfield(params.stim(id),'nOffBlock'), 
    nOffBlock = 12/params.stim(id).framePeriod; % original without integer assumption
else
    nOffBlock = params.stim(id).nOffBlock;
end;
if params.stim(id).nStimOnOff == 0, nOffBlock = 0; end;

% step_nx calculated from number of on block frames (JDT 9/14/16)
step_nx      = (numImages-(nOffBlock*params.stim(id).nStimOnOff))/8; 
step_x       = (2*outerRad) ./ step_nx;
step_startx  = (step_nx-1)./2.*-step_x - (ringWidth./2);

images = zeros(prod([size(x,2) size(x,1)]),numImages);

% create logical on/off array for frames with remainder TR frames being
% included with on blocks in order to deweight these frames (JDT 9/14/16)
nOnBlock = step_nx*(8/params.stim(id).nStimOnOff);
onOff = repmat([true(1,nOnBlock),false(1,floor(nOffBlock)),true(1,nOnBlock)+1,false(1,floor(nOffBlock))],1,params.stim(id).nStimOnOff/2);

% Loop that creates the final images
% fprintf(1,'[%s]:Creating images:',mfilename);

% only create images during on block frames (previously 1:numImages) 
% (JDT 9/14/16)
for imgNum=find(onOff), 
    % reset img
    img = zeros(size(x,2),size(x,1));
    
    % for each new onBlock (JDT 9/14/16)
    if mod(find(find(onOff)==imgNum),step_nx)==1,
        % get onBlock number by dividing relative on block frame by number
        % of on block frames per block (JDT 9/14/16)
        b = ceil(find(find(onOff)==imgNum)/step_nx);
        % set x and y to appropriate orientation (using orientations rather
        % than remake_xy JDT 9/14/16)
        x = original_x .* cos(orientations(b)) - original_y .* sin(orientations(b));
        y = original_x .* sin(orientations(b)) + original_y .* cos(orientations(b));
        % reset starting point 
        loX = step_startx-step_x;
        % after first image, add step_x * remainder of nOffBlock and 1/0 
        % previous frame was offBlock to account for difference in movement 
        % if on block began during previous frame (JDT 9/14/16)
        if imgNum > 1, loX = loX + (step_x * mod(nOffBlock, 1) * ~onOff(imgNum-1)); end;
    end;

    loEcc = innerRad;
    hiEcc = outerRad;
    loX   = loX + step_x;
    hiX   = loX + ringWidth;

    % Can we do this just be removing the second | from the window expression? so...
    window = ( (x>=loX & x<=hiX) & r<outerRad);
    % if the previous frame was offBlock, set to 1 - remainder of nOffBlock
    % (to weight the trial by proportion of on block time during frame)
    % else if followin frame is offBlock, set to remainder of nOffBlock 
    % (to weight the trial by proportion of off block time during frame)
    % otherwise, set to 1 (JDT 9/14/16)
    if (imgNum > 1 && ~onOff(imgNum-1)),
        img(window) = 1 - mod(nOffBlock, 1);
    elseif (imgNum < numImages && ~onOff(imgNum+1)),
        img(window) = mod(nOffBlock, 1);
    else
        img(window) = 1;
    end;
    
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
        
    images(:,imgNum) = img(:);
%     fprintf('.');drawnow;
end

% repeat across cycles
img    = repmat(images,[1 params.stim(id).nCycles]);

% Note: removed in favor of skipping offBlocks rather than creating here
% (JDT 9/14/16)
% on off
% if params.stim(id).nStimOnOff>0,
% %     fprintf(1,'(with Blanks)');
%     nRep = params.stim(id).nStimOnOff;
%     offBlock = round(12./params.stim(id).framePeriod);
%     onBlock  = params.stim(id).nFrames./nRep-offBlock;
%     onoffIndex = repmat(logical([zeros(onBlock,1); ones(offBlock,1)]),nRep,1);
%     img(:,onoffIndex)    = 0;
% end;

% Note: changed preimg to be blank (same as offBlock) (JDT 9/14/16)
% preimg = img(:,1+end-params.stim(id).prescanDuration:end);
preimg = zeros(size(images,1),params.stim(id).prescanDuration);
params.stim(id).images = cat(2,preimg,img);
% fprintf(1,'Done.\n');


return;
  


