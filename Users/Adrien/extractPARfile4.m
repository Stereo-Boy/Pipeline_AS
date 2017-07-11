function extractPARfile4(stamFile, rootName)
% CORRECT VERSION for Adrien (Full model with two configurations / two correlation and cue onset)
% 6 predictors (including fixation)  
%
% This version extracts the design matrix for mrVista into a PAR file, from the stam files.
% The smart thing to do with it is to run it once with a rootName for generated par files
% It will issues a par file by run, with unique code for onset of any crossed/left event correlated, one for uncrossed/left events
% but also one for anti-correlated crossed/left and uncrossed/left events
% With that parfile, a GLM can be run to nourrish the MVPA decoding and get accuracies by selecting only betamaps including
% correlated events and then replicating with betamaps for anticorrelated events only
%
% YOU NEED TO CD IN THE STAM DIRECTORY FIRST
% stamfile is the file with the stimuli matrix
% rootName is the root from which are par file names generated
% Ex of use: extractPARfile2('mv40pre10_MRI_1.mat','epi') will read
% mv40pre10_MRI_1.mat and generate par files called epi01, epi02...
if ~exist('stamFile','var');error('Stam file not defined for extractPARfile function - .mat is important'); end
if ~exist('rootName','var');disp('Default root epi name used: epi'); rootName = 'epi'; end
if ~exist(stamFile,'file');error('Stam file not found for extractPARfile function'); end

%Files need to exist
check_files(cd, stamFile, 1, 1);

disp(['Loading following stam data file: ', stamFile])

    fixationDuration = 7*2.2428;
    dispi('Fixation duration is ', fixationDuration)
    load(stamFile)
    inverted = 0; %if this parameter is 1, it means that LE was not red but green (0 otherwise LE = red)
    if inverted ==1
        answer = input('Data seems inverted (LE sees green), be sure this is correct (1 = yes, 2 = no)');
        if answer>1
           error('Program interrupted') 
        end
    else
        disp('Data are not declared inverted - LE sees red')
    end
    data = runSaved(:,[1,7,10,12,13,15,18]);

                % ----- DATA TABLE STRUCTURE -----
                %    1:  trial # in block; each one is a ON and a OFF
                %    2:  config, where is  closest stimulus 1: left (-/+) - 2: right (+/-)
                %    3: disparity value in arcsec (of left stimulus)
                %    4: correlated (1: yes, 2: anti)
                %    5: block # -chrono order- (one block is either +/- configuration or -/+ configuration and one disp)
                %    6: run nb
                %    7: attentional cue onsets (0 no, 1 yes)
    
    %WRITE one PAR file by EPI, so split data by epi run if more than 1
    runs = logic('union',data(:,6),[]);
    nbRuns = numel(runs);
    if nbRuns>1
        %more than 1 epi
        disp([num2str(nbRuns), ' epis found: split data matrix by epi.'])
        test = data(data(:,6)==runs(1),:); %we assume all runs are equal number of data lines
        dataSplit = nan([size(test),nbRuns]);
        for i=1:nbRuns
            dataSplit(:,:,i) = data(data(:,6)==runs(i),:);
        end
    else
        disp('Only one epi found')
        dataSplit = data;
    end
    
        % codes
        % 0 Fixation
        % 1 -/+ configuration correlated
        % 2 +/- configuration correlated
        % 3 -/+ configuration anti-correlated
        % 4 +/- configuration anti-correlated
        % 5 cue onset  
        
        eventCodes = {'FX', 'L_COR', 'R_COR', 'L_ANT', 'R_ANT', 'CUE'} %NO slash in names
       % colorCodes = [[0.9 0 0]; [0 0.9 0]; [0 0.45 0]; [0 0 0.9]; [0 0 0.45]];
        
    %for each run
    for run = 1:nbRuns
        %select data from that run
        data = dataSplit(:,:,run);
        time = 0; %initialize time
       
        %select one event every 14 (given in each block, all 14 trials are identical)
        data14 = data(1:14:size(data,1),:);
        currentLine = 1; %initialize line of the design matrix in par file

        %Start run with fixation
        parfile = {time 0 eventCodes{1}}; % colorCodes(1,1) colorCodes(1,2) colorCodes(1,3)      
        time = time+fixationDuration;
        currentLine = currentLine + 1;

        for i=1:size(data14,1) %go through each data line
            
            %Given we split data between runs, the following case should not happen
            %anymore (detection of change of run): so I comment it
            %I keep a little code after, to detect if this is actually
            %occuring because it would mean something went wrong...
%             if i>1 && data(i,6)~=data(i-1,6) %DETECT CHANGE OF RUN (we assume a run covers always more than a single data line)
%                 %finish with fixation
%                     parfile(currentLine,:) = {time 0 eventCodes{1} colorCodes(1,1) colorCodes(1,2) colorCodes(1,3)};
%                     currentLine = currentLine + 1;
%                     time = time+fixationDuration;
%                 %start next run with fixation
%                     parfile(currentLine,:) = {time 0 eventCodes{1} colorCodes(1,1) colorCodes(1,2) colorCodes(1,3)};
%                     currentLine = currentLine + 1;
%                     time = time+fixationDuration;
%             end
            if i>1 && data14(i,6)~=data14(i-1,6) %DETECT CHANGE OF RUN
                error('We detected a change of run in the epi data: that should not happen - check the code')
            end
            
                
                if inverted ==1 %deal with inverted eyes (this invert the configuration)
                    code = 3-data14(i,2);
                else
                    code = data14(i,2);
                end
                
                if data14(i,4)==1  % correlated
                    parfile(currentLine,:) = {time code eventCodes{code+1}};
                    %move to next event line
                end
                if data14(i,4)==2  %anti-correlated
                    parfile(currentLine,:) = {time code+2 eventCodes{code+3}};
                    %move to next event line
                end                     
                currentLine = currentLine + 1;
            
            time = round(1000*(time+7*2.2428))/1000;
        end

        %redo this for the cue onset events
        time = fixationDuration;
        for i=1:size(data,1) %go through each data line
            if data(i,7)==1
                parfile(currentLine,:) = {time 5 eventCodes{6}};
                currentLine = currentLine + 1;
            end
            time = round(1000*(time+(2.2428/2)))/1000;
        end
        
        %sort par file by time of onset
        parfile=sortrows(parfile,1);
        
        %finish with fixation on last run
        parfile(currentLine,:)  = {time 0 eventCodes{1}};

        parfile
        writeMatToFile(parfile,[rootName,sprintf('%02.f',runs(run)),'.par'])
    end
end

function writeMatToFile(matvar,fileName)
    if exist(fileName,'file')==2; error(['File ',fileName,' exists, first delete to avoid concatenation']); end
    try  
        file = fopen(fileName, 'a');
        str=char(universalStringConverter(matvar,[],2));
        fprintf(file,sprintf('%s', str));    
        fclose(file);
        disp(['Success in writing file ', fileName]);
    catch errors
        disp('extractPARFile error: Writing the file failed')
        fclose(file);
        rethrow(errors)
    end
end