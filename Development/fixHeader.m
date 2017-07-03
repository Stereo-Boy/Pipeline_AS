function fixHeader(source_dir, expr, dest_dir, check_n, varargin)
% fixHeader(source_dir, expr, 'field', 'value',...,['verboseOFF'])
% 
% Inputs:
% source_dir: string directory containing nifti files to correct headers
% (default is pwd)
% expr: string expression to find files in source_dir (default is '*.nii*')
% dest_dir: where to put the nifti corrected file (default: same folder than source)
% check_n: the number of expected nifti files to correct (for checking the result)
% varargin: header fields to fix followed by value to use.
% if value is string and begins with 'eval(' and ends with ')', the value 
% will be evaluated
% 'verboseOFF': turn off verbose printout (default is 'verboseON')
%
% Outputs:
% nifti files saved with fixed header fields
%
% Example:
% fixHeader(fullfile(pwd,'05_nifti_fixed'),'epi*.nii.gz',...
%          'freq_dim',1,'phase_dim',2,'slice_dim',3)
%
% Created by Justin Theiss, updated Adrien Chopin Jan 2017

    % get verbose
    if any(strncmp(varargin,'verbose',7)),
        verbose = varargin(strncmp(varargin,'verbose',7));        verbose=verbose{1}; %otherwise does not work
        varargin(strcmp(varargin,verbose)) = [];
    else % default on
        verbose = 'verboseON';
    end

   % init defaults
    if ~exist('source_dir','var')||~exist(source_dir,'dir'), source_dir = pwd; warni('[fixHeader] empty source_dir defaulted to ',source_dir, verbose); end;
    if ~exist('expr','var')||isempty(expr), expr = '*.nii*'; warni('[fixHeader] empty expr defaulted to ',expr, verbose);end;
    if ~exist('dest_dir','var')||~exist(dest_dir,'dir'), dest_dir = source_dir; warni('[fixHeader] empty dest_dir defaulted to ',dest_dir, verbose);end;

    % get fields and values from varargin
    fields = varargin(1:2:end);
    values = varargin(2:2:end);

    % set vars for displaying
    if ~isempty(fields) && ~isempty(values),
        vars = cellfun(@(x,y){{x,': ',y,'\n'}},fields,values);
        vars = cat(2,vars{:});
    else % set vars to empty
        vars = {};
    end
    
    % display inputs
    dispi(mfilename,'\nsource_dir: ',source_dir,'\nexpr: ',expr,'\ndest_dir: ',dest_dir, '\n',vars{:},verbose);

    % get files
    %d = dir(fullfile(source_dir,expr));
    %files = fullfile(source_dir,{d.name});
    [files, nn] = get_dir(source_dir, expr);

    if nn~=check_n; errori('Incorrect number of files selected for nifti header fix: (',expr,') ',nn,'/',check_n, verbose); end
        
    % for each file, set headers
    for x = 1:numel(files),
        % get nifti
        clear ni;
        ni = readFileNifti(files{x});
        dispi('Correcting header of :', ni.fname,verbose)
        % for each varargin, set header field
        for n = 1:numel(fields),
            if strncmp(values{n},'eval(',5),
                evaluatedV = eval(values{n}(6:end-1));
                if ni.(fields{n}) == evaluatedV;
                    dispi(fields{n},' is correct (',evaluatedV,')', verbose)
                else
                    dispi(fields{n},' CORRECTED at ',evaluatedV, verbose)
                    ni.(fields{n}) = evaluatedV;
                end
            else
                if ni.(fields{n}) == values{n}
                    dispi(fields{n},' correct (',values{n},')', verbose)
                else
                    dispi(fields{n},' CORRECTED at ',values{n}, verbose)
                    ni.(fields{n}) = values{n};
                end
            end
        end
             
        % check qto
        ni = niftiCheckQto(ni);
        
        % add destination folder
        [~,filename,extension] = fileparts(ni.fname);
        ni.fname=fullfile(dest_dir,[filename,extension]);
        
        % display file and nifti structure
        dispi('Resulting file structure:\n',ni,verbose);
        
        % write out nifti
        writeFileNifti(ni);
        dispi(repmat('-',1,20),'file written',repmat('-',1,20),verbose);
    end
    success=check_files(dest_dir, expr, check_n, 1, verbose); %that shoud work even if dest_dir is the same than source_dir given fixed files overwrite 

     if success==1
         % leave a lame log file, but only if successful
         fid = fopen(fullfile(dest_dir,'headers_FIXED.txt'),'at');
         fprintf(fid, datestr(now));
         %fprintf(fid, 'Files fixed are:\n');
         %fprintf(fid, files(:));
         fclose(fid);
     end
        
end