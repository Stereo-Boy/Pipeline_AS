function warni(varargin)
% Format-proof warning function with verbose option
% This function just warn anything, even numbers. 
% You can also just provide all the message parts separated by commas rather
% that producing a string between brackets.
% If warni is provided with an argument 'verboseOFF' then it just tells nothing.
% 'verboseON' is simply ignored.
% Adrien Chopin, nov 2016

nbArg=numel(varargin);
if nbArg>0
    string=[];
    for i=1:nbArg
        if strcmpi(varargin{i},'verboseOFF')
%           warning(' ')
           return 
        elseif strcmpi(varargin{i},'verboseON')
            %do nothing
        else
            string=[string,num2str(varargin{i})];
        end
    end
    warning(string)
else
        warning('No arguments provided to warni for display...')
end

end