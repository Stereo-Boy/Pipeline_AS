function decoding_success(map,sessionDir)

%check that dir are existing (it should be the folder in mrVista session 
if ~exist('sessionDir','var')||isempty(sessionDir), sessionDir = cd; dispi('[decoding_success] empty sessionDir defaulted to ',sessionDir); end;
check_folder(sessionDir, 1); %needs to exist

%load model
close all
load(fullfile(sessionDir, 'mvpa',map))

all_voxels = map{1}; %all voxels % decoding

dispi('Median % decoding: ', median(all_voxels), '%')
dispi('% of good voxels (with % decoding >10): ', 100*sum(all_voxels>10)./numel(all_voxels), '%')
dispi('Nb of good voxels (with % variance explained >10): ', sum(all_voxels>10))
dispi('Average % decoding for the best half of the voxels: ', mean(all_voxels(all_voxels>median(all_voxels))),'%')
bestVoxPerc=5;
limit = quantile(all_voxels,1-bestVoxPerc/100);
dispi('Average % decoding for the best ',bestVoxPerc,'% of the voxels: ', mean(all_voxels(all_voxels>limit)),'%')

figure()
subplot(2,2,1)
hist(all_voxels)
titleAxis('All voxels','% decoding','n',15)
axis square

subplot(2,2,2)
boxplot(all_voxels)
titleAxis('All voxels','boxplot','% decoding',15)
axis square

bestVox=nan(100,1);
for i=1:100
    limitX = quantile(all_voxels,1-i/100);
    bestVox(i)=median(all_voxels(all_voxels>limitX));    
end
subplot(2,2,3)
plot(1:100,bestVox)
titleAxis('% best voxels','%','Median % decoding',15)
axis square

subplot(2,2,4)
hist((all_voxels(all_voxels>limit)),4)
%axis([limit max(all_voxels) 0 numel(all_voxels)/30])
titleAxis('5% best voxels','% decoding','n',15)
axis square
