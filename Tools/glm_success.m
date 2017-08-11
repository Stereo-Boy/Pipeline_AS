function glm_success(glm_dir, grayFlag)

%grayFlag indicates whether we work with gray maps (1-default) or not (0) (they are sized differently)

%check that dir are existing (it should be the folder in mrVista session Gray folder
if ~exist('glm_dir','var')||isempty(glm_dir), glm_dir = cd; dispi('[glm_success] empty glm_dir defaulted to ',glm_dir); end;
if ~exist('grayFlag','var')||isempty(grayFlag), grayFlag = 1; dispi('[glm_success] empty grayFlag defaulted to ',grayFlag); end;
check_folder(glm_dir, 1); %needs to exist

%load model
close all
load(fullfile(glm_dir, 'Proportion Variance Explained.mat'))
all_maps=[];

    for i=1:size(map,2) %all runs for each voxel
        if grayFlag==1
             all_maps=[all_maps;map{i}];
        else
            thisMap=map{i};
            all_maps=[all_maps;thisMap(:)'];
        end
      %  subplot(2,4,i)
      % hist(map{i})
      % size(all_maps)
    end

%figure()
%plot(median(all_maps,2))

 all_maps_med = mean(all_maps)*100; %median % variance explained across all runs for each voxel
% bf = size(all_maps_med,2);
% %filtering out very variables voxels (std across runs)
% all_maps_med(std(all_maps)./std(all_maps(:))>1.5)=[];
% dispi('Filtering out ', bf-size(all_maps_med,2), ' most variable voxels across runs (>1.5 mean variation) - ', (bf-size(all_maps_med,2))/bf*100, '%') 
dispi('Median % variance explained: ', median(all_maps_med), '%')
dispi('% of good voxels (with % variance explained >3): ', 100*sum(all_maps_med>3)./numel(all_maps_med), '%')
dispi('Nb of good voxels (with % variance explained >10): ', sum(all_maps_med>10))
dispi('% of good voxels (with % variance explained >10): ', 100*sum(all_maps_med>10)./numel(all_maps_med), '%')
dispi('Average % variance explained for the best half of the voxels: ', mean(all_maps_med(all_maps_med>median(all_maps_med))),'%')
figure()
subplot(1,3,1)
hist(all_maps_med)
titleAxis('All voxels','% variance explained','n',15)
axis square
subplot(1,3,2)
boxplot(all_maps_med)
limit = quantile(all_maps_med,0.95);
titleAxis('All voxels','boxplot','%variance explained',15)
axis square
subplot(1,3,3)
dispi('Average % variance explained for the best 5% of the voxels: ', mean(all_maps_med(all_maps_med>limit)),'%')
hist((all_maps_med(all_maps_med>limit)))
axis([limit max(all_maps_med) 0 numel(all_maps_med)/30])
titleAxis('5% best voxels','%variance explained','n',15)
axis square
