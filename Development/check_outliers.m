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
s = round(size(data{x},1) / 2);
n_tr = size(data{x},4);
n_slc = size(data{x},1);

% create figure, and set data
h = figure('Visible','off','Name','Check Outliers','NumberTitle','off','MenuBar','none');
set(h, 'UserData', struct('data',{data},'trs',{trs},'outliers',{cell(size(files))}));

% get figure color
fig_color = get(h,'Color');

% set uicontrols 
uicontrol('Parent',h,'Style','popupmenu','Tag','files','String',names(:),...
    'units','normalized','Position',[0,.5,.22,.04],'Callback',@(x,y)setfile_callback(h,x));
uicontrol('Parent',h,'Style','popupmenu','Tag','views','String',{'Sagittal','Axial','Coronal'},...
    'units','normalized','Position',[0,.4,.22,.04],'Callback',@(x,y)setview_callback(h,x));
uicontrol('Parent',h,'Style','pushbutton','Tag','next_tr','String','Next Outlier',...
    'units','normalized','Position',[0,.3,.2,.04],'Callback',@(x,y)settr_callback(h,x));
uicontrol('Parent',h,'Style','pushbutton','Tag','prev_tr','String','Prev Outlier',...
    'units','normalized','Position',[0,.2,.2,.04],'Callback',@(x,y)settr_callback(h,x));
% text boxes
uicontrol('Parent',h,'Style','text','Tag','str_tr','String',['TR: ',num2str(t)],...
    'units','normalized','Position',[.4,.05,.1,.04],'BackgroundColor',fig_color);
uicontrol('Parent',h,'Style','text','Tag','str_nslices','String','# slices: 1',...
    'units','normalized','Position',[0,.05,.1,.04],'BackgroundColor',fig_color);
uicontrol('Parent',h,'Style','text','Tag','str_slice','String',['Slice: ',num2str(s)],...
    'units','normalized','Position',[0,0,.1,.04],'BackgroundColor',fig_color);
% sliders
uicontrol('Parent',h,'Style','slider','Tag','tr','Min',1,'Max',n_tr,...
    'Value',t,'Callback',@(x,y)imshow_callback(h),'units','normalized',...
    'Position',[.5,.05,.2,.04],'SliderStep',[1/(n_tr-1),10/(n_tr-1)]);
uicontrol('Parent',h,'Style','slider','Tag','nslices','Min',1,'Max',n_slc,...
    'Value',1,'Callback',@(x,y)setnslc_callback(h,x),'units','normalized',...
    'Position',[.1,.05,.2,.04],'SliderStep',[1/(n_slc-1),10/(n_slc-1)]);
uicontrol('Parent',h,'Style','slider','Tag','slice','Min',1,'Max',n_slc,...
    'Value',s,'Callback',@(x,y)imshow_callback(h),'units','normalized',...
    'Position',[.1,0,.2,.04],'SliderStep',[1/(n_slc-1),10/(n_slc-1)]);
% pushbuttons
uicontrol('Parent',h,'Style','pushbutton','Tag','interp','String','Confirm Outlier',...
    'Callback',@(x,y)confirm_outlier_callback(h),'units','normalized','Position',[.5,0,.2,.04]);
uicontrol('Parent',h,'Style','pushbutton','Tag','done','String','Done',...
    'Callback','uiresume(gcbf)','units','normalized','Position',[.8,0,.1,.04]);

% setfile for to show image
setfile_callback(h);

% set visible and wait until done
set(h,'visible','on');
uiwait(gcf);
if ~isgraphics(h), return; end;

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

% get data for slice and tr
function data = local_getdata(h, s)
% get userdata, idx, and data
user_data = get(h, 'UserData');
idx = get(findobj(h,'Tag','files'),'Value');
data = user_data.data{idx};
% get view and set slice index
view = get(findobj(h,'Tag','views'),'Value');
slc_idx = {':',':',':'};
slc_idx{view} = s;
% get current tr
t = round(get(findobj(h,'Tag','tr'),'Value'));
% return data or empty image
if ~isnan(s),
    data = squeeze(data(slc_idx{:},t));
else % empty image
    slc_idx{view} = 1;
    data = zeros(size(squeeze(data(slc_idx{:},t))));
end
end

