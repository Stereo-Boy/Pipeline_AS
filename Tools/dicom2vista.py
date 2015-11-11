#!/Library/Frameworks/Python.framework/Versions/Current/bin/python
#dicom2vista.py

"""This script takes the raw dicoms as they come off the scanner, and
creates the environment that mrVista expects to find, when running
mrInit2

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
    dir_list = np.array(os.listdir('.')) 
    #In order to not include '.DS_store'
    dir_list = dir_list[np.where(dir_list!='.DS_Store')]

    #Make the expected directory structure, if it's not there already:
    if not(np.any(np.where(dir_list == sess_name + '_nifti'))):
        #os.mkdir (sess_name+'_backup')
        os.mkdir (sess_name+'_dicom')
        os.mkdir (sess_name+'_nifti')

    #Exclude these directories:
    dir_list = dir_list[np.where(dir_list!=sess_name + '_dicom')]
    dir_list = dir_list[np.where(dir_list!=sess_name + '_nifti')]

    #Making backups takes a lot of time, so don't
    #print("Making backups")
    #Copy everything into the backups directory
    
    #for this_dir in dir_list:
    #    os.system('cp -r ' + this_dir + ' ' + sess_name + '_backup/')
        

    #make empty containers to add the motion params to, for plotting purposes:
    #Three rotation params:
    r1 = np.array([]) 
    r2 = np.array([])
    r3 = np.array([])
    #And three translations:
    t1 = np.array([])
    t2 = np.array([])
    t3 = np.array([])

    #Main loop:
    for this_dir in dir_list: 
        os.chdir(sess_dir+'/'+this_dir)
        get_dir = np.array(os.listdir('.'))
                  
        #Run the following only if there is no mc params file there:
        if not np.any(np.where(get_dir == this_dir + '_mcf.par')):
            print("Processing files in " + this_dir)
            #Run dcm2nii in order to do the conversion:
            print ("Converting dicom files to nifti")

            os.system('dcm2nii -f *.dcm ' + this_dir)
            #Change the name to the directory name: 
            os.system('mv *.nii.gz ' + this_dir + '.nii.gz')

            #In the first epi directory, convert the first image to nifti,
            #to be used in motion correction afterwards as reference:

            if this_dir!='gems':
                if this_dir[4]=='1':
                    os.system('dcm2nii -g N *0001.dcm')
                    os.system('mv *.nii ref_vol.nii')

                print('Motion correction')

                #Run mcflirt motion correction with reference to the first
                #volume in the first epi (this assumes that the gems were
                #acquired right before the first run). The params
                #(cost=mutualinfo and smooth=16) are taken from the Berkeley
                #shell-script AlignFSL070408.sh:
                os.system('mcflirt -reffile ../epi01/ref_vol.nii -plots ' +
                          '-report '+ '-cost mutualinfo -smooth 16 -in '+
                          this_dir+'.nii.gz')
                      
        #Get the motion correction params if this is not the gems directory: 
        if this_dir!='gems':
            dt = dict(names = ('R1','R2','R3','T1','T2','T3'), 
                  formats = (np.float32,np.float32,np.float32,
                             np.float32,np.float32,np.float32))
            motion_params = np.loadtxt(this_dir + '_mcf.par',dt)
            
            r1 = np.append(r1,motion_params['R1'])
            r2 = np.append(r2,motion_params['R2'])
            r3 = np.append(r3,motion_params['R3'])
            t1 = np.append(t1,motion_params['T1'])
            t2 = np.append(t2,motion_params['T2'])
            t3 = np.append(t3,motion_params['T3'])

    #After doing all that copy stuff into the right places:
    for this_dir in dir_list:
        os.chdir(sess_dir)
        os.system('mv ' + this_dir + ' ' + sess_name + '_dicom/')    
        os.chdir(sess_name + '_dicom/' + this_dir)
        os.system('mv *.nii.gz ../../' + sess_name + '_nifti/')

        if this_dir!='gems':
            os.system('mv *.par ../../' + sess_name + '_nifti/')
            #Remove the file that was used as reference for MC:
            if this_dir[4]=='1':
                os.system('rm ref_vol.nii')

    os.chdir('../../' + sess_name + '_nifti/')
    
    #Plot the motion params: 
    fig = plt.figure()
    ax1 = fig.add_subplot(2,1,1)
    ax1.plot(t1)
    ax1.plot(t2)
    ax1.plot(t3)
    ax1.set_ylabel('Translation (mm)')
    ax2 = fig.add_subplot(2,1,2)
    ax2.plot(r1)
    ax2.plot(r2)
    ax2.plot(r3)
    ax2.set_ylabel('Rotation (rad)')
    ax2.set_xlabel('Time (TR)')
    fig.savefig(sess_name + '_motion_params.png')
    os.system('open ' + sess_name + '_motion_params.png')
