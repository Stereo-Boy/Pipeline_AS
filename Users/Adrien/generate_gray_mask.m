

% Script loading gray coords and convert them in a nifti file mask in the mprage format
% You need to start from the mrvista session folder

cd Gray
load coords.mat
coordsGray=coords;

mprage_space=zeros(256,256,256);
inds=sub2ind([256,256,256],coords(1,:),coords(2,:),coords(3,:)); %linear index for gray voxels in mprage space

%use those index to mask mprage space with gray voxels only
gray_mask=mprage_space;
gray_mask(inds)=1;

%rotate the matrix toward nifti space - nifti space in in LPI (L is origin) and coords are in SAL
permuted_mask = permute(gray_mask,[3,2,1]); %permute dim 1 and 3 to get LAS
permuted_mask = permuted_mask(:,end:-1:1,end:-1:1); %flip 2 and 3 to get LPI

cd ..
cd nifti
%load nifti mprage and mask the non-gray voxels
ni=niftiRead('mprage_nu_RAS_NoRS.nii.gz');
ni.data(permuted_mask==0)=0;
size(ni.data)
niftiWrite(ni,'gray_mask_test.nii.gz')

