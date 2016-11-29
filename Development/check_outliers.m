function outlier_table = check_outliers(outlier_table)
% outlier_table = check_outliers(outlier_table)
% Displays data for outlier TRs and allows user to view adjacent TRs and
% confirm whether each TR is an outlier. 
%
% Inputs:
% outlier_table: table output from motion_outliers function (first column
% is nifti file names, second column is the number of outliers, third
% column is the outlier TRs)
%
% Outputs:
% outlier_table: updated table with confirmed outputs
%
% Notes: This function opens a figure showing the middle slice for the
% first outlier of the first file in outlier_table. Files can be changed
% via the drop-down menu on the left side of the figure. Outliers can be
% toggled between using the "Next Outlier" and "Prev Outlier" buttons. TRs
% and slices can be changed via the appropriate sliders. If an outlier is
% determined to be an outlier that needs to be interpolated, click "Confirm
% Outlier" while the TR is shown. When finished confirming outliers for all
% files, click "Done". To exit and return the input outlier_table, close
% the figure instead.
%
% Created by Justin Theiss 11/16

% init vars
if nargin==0||isempty(outlier_table), return; end;

% get files and trs from outlier_table
files = outlier_table(:,1);
trs = outlier_table(:,3);

% get files with outliers
files = files(~cellfun('isempty',trs));
trs = trs(~cellfun('isempty',trs));

% get initial data
data = cell(size(files));
names = cell(size(files));
for x = 1:numel(files), 
    ni = readFileNifti(files{x});
    data{x} = ni.data;
    [~,names{x}] = fileparts(files{x});
end

% set initial tr and slice
t = trs{1}(1);
s = round(size(data{x},3) / 2);
n_tr = size(data{x},4);
n_slc = size(data{x},3);

% create figure, and set data
h = figure('Visible','off','NumberTitle','off');
set(h, 'UserData', struct('data',{data},'trs',{trs},'outliers',{cell(size(files))}));

% set uicontrols
uicontrol('Parent',h,'Style','popupmenu','Tag','files','String',...
    names(:),'Position',[5,100,90,20],'Callback',@(x,y)setfile_callback(h,x));
uicontrol('Parent',h,'Style','pushbutton','Tag','next_tr','String','Next Outlier',...
    'Position',[10,80,80,20],'Callback',@(x,y)settr_callback(h,x));
uicontrol('Parent',h,'Style','pushbutton','Tag','prev_tr','String','Prev Outlier',...
    'Position',[10,60,80,20],'Callback',@(x,y)settr_callback(h,x));
uicontrol('Parent',h,'Style','text','Tag','str_tr','String',...
    ['TR: ',num2str(t)],'Position',[5,20,60,20]);
uicontrol('Parent',h,'Style','text','Tag','str_slice','String',...
    ['Slice: ',num2str(s)],'Position',[5,2,60,20]);
uicontrol('Parent',h,'Style','slider','Tag','tr','Min',1,'Max',n_tr,...
    'Value',t,'Callback',@(x,y)imshow_callback(h),'Position',[60,20,80,20],...
    'SliderStep',[1/(n_tr-1),10/(n_tr-1)]);
uicontrol('Parent',h,'Style','slider','Tag','slice','Min',1,'Max',n_slc,...
    'Value',s,'Callback',@(x,y)imshow_callback(h),...
    'Position',[60,2,80,20],'SliderStep',[1/(n_slc-1),10/(n_slc-1)]);
uicontrol('Parent',h,'Style','pushbutton','Tag','interp','String','Confirm Outlier',...
    'Callback',@(x,y)interp_callback(h),'Position',[250,2,80,20]);
uicontrol('Parent',h,'Style','pushbutton','Tag','done','String','Done',...
    'Callback','uiresume(gcbf)','Position',[475,2,80,20]);

% setfile for to show image
setfile_callback(h);

% set visible and wait until done
set(h,'visible','on');
uiwait(gcf);
if ~isvalid(h), return; end;

% get user_data
outliers = getfield(get(h, 'UserData'), 'outliers');

% set output
outlier_table = cell(numel(files), 3);
outlier_table(:,1) = files;
outlier_table(:,2) = cellfun(@(x){numel(unique(x))}, outliers);
outlier_table(:,3) = cellfun(@(x){sort(unique(x))}, outliers);

% close h
close(h);
end

function setfile_callback(h, x)
% init idx
if ~exist('x','var'), 
    idx = 1;
else % get idx from x
    idx = get(x, 'Value');
end
% get objs
tr_obj = findobj(h,'Tag','tr');
slc_obj = findobj(h,'Tag','slice');
% get data, trs
data = getfield(get(h, 'UserData'), 'data');
trs = getfield(get(h, 'UserData'), 'trs'); 
% set tr and slice
set(tr_obj,'Value',trs{idx}(1));
set(slc_obj,'Value',round(size(data{idx}, 3) / 2));
set(tr_obj,'Max',size(data{idx},4)); 
set(slc_obj,'Max',size(data{idx},3));
% run imshow callback
imshow_callback(h);
end

function settr_callback(h, x)
% get tr_obj
tr_obj = findobj(h,'Tag','tr');
% get trs from userdata
trs = getfield(get(h, 'UserData'), 'trs');
idx = get(findobj(h,'Tag','files'),'Value');
% get current tr
t = get(tr_obj, 'Value');
% find index for current tr
n = find(trs{idx} == t);
if isempty(n), n = 0; end;
% if next, set to next
if strcmp(get(x,'Tag'),'next_tr'), 
    set(tr_obj, 'Value', trs{idx}(min(n+1, end)));
else % set to previous
    set(tr_obj, 'Value', trs{idx}(max(n-1, 1)));
end
% run imshow callback
imshow_callback(h);
end

function imshow_callback(h)
% get objs
fl_obj = findobj(h,'Tag','files');
tr_obj = findobj(h,'Tag','tr');
str_tr_obj = findobj(h,'Tag','str_tr');
slc_obj = findobj(h,'Tag','slice');
str_slc_obj = findobj(h,'Tag','str_slice');
% get file index, TR, and slice from sliders
idx = get(fl_obj,'Value');
t = int32(get(tr_obj,'Value')); 
s = int32(get(slc_obj,'Value'));  
% get slc_data
data = getfield(get(h, 'UserData'), 'data'); 
slc_data = data{idx}(:,:,s,t);
% imshow
imshow(slc_data,[min(slc_data(:)),max(slc_data(:))],'InitialMagnification','fit');
% set TR and slice numbers
set(str_tr_obj,'String',['TR: ',num2str(t)]);
set(str_slc_obj,'String',['Slice: ',num2str(s)]);
end

function interp_callback(h)
% get user data and idx
user_data = get(h, 'UserData');
idx = get(findobj(h,'Tag','files'),'Value');
% get current trs and tr
trs = user_data.trs{idx};
t = get(findobj(h,'Tag','tr'),'Value');
if isempty(find(trs == t, 1)), return; end;
% set outliers to n
user_data.outliers{idx}(max(1,end+1)) = t;
set(h, 'UserData', user_data);
end