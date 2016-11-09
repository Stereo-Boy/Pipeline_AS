function listFolders = list_folders(source, expr, absolutePath)
% listFolders = list_folders(source, expr, absolutePath)
% return all folders present in source (default pwd) retrieved with expr
% (default is *)
% absolutePath (default 0) allows to convert all files to their absolute path
% Ex: list_folders(pwd, '*epi*') -> find all directories containing the
% word epi

% Adrien Chopin 2016

if exist('source', 'var')==0; source=pwd; end
if exist('expr', 'var')==0; expr='*'; end
if exist('absolutePath', 'var')==0; absolutePath=0; end

files = dir(fullfile(source,expr));
list = {files.name};

%remove all non-dir from the list
dirs = [files.isdir];

listFolders = list(dirs);

%remove all folders starting with an .
for i=numel(listFolders):-1:1
    folder=listFolders{i};
   if strcmp(folder(1),'.')
       listFolders(i)=[];
   end
end

if absolutePath; listFolders=fullfile(source,listFolders); end