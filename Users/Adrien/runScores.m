
clear all
listSS={'SO81','RN31','MV106','MV40','MS09','MH99','MC105','LYY65','KR104','KM79','KK100','HB85','EM21',...
    'DC95','CL90','AM52'};
listSS={'KM79'}
thePath = '/Users/adrienchopin/Desktop/Big_data_STAM/';
dispi('Starting in ', thePath)
for i=1:numel(listSS)
    dispi('Participant: ', listSS{i})
    cd(fullfile(thePath,listSS{i},'pre1/stam'))
    listFiles=list_files(cd,'*MRI*.mat');
    prop=[];
    for f=1:numel(listFiles)
        theFile=listFiles{f};
        if strcmp(theFile(end-7:end),'temp.mat')==0
            dispi('File: ', theFile)
            load(theFile)
            performance(:,:,sum(sum(performance,2),1)==0)=[];
            performance(:,2,:)=round(performance(:,2,:)./4); %dividing FA rate by correction factor
            performance(:,4,:)=14-sum(performance(:,1:3,:),2); %replacing CR rate by the correct one (14-everything else)
            % %hit - %FA
            performance
             pHminusFA=100.*(performance(:,1,:))./(10.^-10+performance(:,1,:)+performance(:,3,:))-performance(:,2,:)./(10.^-10+performance(:,2,:)+performance(:,4,:));           
            prop=[prop;squeeze(mean(pHminusFA/2+50,1))];
        else
            dispi('Temp file detected and skipped')
        end
    end
    prop
    propCR{i}=prop;
end
dispi('Be careful with the interpretation of the run order!!!!')
[listSS',propCR']