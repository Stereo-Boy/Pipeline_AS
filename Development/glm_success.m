function glm_success(glm_dir)

%check that dir are existing
if ~exist('glm_dir','var')||isempty(glm_dir), glm_dir = cd; dispi('[glm_success] empty glm_dir defaulted to ',glm_dir); end;
check_folder(glm_dir, 1); %needs to exist

%load model
load(fullfile(glm_dir, 'Proportion Variance Explained.mat'))
all_maps=[];
for i=1:size(map,2)
   all_maps=[all_maps;map{i}];
end

 all_maps_med = median(all_maps); %median % variance explained across all runs for each voxel
% bf = size(all_maps_med,2);
% %filtering out very variables voxels (std across runs)
% all_maps_med(std(all_maps)./std(all_maps(:))>1.5)=[];
% dispi('Filtering out ', bf-size(all_maps_med,2), ' most variable voxels across runs (>1.5 mean variation) - ', (bf-size(all_maps_med,2))/bf*100, '%') 
dispi('Median % variance explained: ', median(all_maps_med)*100, '%')
dispi('Mean % variance explained: ', mean(all_maps_med)*100, '%')
dispi('Nb of good voxels (with % variance explained >3): ', sum(all_maps_med>0.03))
dispi('% of good voxels (with % variance explained >3): ', 100*sum(all_maps_med>0.03)./numel(all_maps_med), '%')
