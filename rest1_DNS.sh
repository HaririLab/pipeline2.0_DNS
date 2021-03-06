#!/bin/bash
#
# Script: rest_DNS.sh
# Purpose: Take a minimally preprocessed Resting State Scan and finish preprocessing so that subject is ready for Group Analyses
# Author: Maxwell Elliott
# # ran using : for id in `awk -F, '{print $1}' $H/Scripts/pipeline2.0_DNS/config/sublist_rest1_DNS.txt | sed s/DNS//g `; do sbatch $H/Scripts/pipeline2.0_DNS/rest1_DNS.sh $id; done
# # had to set fileformat=unix for sublist
################Steps to include#######################
#1)despike
#2)motion Regress 12 params
#3)censor
#4) bandpass
#5) compcorr
#6) 

###Eventually
#surface
#graph Analysis construction

###############################################################################
#
# Environment set up
#
###############################################################################
# --- BEGIN GLOBAL DIRECTIVE -- 
#SBATCH --output=/dscrhome/%u/rest1_DNS.%j.out 
#SBATCH --error=/dscrhome/%u/rest1_DNS.%j.out 
# SBATCH --mail-user=%u@duke.edu
# SBATCH --mail-type=END
#SBATCH --mem=12000 # max is 64G on common partition, 64-240G on common-large
#SBATCH --partition scavenger
# -- END GLOBAL DIRECTIVE -

source ~/.bash_profile

sub=$1 #just number
TOPDIR=/cifs/hariri-long
imagingDir=$TOPDIR/Studies/DNS/Imaging
outDir=$imagingDir/derivatives/epiMinProc_rest/sub-${sub}
antDir=$imagingDir/derivatives/ANTs/sub-${sub}
tmpDir=${outDir}/tmp
minProcEpi1=$outDir/rest1/epiWarped.nii.gz
templateDir=$TOPDIR/Templates/DNS/WholeBrain #pipenotes= update/Change away from HardCoding later
templatePre=DNS500template_MNI_  #pipenotes= update/Change away from HardCoding later
antPre="highRes_" #pipenotes= Change away from HardCoding later
FDthresh=.25 #MLS: .35 in DIBS? #pipenotes= Change away from HardCoding later, also find citations for what you decide likely power 2014, minimun of .5 fd 20DVARS suggested
DVARSthresh=1.55 #pipenotes= Change away from HardCoding later, also find citations for what you decide
mkdir -p ${outDir}
mkdir -p $tmpDir

##Nest minProc within overarching rest directory

if [[ ! -f ${outDir}/rest1/epiWarped.nii.gz ]];then
	echo ""
	echo "!!!!!!!!!!!!!!!!!!!!!!No minimally processed Rest Scan Found!!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!need to run epi_minProc_DNS.sh first before this script!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!EXITING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo ""
	exit
fi

numRest=1
restNum=1

###Extract CompCor Components
voxSize=$(@GetAfniRes ${minProcEpi1})
numTR=$(3dinfo -nv ${minProcEpi1})

3dresample -input ${templateDir}/${templatePre}Brain.nii.gz -dxyz $voxSize -prefix ${tmpDir}/refTemplate4epi.nii.gz
antsApplyTransforms -d 3 -t ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz -t ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat -o ${tmpDir}/BrainSegmentationPosteriors1Warped2Template.nii.gz -r ${tmpDir}/refTemplate4epi.nii.gz -i ${antDir}/${antPre}BrainSegmentationPosteriors1.nii.gz
antsApplyTransforms -d 3 -t ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz -t ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat -o ${tmpDir}/BrainSegmentationPosteriors3Warped2Template.nii.gz -r ${tmpDir}/refTemplate4epi.nii.gz -i ${antDir}/${antPre}BrainSegmentationPosteriors3.nii.gz
3dcalc -a ${tmpDir}/BrainSegmentationPosteriors3Warped2Template.nii.gz -b ${tmpDir}/BrainSegmentationPosteriors1Warped2Template.nii.gz -expr 'step(a-0.95)+step(b-0.95)' -prefix ${tmpDir}/seg.wm.csf.nii.gz
3dmerge -1clust_depth 5 5 -prefix ${tmpDir}/seg.wm.csf.depth.nii.gz ${tmpDir}/seg.wm.csf.nii.gz
3dcalc -a ${tmpDir}/seg.wm.csf.depth.nii.gz -expr 'step(a-1)' -prefix ${tmpDir}/seg.wm.csf.erode.nii.gz ##pipenotes:for DBIS may want to edit this to move further away from WM because of smaller voxels


