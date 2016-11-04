function remove_frames(fileName, n)
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

% get nifti struct
ni = readFileNifti(fileName);

% remove first n_dum frames
ni.data(:,:,:,1:n) = [];
 
% update dim
ni.dim = size(ni.data);

% write file
writeFileNifti(ni);