test -e /etc/profile && echo "Sourcing /etc/profile" || echo "/etc/profile not found"
export PATH=/etc/bin:/usr/X11/bin:${PATH}

#Avoiding language specific issues
LC_NUMERIC=en_GB.UTF-8 
export LC_NUMERIC

# Setting PATH for Python 3.4# The original version is saved in .bash_profile.pysave
pythonLib=/Library/Frameworks/Python.framework/Versions/3.4/bin
test -e $pythonLib && echo "Adding python libraries to path" || echo "python libraries not found"
PATH=${pythonLib}:${PATH}
export PATH

# Add FSL - Double check that FSL path is defined correctly
FSLDIR=/usr/local/fsl 
test -e $FSLDIR && echo "Adding FSL is in path" || echo "FSL not found"
PATH=${FSLDIR}/bin:${FSLDIR}/etc/fslconf/:${FSLDIR}:${PATH} 
export FSLDIR PATH

# Add MricroGL path for dcn2nii 
pathMRIcron=/Users/adrien_chopin/Desktop/MRIcroGL
# pathMRIcron =/usr/local/mricron
test -e $pathMRIcron && echo "Adding  MRIcron to path" || echo "MRIcron not found"
PATH=${pathMRIcron}:${PATH}
export PATH

# Add freesurfer path (necessary in order to run itkGray and white segmentation 
# scripts from matlab later)
freesurferPath=/Applications/freesurfer
test -e $freesurferPath && echo "Adding Freesurfer to path" || echo "Freesurfer not found"
PATH=${freesurferPath}/bin:${freesurferPath}/mni/bin:${PATH}
export PATH

# export freesurfer home env variable
export freesurferPath
SUBJECTS_DIR=${freesurferPath}/subjects
test -e $SUBJECTS_DIR && echo "Exporting Freesurfer path and subject folder" || echo "Freesurfer subject folder not found"
export SUBJECTS_DIR
export FREESURFER_HOME=${freesurferPath}
FUNCTIONALS_DIR=${freesurferPath}/sessions
test -e $SUBJECTS_DIR && echo "Exporting Freesurfer session folder" || echo "Freesurfer session folder not found"
export FUNCTIONALS_DIR

# Add path to segmentation files - change that to yours
segm=~/Desktop/Pipeline_AS/Tools
test -e $segm && echo "Adding Segmentation to path" || echo "Segmentation not found"
PATH=${segm}:${PATH}
export PATH

echo "Sourcing FreeSurferEnv.sh and fsl.sh"
. ${freesurferPath}/FreeSurferEnv.sh
. ${FSLDIR}/etc/fslconf/fsl.sh

#what about /Applications/freesurfer/fsfast/bin and /Applications/freesurfer/tktools ?

# Add path to Users files in pipeline  - change that to yours
#segm1=~/Desktop/Megavista/zUsers/Adrien
#segm2=~/Desktop/Megavista/zUsers/Sara
#test -e $segm1 && echo "zUsers/Adrien is in path" || echo "zUsers/Adrien not found"
#test -e $segm2 && echo "zUsers/Sara is in path" || echo "zUsers/Sara not found"
#PATH=${segm1}:${segm2}:${PATH}
#export PATH

echo "PATH is defined to ${PATH}"


# Setting PATH for Python 3.4
# The orginal version is saved in .bash_profile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/3.4/bin:${PATH}"
export PATH