3dcalc -a ${tmpDir}/seg.wm.csf.erode.nii.gz -b ${outDir}/rest1/epiWarped.nii.gz -expr 'a*b' -prefix ${tmpDir}/rest1.wm.csf.nii.gz
3dpc -pcsave 5 -prefix ${tmpDir}/pcRest1.wm.csf ${tmpDir}/rest1.wm.csf.nii.gz
mv ${tmpDir}/pcRest1.wm.csf_vec.1D ${outDir}/
####Setup Censoring
cenTRdelta=$(echo "($restNum - 1)*${numTR}" | bc)
awk -v thresh=$FDthresh '{if($1 > thresh) print NR}' ${outDir}/rest1/FD.1D | awk '{print ($1 - 1) " " $2}' > ${tmpDir}/raw1FDcensorTRs.1D #find TRs above threshold and subtract 1 from list to 0 index for afni's liking
awk -v thresh=$DVARSthresh '{if($1 > thresh) print NR}' ${outDir}/rest1/DVARS.1D | awk '{print ($1) " " $2}' > ${tmpDir}/raw1DVARScensorTRs.1D #find TRs above threshold and Don't subtract 1 from list because DVARS is based on change from first TR and has one less value, value 1 will therefore be for afni 1 index (TR number 2)
1deval -a ${tmpDir}/raw1FDcensorTRs.1D -expr "a+$cenTRdelta" > ${outDir}/FDcensorTRs1.1D
1deval -a ${tmpDir}/raw1DVARScensorTRs.1D -expr "a+$cenTRdelta" > ${outDir}/DVARScensorTRs1.1D


cat ${outDir}/FDcensorTRs1.1D ${outDir}/DVARScensorTRs1.1D | sort -g | uniq > ${outDir}/censorTRs.1D #combine DVARS and FD TRs above threshold 
cat ${outDir}/rest1/motion.1D > ${outDir}/allmotion.1D
cat ${outDir}/rest1/motion_deriv.1D > ${outDir}/allmotion_deriv.1D
cat ${outDir}/pcRest1.wm.csf_vec.1D > ${outDir}/allCompCorr.1D

####Project everything out
clist=$(cat ${outDir}/censorTRs.1D)
lenC=$(echo $clist | wc -w )
##pipeNotes: consider Changing GM mask to one based on all subjects eventually, the all Caucasian with 570 subs should be fine
if [[ $lenC == 0 ]];then
	3dTproject -input ${outDir}/rest1/epiWarped.nii.gz -mask ${templateDir}/${templatePre}BrainExtractionMask_2mmDil1.nii.gz  -prefix ${outDir}/epiPrepped_blur6mm.nii.gz -ort ${outDir}/allmotion.1D -ort ${outDir}/allmotion_deriv.1D -ort ${outDir}/allCompCorr.1D -polort 1 -bandpass 0.008 0.10 -blur 6
##comments: Decided again a more restricted blur in mask with different compartments for cerebellum etc, because that approach seemed to be slighly harming tSNR actually and did not help with peak voxel or extent analyses when applied to Faces contrast. Decided to use a dilated Brain Extraction mask because this at least gets rid of crap that is way outside of brain. This saves space (slightly) and aids with cleaner visualizations. A GM mask can still later be applied for group analyses, this way we at least leave that up to the user.
else
	3dTproject -input ${outDir}/rest1/epiWarped.nii.gz -mask ${templateDir}/${templatePre}BrainExtractionMask_2mmDil1.nii.gz -prefix ${outDir}/epiPrepped_blur6mm.nii.gz -CENSORTR $clist -ort ${outDir}/allmotion.1D -ort ${outDir}/allmotion_deriv.1D -ort ${outDir}/allCompCorr.1D -polort 1 -bandpass 0.008 0.10 -blur 6
##comments: Decided against a more restricted blur in mask with different compartments for cerebellum etc, because that approach seemed to be slighly harming tSNR actually and did not help with peak voxel or extent analyses when applied to Faces contrast. Decided to use a dilated Brain Extraction mask because this at least gets rid of crap that is way outside of brain. This saves space (slightly) and aids with cleaner visualizations. A GM mask can still later be applied for group analyses, this way we at least leave that up to the user.
fi

rm -r $tmpDir
# -- BEGIN POST-USER -- 
echo "----JOB [$SLURM_JOB_ID] STOP [`date`]----" 
mv /dscrhome/$USER/rest1_DNS.$SLURM_JOB_ID.out $outDir/rest1_DNS.$SLURM_JOB_ID.out 
# -- END POST-USER -- 

#pipenotes: Cen options in 3dTproject start at 0, currently ours based on awk start with 1. Make sure to subtract 1 before giving to tproject!!!!

