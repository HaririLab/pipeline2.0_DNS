#!/bin/bash

# --- BEGIN GLOBAL DIRECTIVE -- 
#$ -o $HOME/$JOB_NAME.$JOB_ID.out
#$ -e $HOME/$JOB_NAME.$JOB_ID.out
# -- END GLOBAL DIRECTIVE -- 

##################################getSeedFuncConZ.bash##############################
####################### Authored by Max Elliott 3/11/2016 ####################
## Example run: qsub getSeedFuncConZ.bash $sub/rest/epiPrepped.nii.gz $DNS/Analysis/SPM/ROI/NEW_PIPEINE/VS/left_VS_10mm.nii 1 $sub/rest/seedFC VS_L_10mm
## ARK added output nii instead of nii.gz 1/5/18

####Description####
#made to speed up the extraction of Z scores from ROIs for purposes of seed diffs and cwas followups. Slow if not run on biowulf

data=$1
seedMask=$2
maskSelector=$3	# will use only voxels with this value in mask image (i.e. 1 for a binary mask)
outWD=$4
prefix=$5

echo "----JOB [$JOB_NAME.$JOB_ID] SUBJ $SUBJ START [`date`] on HOST [$HOSTNAME]----"
echo "Call: $0 $@"

3dmaskave -quiet -mrange $maskSelector $maskSelector -mask $seedMask $data > $outWD/tmp.$prefix.maskData.1D
3dDeconvolve -quiet -input $data -polort -1 -num_stimts 1 \
	-stim_file 1 $outWD/tmp.$prefix.maskData.1D -stim_label 1 maskData \
	-tout -rout -bucket $outWD/tmp.$prefix.maskData.decon.nii
	
3dcalc -a $outWD/tmp.$prefix.maskData.decon.nii'[4]' -b $outWD/tmp.$prefix.maskData.decon.nii'[2]' -expr 'ispositive(b)*sqrt(a)-isnegative(b)*sqrt(a)' -prefix $outWD/tmp.$prefix.maskData.R.nii
3dcalc -a $outWD/tmp.$prefix.maskData.R.nii -expr 'log((1+a)/(1-a))/2' -prefix $outWD/$prefix.Z.nii
rm $outWD/tmp*


# -- BEGIN POST-USER -- 
echo "----JOB [$JOB_NAME.$JOB_ID] STOP [`date`]----" 
mv $HOME/$JOB_NAME.$JOB_ID.out $outWD/$JOB_NAME.$prefix.out	 
# -- END POST-USER -- 