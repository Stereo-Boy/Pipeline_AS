function params = create_params(params, fields, values)
% params = create_params(params, fields, values)
% Create parameters that will be used in the pipeline_JAS wrapper.
%
% Inputs:
% params - structure to set fields/values to (default is struct)
% fields - cell array of fields to set in params structure 
% values - cell array of values to be set in params structure
%   [default]: @uigetdir for _dir, @str2double(inputdlg) for _n, @inputdlg otherwise
%
% Outputs:
% params - structure containing parameters to use in pipeline_JAS wrapper
%
% Example:
% params = create_params([], {'pRF_dummy_n','retino_dicom'}, {5,'/Users/Sub01/Raw/'})
%
% params = 
% 
%      pRF_dummy_n: 5
%     retino_dicom: '/Users/Sub01/Raw/'
%
% Created by Justin Theiss

% init defaults
if ~exist('params','var')||~isstruct(params), params = struct; end;
if ~exist('fields','var')||isempty(fields), return; end;
if ~iscell(fields), fields = {fields}; end;
if ~exist('values','var')||isempty(values),
    % init values
    values = cellfun(@(x){input_values(params, x)}, fields);
end
if ~iscell(values), values = {values}; end;

% set each field, value
for x = 1:numel(fields),
    if nargin==3 || iscell(values{x}) || ~any(isnan(values{x})),
        params.(fields{x}) = values{x}; 
    end
end
end

% input value for field
function value = input_values(params, field)
    % init defaults
    if ~isfield(params, field)||isempty(params.(field)), 
        value = '';
    else % set value
        value = params.(field);
    end
    % return value using uigetdir/inputdlg
    if any(regexp(field,'_dir$')), % uigetdir folder
        value = local_setfun('uigetdir', field, value);
        if ~any(value), value = nan; end;
    elseif any(regexp(field,'_n$')), % inputdlg number
        value = local_setfun('str2double', field, value);
    elseif any(regexp(field,'_args$')), % cellfun inputdlg
        value = local_setfun('cell', field, value);
        if isempty(value), value = nan; end;
    elseif ischar(value), % inputdlg
        value = local_setfun('inputdlg', field, value);
        if isempty(value), value = nan; end;
    end
end

% set value using function
function value = local_setfun(fun, field, value)
    if isa(fun,'function_handle'), fun = func2str(fun); end;
    % switch based on function
    switch lower(fun)
        case {'uigetdir','directory'} % get directory
            if ~ischar(value)&&~isdir(value), value = pwd; end;
            disp(['Choose directory for ',field]);
            value = uigetdir(value, ['Choose directory for ',field]);
        case {'uigetfile','file'} % get file
            disp(['Choose file for ',field]);
            value = uigetfile([],['Choose file for ',field]);
        case {'str2double','number'} % string to double
            if ~isnumeric(value), value = []; end;
            value = str2double(cell2mat(inputdlg(['Enter number for ',field],...
            '',1,{num2str(value)})));
        case 'cell' % multiple cells
            if ~iscell(value), value = {}; end;
            funs = {'Directory','File','Number','Cell','Input'};
            n = str2double(cell2mat(inputdlg('Enter number of arguments to set:')));
            if isnan(n), value = {}; return; end;
            for x = 1:n,
                chc = listdlg('PromptString',['Choose type to set ',field,' ',num2str(x)],...
                    'ListString',funs,'SelectionMode','Single');
                if isempty(chc), continue; end;
                value{x} = local_setfun(funs{chc}, [field,' ',num2str(x)], '');
            end
        otherwise % input
            if ~iscellstr(value)&&~ischar(value), value = ''; end;
            value = cell2mat(inputdlg(['Enter ',field],'',1,{value}));
    end
end