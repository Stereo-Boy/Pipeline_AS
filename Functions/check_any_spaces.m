function output = check_any_spaces(name)
%output = check_any_spaces(name)
%
% Checking whether the string 'name' has any spaces in it.
% Throws an error if there is a space, otherwise returns the output which
% is the folder name.

spaces = isstrprop(name, 'wspace');
if any(spaces)~=0
    erri('[check_any_spaces] Folder name erroneously contains space')
end 
output = name;