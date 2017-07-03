function design = transform_L1O_into_L2O(design)

%remove last column (last step of validation)
    design.train(:,end) = [];
    design.test(:,end) = [];
    design.label(:,end) = [];
    
%for each train chunk out, also leave the next one out
    ind=find(design.train==0);
    design.train(ind+1) = 0;

%for each test chunk in, also leave the next one in
    ind2=find(design.test==1);
    if numel(ind)~=numel(ind2), dispi('Inegal number of test and train indexes found - check this'); end
    design.test(ind2+1) = 1;
    
