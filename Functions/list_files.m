function listFiles = list_files(source, expr, absolutePath)
% listFiles = list_files(source, expr, absolutePath)
% return all files present in source (default pwd) retrieved with expr
% (default is *)
% absolutePath (default 0) allows to convert all files to their absolute path
% Ex: list_files(pwd, '*.jpg') -> find all jpeg images in current
% directory

% Adrien Chopin 2016

if exist('source', 'var')==0; source=pwd; end
if exist('expr', 'var')==0; expr='*'; end
if exist('absolutePath', 'var')==0; absolutePath=0; end

files = dir(fullfile(source,expr));
list = {files.name};

%remove all dir from the list
dirs = [files.isdir];

%remove all files starting with an .

listFiles = list(~dirs);
if absolutePath; listFiles=fullfile(source,listFiles); end