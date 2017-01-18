function output = check_folder(folder, forceError, verbose)
% output = checkFolder(folder, forceError, verbose)
%
% Checking whether the input is an existing folder(s) in the current pwd, and may create it otherwise without a warning. 
% The input folder can be a list of folders in a cell array including empty cells
%
% forceError = 1 (default 0): forces an error and therefore does not creates the folder
%
% verbose = verboseOFF, none of the disp function will give an ouput (default verboseON)
% 
% output is the existing or created folder(s)
% ------------------------------------------------------------------------------------------------------------

% ------------------------------------------------------------------------------------------------------------
% Written Nov 2016, re-adapted in Jan 2017
% Adrien Chopin
% -------------------------------------------------------------------------------------------------------------

%default values
if ~exist('verbose', 'var')|| isempty(verbose); verbose='verboseON'; end
if ~exist('forceError', 'var') || isempty(forceError); forceError=0; end

%determine number of cells in folder and creates an output template
if iscell(folder); sizeF=numel(folder); else sizeF=1;  end
output=cell(1,sizeF);

%checks that input exists
if ~exist('folder', 'var')
        help(mfilename);
        warni('[check_folder] needs an input', verbose)
else
   if ~iscell(folder), folder = {folder};end; %transforms in a cell array so that we can parse it one cell after one
   if numel(folder)==0;         dispi('[check_folder] Folder wass not created because it is an empty string.', verbose) ;    end
   for ff = 1:numel(folder), 
       currentFF = folder{ff};
       if iscell(currentFF);   %if there is a cell array in the cell array, recursively apply the function
                output{ff} = check_folder(currentFF, forceError, verbose);
       else
            %checks whether folder exists
            if exist(currentFF,'dir'); %yes
                dispi('[check_folder] confirms that the following folder exists: ', currentFF, verbose)
                output{ff}=currentFF;
            else  % not a folder
                    if forceError==1
                        erri('[check_folder] Folder does not exist: ',currentFF)
                    else
                        if isempty(currentFF)==0
                            dispi('[check_folder] Folder does not exist so attemps to create it: ', currentFF, verbose)
                            [success,message]=mkdir(currentFF);
                            if success; dispi('[check_folder] Folder created');output{ff}=currentFF; else warni('Could not create folder because: ', message, verbose);end    
                        else
                            dispi('[check_folder] Folder was not created because it is an empty string.', verbose)  
                        end
                    end
            end
       end
   end
   if numel(output)==1, output = output{1}; end;
end