function motion_parameters(mc_dir)
%

% get files
d = dir(fullfile(mc_dir,'epi*.par'));
files = fullfile(mc_dir,{d.name});

% params are rot x, y, z and trans x, y, z 
params = [];
for x = 1:numel(files),
    tmp = load(files{x});
    params = cat(1,params,tmp);
end

% get absolute differences between trs
pdiff = abs(diff(params,1));

% create rotation matrix for each tr and...
for t = 1:size(pdiff,1),
    % build matrix
    rot_mat = affineBuild([0,0,0], pdiff(t,1:3), [1,1,1], [0,0,0]);
    % remove 4th row and column
    rot_mat = rot_mat(1:3,1:3);
    % multiply by brain dims
    
end