% change file
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
view_obj = findobj(h,'Tag','views');
% get data, trs, and view
data = getfield(get(h, 'UserData'), 'data');
trs = getfield(get(h, 'UserData'), 'trs'); 
view = get(view_obj, 'Value');
% set tr and slice
set(tr_obj,'Value',trs{idx}(1));
set(slc_obj,'Value',round(size(data{idx}, view) / 2));
set(tr_obj,'Max',size(data{idx}, 4)); 
set(slc_obj,'Max',size(data{idx}, view));
% update view
setview_callback(h, view_obj);
end

% change view
function setview_callback(h, x)
% get view
view = get(x, 'Value');
% get nslices object
nslc_obj = findobj(h,'Tag','nslices');
% get userdata
user_data = get(h, 'UserData');
data = user_data.data;
% get idx
idx = get(findobj(h,'Tag','files'),'Value');
% get current nslice, slice, and size of data in view
nslices = round(get(nslc_obj,'Value'));
sz = size(data{idx}, view);
% set nslices max and value
set(nslc_obj,'Value', min(nslices, sz));
set(nslc_obj,'Max',sz);
% run setnslc 
setnslc_callback(h, nslc_obj);
end

% next/prev TR
function settr_callback(h, x)
% get tr_obj
tr_obj = findobj(h,'Tag','tr');
% get userdata
user_data = get(h, 'UserData');
% get idx
idx = get(findobj(h,'Tag','files'),'Value');
% get trs from userdata
trs = user_data.trs{idx};
% get current tr
t = get(tr_obj, 'Value');
% find index for current tr
n = find(trs == t);
if isempty(n), n = 0; end;
% if next, set to next
if strcmp(get(x,'Tag'),'next_tr'), 
    set(tr_obj, 'Value', trs(min(n+1, end)));
else % set to previous
    set(tr_obj, 'Value', trs(max(n-1, 1)));
end
% run imshow callback
imshow_callback(h);
end

% change number of slices shown
function setnslc_callback(h, x)
% get max of nslices, current nslices, and current slice
max_n = round(get(x,'Max'));
nslices = round(get(x,'Value'));
diff = max_n - nslices;
s = round(get(findobj(h,'Tag','slice'),'Value'));
% set str_nslices
set(findobj(h,'Tag','str_nslices'),'String',['# slices: ',num2str(nslices)]);
% set value, min, and max slices
set(findobj(h,'Tag','slice'),'Value',min(s, diff+1));
if diff == 0, % set min to 0 to avoid min > max
    set(findobj(h,'Tag','slice'),'Min',0);
end
set(findobj(h,'Tag','slice'),'Max',diff + 1);
% change slider steps
set(findobj(h,'Tag','slice'),'SliderStep',[1/max(1,diff),10/max(1,diff)]);
% run imshow callback
imshow_callback(h);
end

% show image
function imshow_callback(h)
% get objects
fl_obj = findobj(h,'Tag','files');
view_obj = findobj(h,'Tag','views');
tr_obj = findobj(h,'Tag','tr');
str_tr_obj = findobj(h,'Tag','str_tr');
slc_obj = findobj(h,'Tag','slice');
str_slc_obj = findobj(h,'Tag','str_slice');
% get tr and slice
t = round(get(tr_obj,'Value'));
s = round(get(slc_obj,'Value'));
if s==0, s = 1; end;
% set TR and slice numbers
set(str_tr_obj,'String',['TR: ',num2str(t)]);
set(str_slc_obj,'String',['Slice: ',num2str(s)]);
% get nrows and ncols
nslc = round(get(findobj(h,'Tag','nslices'),'Value'));
nrows = ceil(sqrt(nslc));
ncols = ceil(nslc/nrows);
% create slcs with nrows and ncols
slcs = nan(1, nrows * ncols);
slcs(1:nslc) = s:s+nslc-1;
slcs = reshape(slcs, ncols, nrows)'; 
% create image tiles
img = [];
for r = 1:nrows,
    rowimg = [];
    for c = 1:ncols, % get columns
        rowimg = [rowimg, local_getdata(h, slcs(r,c))];
    end % add rowimg to img
    img = [img; rowimg];
end
% imshow
imshow(img,[min(img(:)),max(img(:))],'InitialMagnification','fit');
end

% confirm outlier
function confirm_outlier_callback(h)
% get user data and idx
user_data = get(h, 'UserData');
idx = get(findobj(h,'Tag','files'),'Value');
% get current tr
t = get(findobj(h,'Tag','tr'),'Value');
% set outliers to n
user_data.outliers{idx}(max(1,end+1)) = t;
set(h, 'UserData', user_data);
end