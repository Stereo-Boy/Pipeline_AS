function dcm2niiConvert(dicom_dir, expr, correctScan_n, correctDcm_n, ni_dir, verbose)
% dcm2niiConvert(dicom_dir, expr, correctScan_n, correctDcm_n, ni_dir, verbose)
%
% Check that dicom_dir contains the correct number of dcm folders (correctScan_n) with the correct number of dcm files in each folder
% (correctDcm_n) and convert the dcm files in nifti (.nii.gz) 4D files in ni_dir with one file for each folder, and finally check the result
%
% dicom_dir : folder where you can find the individual dicom folders to convert to nifti
% expr is an expression or list of expr to localize the individual folders to convert in dicom_dir (typically {'*mpr*/', '*epi*/', '*gems*/'} for mprage, epi and gems)
%   They have to end up with a / (so that only folders are selected)
% correctScan_n is a number or a vector of numbers giving the expected number of scan folders for each items of the list expr
% correctDcm_n is the number or a vector of numbers giving the expected number of dcm files (TR/slices) for each folder of the list expr
% ni_dir -> where to send the converted files
% verbose - verboseOFF or verboseON (default)
%
% Written in Jan 2017 (Adrien Chopin) from previous functions writtent by Justin Theiss

    if ~iscell(expr); expr={expr}; end %convert expr in cell list if necessary
    if iscell(correctScan_n); correctScan_n=cell2mat(correctScan_n); end %convert correctScan_n in vector if necessary
    if iscell(correctDcm_n); correctDcm_n=cell2mat(correctDcm_n); end %convert correctDcm_n in vector if necessary
    if ~exist('verbose','var')||isempty(verbose), verbose = 'verboseON'; end;

    for i=1:numel(expr)
        %1/ check that all folders and files are where they should be
        % list the different folders to convert
        dcm_dirs = get_dir(dicom_dir,expr{i});
        %list that the correct number of TR/slices is present in each dicom folder
        dcm_dir_n=numel(dcm_dirs); %check whether number of TR matches with what we expect
        if dcm_dir_n==correctScan_n(i), dispi(dcm_dir_n,'/',correctScan_n(i),' scan folders correctly detected', verbose); 
        else erri(dcm_dir_n,'/',correctScan_n(i),' scan folders detected: incorrect number'); 
        end
        for ff=1:dcm_dir_n  %check that we have the correct number of dcm files in each folder
            check_files(dcm_dirs{ff},'*.dcm', correctDcm_n(i), 0, verbose); %looking for the expected nb of dcm files
        end
    
        %2/ convert
        if numel(dcm_dirs)>0
            loop_system('dcm2niix','-x n','-z y','-f %f','-o',ni_dir,dcm_dirs(:),verbose); % run dcm2niix for each of these dir
            % parameters for dcm2nii: -z y : gzip the files    -s n : convert all images in folder -t y : save a text note file 
                    % -x n : do not crop -v n : no verbose -o : output directory / end term: input directory   
        end
        
    end
    
        %3/ check the conversion
        check_files(ni_dir, '*nii*', sum(correctScan_n), 1, verbose);
        
    %outputs{step} = get_dir(mpr_ni_dir,'*.nii.gz');
end