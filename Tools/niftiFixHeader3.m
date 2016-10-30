function niftiFixHeader3(dataDir)
% 07.01.15
% Kelly Byrne
% modified version - Adrien Chopin, 2015

%McFLIRT is loosing infos in the header and we want that info back

disp('[niftiFixHeader] WARNING - this is a version specific to analysing Adrien''s experiment with vistasoft 2015 and pipeline_AS.')
disp('Check the params of your scanning sessions before proceeding (press a key).')
beep; pause;

%the function opens the below directory and find all COMPRESSED nifty files
%to fix them, if their names start with keywords epi, gems or mprage

    % %the function opens the below directory and find all directory in it
    % %then it goes through each one and find all nifty files to fix them
if ~exist('dataDir','var')==1
    disp(['No input folder entered: will use current folder which is ', cd])
    disp('Press a key')
    datadir = cd;
    beep; pause;
end
cd(dataDir)
% files = dir;
% directoryNames = {files([files.isdir]).name}; %makes a list of dir in the dir
% directoryNames = directoryNames(~ismember(directoryNames,{'.','..'})); %remove the . and .. dirs
% nCases = length(directoryNames);
% for k = 1:nCases %go through each dir and find the nii files
   % casePath = [dataDir filesep directoryNames{k} filesep 'nifti'];
   % cd(casePath)
   fixed = 1;
   disp(['Looking for nii files in ', dataDir])
   fileList = dir;
   fileListName = {fileList.name};
   niiFileList={}; %this is a list of nii files for that dir
   for i = 1:numel(fileListName)
       if numel(fileListName{i})>5 && strcmp(fileListName{i}(end-5:end),'nii.gz')==1 %min of 6 letters for the name
           niiFileList{end+1} = fileListName{i};
       end
   end
   
if numel(niiFileList)>0
   disp('Will now fix the following files:') 
   disp(niiFileList')
   
    for j=1:numel(niiFileList)
        ni = readFileNifti(niiFileList{j});
       % if ismember(ni.descrip,{'GEMS_stam','epi_stam'})
       if numel(ni.fname)>3 && strcmp(ni.fname(1:3),'epi') || strcmp(ni.fname(1:4),'gems')
            ni.qform = 1; %we used method 3, which is why we assign both qform and sform to 1
            ni.sform = 1; %you could decide differently
            %However, if method 2 was used on your nifti conversion, you will get
            %an error when you force method 3 here in nifti header because it will copy
            %below the null sto_xyz to the qto_xyz
            ni.freq_dim = 1; % x is 1, y is 2, z is 3 - in neurology, this is L <-> R; P <-> A; I <-> S
            ni.phase_dim = 2; 
            ni.slice_dim = 3;
            ni.slice_end = ni.dim(ni.slice_dim)-1; %(number of slices-1) 38-1
            if length(ni.pixdim)>3 % pixdim(4) = TR    %EPI
                TR = ni.pixdim(4);
            else %GEMS
                TR = 0; %to be safe, given the error with mprage (but we are not sure this is actually correcting an error for gems)
                %ni.dim(4) = 1; %to avoid a warning
                %ni.pixdim(4) = 1; %to avoid a warning
            end
            disp(['Check that your TR is: ',num2str(TR), ' sec'])
            ni.slice_duration = TR/(ni.slice_end+1); %(TR/#slices)
            ni = niftiCheckQto(ni);
            writeFileNifti(ni);
            disp(['EPI or GEMS file ', niiFileList{j},' is fixed'])
            checkNifti(niiFileList{j})
       elseif (numel(ni.fname)>5 && strcmp(ni.fname(1:6),'mprage')) %initial mprage
            ni.qform = 1; %we used method 3, which is why we assign both qform and sform to 1
            ni.sform = 1; %you could decide differently
            %However, if method 2 was used on your nifti conversion, you will get
            %an error when you force method 3 here in nifti header because it will copy
            %below the null sto_xyz to the qto_xyz
            ni.freq_dim = 1; 
            ni.phase_dim = 2;
            ni.slice_dim = 3;
            ni.slice_end = ni.dim(ni.slice_dim)-1; %160-1
            ni.slice_duration = 0; % it has to be 0 to avoid slice timing correction and some further error
            %ni.dim(4) = 1; %to avoid a warning
            %ni.pixdim(4) = 1; %to avoid a warning
            ni = niftiCheckQto(ni);
            writeFileNifti(ni);
            disp(['MPRAGE file ', niiFileList{j},' is fixed'])
            checkNifti(niiFileList{j})
       elseif (numel(ni.fname)>18 && strcmp(ni.fname(end-18:end),'_nu_RAS_NoRS.nii.gz'))||...
               (numel(ni.fname)>7 && strcmp(ni.fname(1:8),'t1_class')) %MPRAGE
            ni.qform = 1; %we used method 3, which is why we assign both qform and sform to 1
            ni.sform = 1; %you could decide differently
            %However, if method 2 was used on your nifti conversion, you will get
            %an error when you force method 3 here in nifti header because it will copy
            %below the null sto_xyz to the qto_xyz
            ni.freq_dim = 1; 
            ni.phase_dim = 2;
            ni.slice_dim = 3;
            ni.slice_end = ni.dim(ni.slice_dim)-1; %(number of slices-1) after conversion to isotropic conformed space which is 256^3
            ni.slice_duration = 0; % it has to be 0 to avoid slice timing correction and some further error
            %ni.dim(4) = 1; %to avoid a warning
            %ni.pixdim(4) = 1; %to avoid a warning
            ni = niftiCheckQto(ni);
            writeFileNifti(ni);
            disp(['MPRAGE file ', niiFileList{j},' is fixed'])
            checkNifti(niiFileList{j})
        else
            disp(['Non-recognized file ', niiFileList{j},' is skipped'])
            fixed = 0;
        end
    end
   
else
       disp('No nii.gz files found')
       fixed = 0;
end
   
    if fixed == 1
        % leave a lame log file
        fid = fopen('epiHeaders_FIXED.txt', 'at');
        fprintf(fid, datestr(now));
        %fprintf(fid, 'Files fixed are:/n');
        %fprintf(fid, );
        fclose(fid);
    end
    

