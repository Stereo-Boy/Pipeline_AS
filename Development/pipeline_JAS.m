function pipeline_JAS(stepList2run)
% ------------------------------------------------------------------------
% Automated pipeline for mrVista analysis
% stepList2run is a list of numbers corresponding to the possible steps to
% run
% If stepList2run is not defined, it will show a menu of all steps and asks
% for an answer.
% ------------------------------------------------------------------------
% Written Nov 2016
% Justin Theiss and Adrien Chopin
% Legacy Adrien Chopin, Sara Popham late Aug 2015
% From the work made by Eunice Yang, Rachel Denison, Kelly Byrne, Summer
% Sheremata
% ------------------------------------------------------------------------------------------------------------


% MENU
if exist('stepList2run', 'var')==0
    dispi('What step do you want to run?')
    dispi('0. All of the below steps')
    dispi('1. mprage: nifti conversion')
    dispi('2. mprage: fix nifti header')
    dispi('3. mprage: segmentation using FSL')
    dispi('4. mprage: correction of gray mesh irregularities')
    dispi('5. retino epi: nifti conversion and removal of ''pRF dummy'' frames')
    dispi('6. retino epi: motion correction and MC parameter check')
    dispi('7. retino epi: artefact removal')
    dispi('8. retino epi: fix nifti headers')
    dispi('9. retino epi: initialization of mrVista session')
    dispi('10. retino epi: alignment of inplane and volume')
    dispi('11. retino epi: segmentation installation')
    dispi('12. retino epi: pRF model')
    dispi('13. retino epi: mesh visualization of pRF values')
    dispi('14. retino epi: extraction of flat projections')
    dispi('15. exp epi: nifti conversion')
    dispi('16. exp epi: motion correction and MC parameter check')
    dispi('17. exp epi: artefact removal')
    dispi('18. exp epi: fix nifti headers')
    dispi('19. exp epi: initialization of mrVista session')
    dispi('20. exp epi: alignment of inplane and volume')
    dispi('21. exp epi: segmentation installation')
    dispi('22. exp epi: GLM sanity check')
    dispi('23. exp epi: actual GLM model')
    dispi('24. exp epi: mesh visualization')
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
    
    
