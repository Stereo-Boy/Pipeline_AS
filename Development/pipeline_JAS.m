function pipeline_JAS(stepList2run)
% ------------------------------------------------------------------------
% Automated pipeline for mrVista analysis
% stepList2run is a list of numbers corresponding to the possible steps to
% run
% If stepList2run is not defined, it will show a menu of all steps and asks
% for an answer.
% TEST
%
% Steps available to run:
%   0. All of the below steps
%   1. mprage: nifti conversion
%   2. mprage: fix nifti header
%   3. mprage: segmentation using FSL
%   4. mprage: correction of gray mesh irregularities
%   5. retino epi: nifti conversion and removal of ''pRF dummy'' frames
%   6. retino epi: motion correction and MC parameter check
%   7. retino epi: artefact removal
%   8. retino epi: fix nifti headers
%   9. retino epi: initialization of mrVista session
%   10. retino epi: alignment of inplane and volume
%   11. retino epi: segmentation installation
%   12. retino epi: pRF model
%   13. retino epi: mesh visualization of pRF values
%   14. retino epi: extraction of flat projections
%   15. exp epi: nifti conversion
%   16. exp epi: motion correction and MC parameter check
%   17. exp epi: artefact removal
%   18. exp epi: fix nifti headers
%   19. exp epi: initialization of mrVista session
%   20. exp epi: alignment of inplane and volume
%   21. exp epi: segmentation installation
%   22. exp epi: GLM sanity check
%   23. exp epi: actual GLM model
%   24. exp epi: mesh visualization
% ------------------------------------------------------------------------
% Written Nov 2016
% Justin Theiss and Adrien Chopin
% Legacy Adrien Chopin, Sara Popham late Aug 2015
% From the work made by Eunice Yang, Rachel Denison, Kelly Byrne, Summer
% Sheremata
% ------------------------------------------------------------------------------------------------------------


% MENU
if exist('stepList2run', 'var')==0
    help(mfilename);
    stepList2run=input('Enter the numbers of the desired steps, potentially between brackets: ');
end

% CHECKS THAT steps are numbers
if isnumeric(stepList2run)
    if stepList2run==0
       stepList2run=1:24; 
    end
else
    error('The step starter accepts only numeric descriptions.')
end
    
    
