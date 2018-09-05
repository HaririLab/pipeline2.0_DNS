#!/bin/bash
#
# Script: anat_DNS_antBEfailed.sh
# Purpose: Secondary pipeline for processing T1 anatomical images for the DNS study. Use this if anat_DNS.sh failed because ant Brain extraction did not work properly. This script will run freesurfer brain extraction first instead and then use that as input to antCT and rest of processing.
# Author: Maxwell Elliott
#


###########!!!!!!!!!Pipeline to do!!!!!!!!!!!!!#############
#1)make citations #citations
#2)Follow up on #pipeNotes using ctrl f pipeNotes.... Made these when I knew a trick or something I needed to do later

###########!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!###########################

###############################################################################
#
# Environment set up
#
###############################################################################

# --- BEGIN GLOBAL DIRECTIVE -- 
#SBATCH --output=/dscrhome/%u/epi_minProc_DBIS.%j.out 
#SBATCH --error=/dscrhome/%u/epi_minProc_DBIS.%j.out 
# SBATCH --mail-user=%u@duke.edu
# SBATCH --mail-type=END
#SBATCH --mem=24000 # max is 64G on common partition, 64-240G on common-large
# -- END GLOBAL DIRECTIVE -
source ~/.bash_profile

sub=$1
threads=$2
TOPDIR=/cifs/hariri-long
imagingDir=$TOPDIR/Studies/DNS/Imaging
QADir=$imagingDir/derivatives/QA/sub-${sub}
antDir=$imagingDir/derivatives/ANTs/sub-${sub}
freeDir=$imagingDir/derivatives/freesurfer_v5.3/sub-${sub}
tmpDir=${antDir}/tmp
antPre="highRes_" #pipenotes= Change away from HardCoding laterF
templateDir=$TOPDIR/Templates/DNS/WholeBrain #pipenotes= update/Change away from HardCoding later
templatePre=DNS500template_MNI #pipenotes= update/Change away from HardCoding later
anatDir=$imagingDir/sourcedata/sub-${sub}/anat
#flairDir=$TOPDIR/Data/OTAGO/${sub}/DMHDS/MR_3D_SAG_FLAIR_FS-_1.2_mm/
graphicsDir=$TOPDIR/Studies/DNS/Graphics

if [ ${#threads} -eq 0 ]; then threads=1; fi # antsRegistrationSyN won't work properly if $threads is empty
#baseDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$threads
export OMP_NUM_THREADS=$threads
export SUBJECTS_DIR=$imagingDir/derivatives/freesurfer_v5.3
export FREESURFER_HOME=$TOPDIR/Scripts/Tools/FreeSurfer_v5.3/freesurfer
export ANTSPATH=$TOPDIR/Scripts/Tools/ants-2.2.0/bin/
export PATH=$PATH:${scriptDir}/:${scriptDir/DNS/common}/:${scriptDir}/utils/  #DCCnotes: do this all in bash_profile?

echo "----JOB [$SLURM_JOB_ID] SUBJ $sub START [`date`] on HOST [$HOSTNAME]----" 
echo "----CALL: $0 $@----"

##Set up directory
mkdir -p $QADir
mkdir -p $antDir
mkdir -p $tmpDir
cd $antDir

#rm -r ${freeDir}

##Set up directory
mkdir -p $QADir
cd $subDir
mkdir -p $tmpDir

if [[ ! -f ${freeDir}/surf/rh.pial ]];then
	###Prep for Freesurfer with PreSkull Stripped
	#Citation: followed directions from https://surfer.nmr.mgh.harvard.edu/fswiki/UserContributions/FAQ (search skull)
	echo ""
	echo "#########################################################################################################"
	echo "#####################################FreeSurfer Surface Generation#######################################"
	echo "#########################################################################################################"
	echo ""
	#rm -r ${freeDir}
	cd $SUBJECTS_DIR
	${FREESURFER_HOME}/bin/recon-all_noLink -all -s sub-${sub} -openmp $threads -i ${antDir}/${antPre}rWarped.nii.gz
	echo $freeDir
	${FREESURFER_HOME}/bin/recon-all -s sub-$sub -localGI -openmp $threads
else
	echo ""
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!Skipping FreeSurfer, Completed Previously!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo ""
fi
#Run SUMA
if [[ ! -f ${freeDir}/SUMA/std.60.lh.area.niml.dset ]];then
	echo ""
	echo "#########################################################################################################"
	echo "######################################Map Surfaces to SUMA and AFNI######################################"
	echo "#########################################################################################################"
	echo ""
	cd ${freeDir}
	rm -r ${freeDir}/SUMA
	##Add back missing orig files
	#mri_convert ${antDir}/${antPre}ExtractedBrain0N4.nii.gz ${freeDir}/mri/001.mgz
	#mri_convert ${freeDir}/mri/001.mgz ${freeDir}/mri/orig.mgz
	#mkdir ${freeDir}/orig
	@SUMA_Make_Spec_FS_lgi -NIFTI -ld 60 -sid FreeSurfer
	#Convert to GIFTIs for potential use with PALM for TFCE
	#ConvertDset -o_gii -input ${freeDir}/SUMA/std.60.lh.area.niml.dset -prefix ${freeDir}/SUMA/std.60.lh.area
	#ConvertDset -o_gii -input ${freeDir}/SUMA/std.60.rh.area.niml.dset -prefix ${freeDir}/SUMA/std.60.rh.area
	#ConvertDset -o_gii -input ${freeDir}/SUMA/std.60.lh.thickness.niml.dset -prefix ${freeDir}/SUMA/std.60.lh.thickness
	#ConvertDset -o_gii -input ${freeDir}/SUMA/std.60.rh.thickness.niml.dset -prefix ${freeDir}/SUMA/std.60.rh.thickness
else
	echo ""
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!Skipping SUMA_Make_Spec, Completed Previously!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo ""
fi


#cleanup
#mv highRes_* antCT/ #pipeNotes: add more deletion and clean up to minimize space, think about deleting Freesurfer and some of SUMA output
rm -r ${antDir}/tmp ${freeDir}/SUMA/lh.* ${freeDir}/SUMA/rh.* ${freeDir}/SUMA/FreeSurfer_.*spec #${freeDir}/bem ${freeDir}/label ${freeDir}/morph ${freeDir}/mpg ${freeDir}/mri ${freeDir}/rgb ${freeDir}/src ${freeDir}/surf ${freeDir}/tiff ${freeDir}/tmp ${freeDir}/touch ${freeDir}/trash 
rm ${antDir}/${antPre}BrainNormalizedToTemplate.nii.gz ${antDir}/${antPre}TemplateToSubject*
gzip ${freeDir}/SUMA/*.nii 
 
# -- BEGIN POST-USER -- 
echo "----JOB [$JOB_NAME.$JOB_ID] STOP [`date`]----" 
mv $HOME/$JOB_NAME.$JOB_ID.out $antDir/$JOB_NAME.$JOB_ID.out	 
# -- END POST-USER -- 
