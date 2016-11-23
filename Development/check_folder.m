function fileOrFolder = check_folder(fileOrFolder, forceError, verbose)
% checkFolder(fileOrFolder, forceError, verbose)
%
% Checking whether the input is a file or folder or does not exist and returning the
% file/folder name as an ouput. It issues a warning if it does not exist.
%
% forceError = 1 (default 0): forces an error instead of a warning 
%
% If the input does not exist and forceError is set to 0
% (default), then it does attempt to create the folder. 
%
% verbose = verboseOFF, none of the disp function will give an ouput
% (default verboseON)
% ------------------------------------------------------------------------

% ------------------------------------------------------------------------
% Written Nov 2016
% Adrien Chopin
% -------------------------------------------------------------------------

if exist('verbose', 'var')==0; verbose='verboseON'; end
if exist('forceError', 'var')==0; forceError=0; end

%checks that input exists
if exist('fileOrFolder', 'var')==0
        help(mfilename);
        warni('checkFolder needs an input', verbose)
else
    %checks what it is
    type=exist(fileOrFolder);
    switch type
        case {0} %not a file, not a folder
            if forceError==1
                erri([fileOrFolder, ' does not exist'])
            else
                warni([fileOrFolder, ' does not exist'], verbose)
                dispi('check_folder will attempt to create folder: ', fileOrFolder, verbose)
                [success,message]=mkdir(fileOrFolder);
                if success; dispi('Created ', fileOrFolder); else warni('Could not create ', fileOrFolder, ' because: ', message, verbose);end    
            end
        case {2, 3, 4, 5} %file
            if forceError==1
                erri([fileOrFolder, ' input is a file rather than a folder!'])
            else
                warni([fileOrFolder, ' input is a file rather than a folder!'], verbose)
                dispi('check_folder will attempt to create folder ', fileOrFolder, verbose)
                [success,message]=mkdir(fileOrFolder);
                if success; dispi('Created ', fileOrFolder); else warni('Could not create ', fileOrFolder, ' because: ', message, verbose);end    
            end
        case {7} %folder
            dispi('Folder exists:', fileOrFolder, verbose)
    end
end