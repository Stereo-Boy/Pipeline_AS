function tf = check_files(expr, n)
% tf = check_files(expr, n)
% Check if number of files of certain expression exist.
% 
% Inputs:
% expr: string expression of files to check
% n: number of expected files
%
% Outputs:
% tf: boolean result of checking if number of files with expr matches n
%
% Example:
% tf = check_files('*_mcf.nii*', 6)
% 
% tf =
% 
%      1
% 
% Created by Justin Theiss 11/2016

% return number of files with expr == n
tf = (numel(dir(expr)) == n);
return;