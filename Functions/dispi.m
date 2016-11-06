function dispi(varargin)
% Format-proof dispi function with verbose option
% This function just disp anything, even numbers. 
% You can also just provide all the message parts separated by commas rather
% that producing a string between brackets.
% If dispi is provided with an argument 'verboseOFF' then it just skips that function.
% 'verboseON' is simply ignored.
% Adrien Chopin, nov 2016

nbArg=numel(varargin);
if nbArg>0
    string=[];
    for i=1:nbArg
        if strcmpi(varargin{i},'verboseOFF')
           return 
        elseif strcmpi(varargin{i},'verboseON')
            %do nothing
        else
            string=[string,num2str(varargin{i})];
        end
    end
    disp(string)
else
        disp('No arguments provided to dispi for display...')
end

end