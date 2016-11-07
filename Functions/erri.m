function erri(varargin)
% Format-proof error function 
% This function just throw error with any message, even numbers. 
% You can also just provide all the message parts separated by commas rather
% that producing a string between brackets.
% Adrien Chopin, nov 2016

nbArg=numel(varargin);
if nbArg>0
    string=[];
    for i=1:nbArg
            string=[string,num2str(varargin{i})];
    end
    error(string)
else
        error('No arguments provided to erri for display...')
end

end