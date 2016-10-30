#!/Library/Frameworks/Python.framework/Versions/Current/bin/python
#motioncorrect_alt.py

"""This script uses mcflirt to run motion correction on 4d niftis.
These niftis should already be in the file structure expected by mrVista,
which can be created using dicom2vista_org.py.

This script will attempt to motion correct all files starting with 'epi' and 'gems'
that are located in the session _nifti directory. It will motion correct
to a reference volume, which is the middle volume of the scan. It expects
this volume to be found in the session _dicom directory in a subdirectory 
starting with 'epi##'.

2011-Oct-17 RD wrote it, modified from dicom2vista_rd.py
2015-Oct-23 SP wrote it, modified from motioncorrect.py
""" 

import os
import glob
import numpy as np
import sys

from matplotlib import pyplot as plt

if __name__ == "__main__":
	
    #The full path to the session files is a command-line argument: 
    sess_dir = sys.argv[1]
    if sess_dir[-1]=='/': #If a trailing backslash has been input
        sess_dir=sess_dir[:-1]
    sess_name = os.path.split(sess_dir)[1]

    #switch to session directory:
    os.chdir(sess_dir)

    #Directory names: these directories are expected
    dicom_dir = sess_dir + '/' + sess_name + '_dicom/'
    nifti_dir = sess_dir + '/' + sess_name + '_nifti/'

    os.chdir(nifti_dir)
    print 'Moving to:'
    print os.path.realpath(os.path.curdir) #e.g. .../04A_MoCo/04A_MoCo_nifti

    nifti_list = np.array(os.listdir(nifti_dir))
    print 'List of nifti files found:'
    print(nifti_list)
    #In order to not include '.DS_store:'
    epi_list = []
    gems_list = []
    for file in nifti_list:
        if file.startswith('epi'):
            epi_list.append(file)
        if file.startswith('gems'):
            gems_list.append(file)

    # First find the middle epi and use it as ref_vol.nii
    num_epis = len(epi_list)
    mid_epi_index=num_epis//2
    print('-------------------------------------------------------------------')
    print('Creating reference volume from middle epi volume ' + str(mid_epi_index) + ' out of ' + str(num_epis))
    mid_epi = epi_list[mid_epi_index]
    epi_mid_dir = os.path.splitext(os.path.splitext(mid_epi)[0])[0]
    mid_epi_dir = dicom_dir + epi_mid_dir
    os.chdir(mid_epi_dir)
    print('For that, moving to ' + mid_epi_dir) #e.g. .../04A_MoCo/04A_MoCo_dicom/epi02_retino_13
    mid_dicom_list = np.array(os.listdir(mid_epi_dir))
    middle_total_TR = len(mid_dicom_list)//2
    mid_mid_dicom = mid_dicom_list[len(mid_dicom_list)//2]

    print('and executing dcm2niix on ' + mid_mid_dicom + ' (dicom ' + str(middle_total_TR) +  ') of ' + epi_mid_dir)
    print('-------------------------------------------------------------------')
    os.system('dcm2niix -z n -s y -t y -x n -v n ' + mid_mid_dicom) #non-zipped single file
    os.system('mv *.nii ref_vol.nii')
            
    #Move ref_vol to nifti directory
    ref_vol_path = nifti_dir + 'ref_vol.nii'
    os.system('mv ref_vol.nii ' + ref_vol_path)
            
    os.chdir(nifti_dir)
    print os.path.realpath(os.path.curdir)

# ACTUAL MOTION CORRECTION
#Run mcflirt motion correction on the 4d nifti file with
#the params (cost=mutualinfo and smooth=16) are taken from the
#Berkeley shell-script AlignFSL070408.sh:

    # Do motion correction on GEMS list (more than one can be corrected whenever they start with the letters 'gems')
    for this_gems in gems_list:
        print('Motion correction for ' + this_gems)
        os.system('mcflirt -reffile ' + ref_vol_path +
                  ' -plots -report -cost mutualinfo -smooth 16 -in ' +
                  this_gems)
        print('DONE')

    # Do motion correction on epis
    for this_epi in epi_list: 
        print('Motion correction for ' + this_epi)
        os.system('mcflirt -reffile ' + ref_vol_path +
              ' -plots -report -cost mutualinfo -smooth 16 -in ' + 
              this_epi)
        print('DONE')

	    #Remove the file that was used as reference for MC:
	    # os.system('rm ' + ref_vol_path)
	
	