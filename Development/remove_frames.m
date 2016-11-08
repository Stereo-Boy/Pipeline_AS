function remove_frames(fileName, n, verbose)
% remove_frames(fileName, n)
% Remove dummy volumes from beginning of given file.
%
% Inputs:
% fileName - full path to file for which to remove dummy volumes
% n_dum - number of dummy volumes to remove (from beginning)
% 
% Outputs:
% none
%
% requires: readFileNifti, writeFileNifti (from vista)
if ~exist('verbose','var'); verbose='verboseON'; end
if ~exist('fileName','var'); erri('remove_frames: fileName not defined', verbose), end
if ~exist('n','var'); n=0; warni('remove_frames: n not defined. Defaulting to 0', verbose), end


% get nifti struct
ni = readFileNifti(fileName);

% remove first n_dum frames
ni.data(:,:,:,1:n) = [];
 
% update dim
ni.dim = size(ni.data);

% write file
writeFileNifti(ni);

dispi(fileName, ': ', n, ' dummy frames removed', verbose)