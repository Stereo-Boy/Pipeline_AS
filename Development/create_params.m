function params = create_params(params, fields, values)
% params = create_params(params, fields, values)
% Create parameters that will be used in the pipeline_JAS wrapper.
%
% Inputs:
% params - structure to set fields/values to (default is struct)
% fields - cell array of fields to set in params structure 
%   [default]:
%     fields = {'mprage_dcm_dir','retino_dcm_dir','exp_dcm_dir',...
%               'exp_par_dir','retino_n','exp_n','mprage_slc_n',...
%               'retino_tr_n','exp_tr_n','pRF_dummy_n'};
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
for x = 1:numel(fields), params.(fields{x}) = values{x}; end;
end

% input function for defaults
function value = input_values(params, field)
    % init defaults
    if ~isfield(params, field)||isempty(params.(field)), 
        if any(regexp(field,'_dir$')), % uigetdir
            value = pwd; 
        elseif any(regexp(field,'_n$')) % str2double
            value = [];
        else % inputdlg
            value = '';
        end
    else % set value
        value = params.(field);
    end
    % return value using uigetdir/inputdlg
    if any(regexp(field,'_dir$')), % uigetdir folder
        value = uigetdir(value, ['Choose ', field, ' directory']);
        if ~any(value), value = []; end;
    elseif any(regexp(field,'_n$')), % inputdlg number
        value = str2double(cell2mat(inputdlg(['Enter number for ',field],...
            '',1,{num2str(value)})));
        % set value to 0 if nan
        if isnan(value), value = []; end;
    elseif ischar(value), % inputdlg
        value = cell2mat(inputdlg(['Enter ',field],'',1,{value}));
    end
end