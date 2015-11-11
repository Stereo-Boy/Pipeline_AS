function fs4_ribbon2class(segFile)
% convert freesurfer ribbon segmentation file (nifti format) to mrGray class file(s)
% fs4_ribbon2class

% mri_convert /raid/MRI/anatomy/FREESURFER_SUBS/subjid/mri/ribbon.mgz /raid/MRI/anatomy/subject/nifti/xxx.nii.gz

hemi = true;	% hemisheres or whole brain flag

if nargin>0
	if ~exist(segFile,'file')
		error([segFile,' doesn''t exist'])
	end
	[segPath,segFile,ext] = fileparts(segFile);
	segFile = [segFile,ext];
else
	[segFile,segPath]= uigetfile({'*.nii;*.nii.gz','nifti files'},'Freesurfer ribbon file');
	if isnumeric(segFile)
		return
	end
end

%% LOAD NIFTI FILE
if true		% Freesurfer
	% LIA oriented
	% 0=nothing, 2=WM-L, 3=GM-L, 41=WM-R, 42=GM-R
	NII = readFileNifti(fullfile(segPath,segFile));
%{
	if ~true
		NII.data = flipdim(NII.data,1);			% RIA
		NII.data = flipdim(NII.data,3);			% RIP
		NII.data = permute(NII.data,[2 3 1]);	% IPR
	else		% if already transformed to LAS - figure out how to detect this
		NII.data = flipdim(NII.data,1);			% RAS
		NII.data = flipdim(NII.data,2);			% RPS
		NII.data = flipdim(NII.data,3);			% RPI
		NII.data = permute(NII.data,[3 2 1]);	% IPR
	end
%}
		% get nifti rotation matrix
		qb = NII.quatern_b;
		qc = NII.quatern_c;
		qd = NII.quatern_d;
		qa = sqrt(1-qb^2-qc^2-qd^2);
		R = [ qa^2+qb^2-qc^2-qd^2, 2*(qb*qc+qa*qd), 2*(qb*qd-qa*qc);...
				2*(qb*qc-qa*qd), qa^2-qb^2+qc^2-qd^2, 2*(qc*qd+qa*qb);...
				2*(qb*qd+qa*qc), 2*(qc*qd-qa*qb), qa^2-qb^2-qc^2+qd^2];
		R = R';	% only if positive determinant of R?
					% rows of R now [R;A;S]
		R(:,3) = NII.qfac * R(:,3);
		disp(R)

		% now orient to IPR for writeVolAnat to yield PIR vAnatomy
		IPR = [0 0 0];
		[junk,IPR(3)] = max(abs(R(1,:)));	% L-R dimension
		[junk,IPR(2)] = max(abs(R(2,:)));	% P-A dimension
		[junk,IPR(1)] = max(abs(R(3,:)));	% I-S dimension
		if numel(unique(IPR))~=3
			error('bad rotation matrix')
		end
		if any(abs([R(1,IPR(3)),R(2,IPR(2)),R(3,IPR(1))]) < 0.8)
			disp('nifti quaternion inconsistent with 90deg rotations')
		end
		NII.data = permute(NII.data,IPR);
		if R(3,IPR(1)) >= 0
			NII.data = flipdim(NII.data,1);
		end
		if R(2,IPR(2)) >= 0
			NII.data = flipdim(NII.data,2);
		end
		if R(1,IPR(3)) < 0
			NII.data = flipdim(NII.data,3);
		end

	if ~true		% don't use if source anatomy from fs4 too
		nvox = size(NII.data);
		NII.data = NII.data([2:nvox(1),1],:,:);	% shift 1 voxel superior
		NII.data(nvox(1),:,:) = 0;
	end
	classInfo = [0 0; 2 16; 41 16; 3 32; 42 32];
	classInfoL = [0 0; 2 16; 41 0; 3 32; 42 0];
	classInfoR = [0 0; 2 0; 41 16; 3 0; 42 32];
else			% FSL
	% RAS oriented
	% 0=nothing, 1=CSF, 2=GM, 3=WM
	NII = readFileNifti(fullfile(srcDir,[src,'.nii']));
	NII.data = flipdim(NII.data,1);			% ??? really LAS ???
	NII.data = flipdim(NII.data,2);			% RPS
	NII.data = flipdim(NII.data,3);			% RPI
	NII.data = permute(NII.data,[3 2 1]);	% IPR
	classInfo = [0 0; 1 48; 2 32; 3 16];
end

%% WRITE CLASS FILE
% PIR oriented - note: writeClassFileFromRaw transposes slices
% 0 = unknown, 16 = white matter, 32 = gray, 48 = CSF
if hemi
	classPath = segPath;
	% left
	[classFile,classPath] = uiputfile('*.Class','Left hemisphere class file',fullfile(classPath,'left.Class'));
	if ~isnumeric(classFile)
		writeClassFileFromRaw(NII.data,fullfile(classPath,classFile),classInfoL);
	end
	% right
	[classFile,classPath] = uiputfile('*.Class','Right hemisphere class file',fullfile(classPath,'right.Class'));
	if ~isnumeric(classFile)
		writeClassFileFromRaw(NII.data,fullfile(classPath,classFile),classInfoR);
	end
else
	% whole brain
	[classFile,classPath] = uiputfile('*.Class','Whole brain class file',fullfile(segPath,'WB.Class'));
	if ~isnumeric(classFile)
		writeClassFileFromRaw(NII.data,fullfile(classPath,classFile),classInfo);
	end
end

return

%%
% class1 = readClassFile('ribbon.Class',false,false);
% class2 = readClassFile('FSL.Class',false,false);
% data = uint8(zeros(size(class1.data)));							% neither    ==> nothing
% data( (class1.data == 16) & (class2.data == 16) ) = 16;		% both       ==> white
% data( (class1.data == 16) & (class2.data ~= 16) ) = 32;		% freesurfer ==> gray
% data( (class1.data ~= 16) & (class2.data == 16) ) = 48;		% FSL        ==> CSF
% data = permute(data,[2 1 3]);
% writeClassFileFromRaw(data,'FSvFSL.Class',[0 0;16 16;32 32;48 48]);
