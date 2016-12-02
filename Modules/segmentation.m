function segmentation(subjID, mprage_dir, seg_dir, verbose)
% segmentation(subjID, mprage_dir, seg_dir, verbose)
% fMRI processing pipeline whose goal is to automatize steps as much as
% possible
%
% Inputs: 
% subjID: name of folder in freesurfer SUBJECTS_DIR to be created
% mprage_dir: folder containing mprage to segment
% seg_dir: folder to create to output segmented files
% verbose: 'verboseOFF' to prevent displays (default is 'verboseON')
%
% This allows either itkGray or mrGray file conversion based on user input.
% Justin Theiss and Adrien Chopin
% Legacy Adrien Chopin, Sara Popham late Aug 2015

% init vars
if ~exist('verbose', 'var')||~strcmp(verbose,'verboseOFF'), verbose = 'verboseON'; end;
if ~exist('subjID','var'), warning_error('segmentation: subjID not defined', 'errorON'); end;
if ~exist('mprage_dir','var')||isempty(mprage_dir), mprage_dir = pwd; end;
if ~exist('seg_dir','var')||isempty(seg_dir), seg_dir = fullfile(mprage_dir,'Segmentation'); end;

% check FREESURFER_HOME variable exists
if isempty(getenv('FREESURFER_HOME')),
    fs_dir = uigetdir(pwd,'Choose Freesurfer folder:');
    if ~any(fs_dir), warning_error('No FREESURFER_HOME variable set','errorON'); end;
    setenv('FREESURFER_HOME',fs_dir);
end

% check SUBJECTS_DIR variable exists
if isempty(getenv('SUBJECTS_DIR')),
    subjs_dir = uigetdir(pwd,'Choose Freesurfer SUBJECTS_DIR folder:');
    if ~any(subjs_dir), warning_error('No SUBJECTS_DIR variable set','errorON'); end;
    setenv('SUBJECTS_DIR',subjs_dir);
end

% check for specific subject director at SUBJECTS_DIR
fs_subjdir = fullfile(getenv('SUBJECTS_DIR'), subjID);
if exist(fs_subjdir,'dir'),
    dispi('A subject folder for this participant already exists in ', getenv('SUBJECTS_DIR'), verbose);
    dispi('Deleting ', fs_subjdir, verbose);
    rmdir(fs_subjdir,'s');
end

% WHITE MATTER SEGMENTATION
dispi('Starting white matter segmentation. May take 8-24 hours to complete...\n',...
    repmat('-',1,40),verbose);
% get mprage_file
mprage_file = get_dir(mprage_dir,'*mprage*.nii.gz',1);
% run recon-all
dispi('Starting recon-all code on file:', mprage_file, verbose);
loop_system('recon-all','-i',mprage_file,'-subjid',subjID,'-all',verbose);
% check for ribbon.mgz file
check_exist(fullfile(fs_subjdir,'mri'), 'ribbon.mgz', 1, verbose, 'errorON');

% MGZ TO NII CONVERSION
if ~check_exist(fullfile(fs_subjdir,'mri'),[subjID,'_nu_RAS_NoRS.nii.gz'],1,verbose),
    dispi(repmat('-',1,10),'Starting conversion of mgz files to nifti',repmat('-',1,10),verbose);
    % convert mgz file to nifti
    loop_system('mgz2niiOrNoRS.sh',subjID,'RAS');
end

% SET UP FILES FOR ITKGRAY 
check_exist(fullfile(fs_subjdir,'mri'),[subjID,'_nu_RAS_NoRS.nii.gz'],1,verbose,'errorON');
dispi('Setting up files for itkGray', verbose);
dispi('Starting fs_ribbon2itk to convert nifti file to itkGray class file', verbose);
% check for t1_class file, otherwise run fs_ribbon2itk
if ~check_exist(fullfile(fs_subjdir,'mri'),'t1_class.nii.gz',1,verbose)
    % run fs_ribbon2itk
    fs_ribbon2itk(subjID);
end % check again for t1_class file
check_exist(fullfile(fs_subjdir,'mri'),'t1_class.nii.gz',1,verbose,'errorON');

% COPY FILES TO seg_dir
dispi(repmat('-',1,10),'Cleaning - Copying files back to your segmentation folder',repmat('-',1,10),verbose);
dispi('Copying ', [subjID '_nu_RAS_NoRS.nii.gz file...'], verbose);
copyfile(fullfile(fs_subjdir,'mri',[subjID,'_nu_RAS_NoRS.nii.gz']), seg_dir);
dispi('Copying t1_class.nii.gz file...', verbose);
copyfile(fullfile(fs_subjdir,'mri','t1_class.nii.gz'),seg_dir);

% check that itkGray files were actually put in the correct place
check_exist(seg_dir, 't1_class.nii.gz', 1, verbose, 'errorON');
check_exist(seg_dir, [subjID '_nu_RAS_NoRS.nii.gz'], 1, verbose, 'errorON');
end