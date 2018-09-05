#!/bin/bash
# run with qsub -t 1:N run_firstlevel_AFNI.bash (where N is number of subjects
# gets subject IDS from DNS.01/Analysis/All_Imaging/DNSids.txt

# --- BEGIN GLOBAL DIRECTIVE -- 
#SBATCH --output=/dscrhome/%u/glm_faces.%j.out 
#SBATCH --error=/dscrhome/%u/glm_faces.%j.out 
# SBATCH --mail-user=%u@duke.edu
# SBATCH --mail-type=END
#SBATCH --mem=12000 # max is 64G on common partition, 64-240G on common-large
# -- END GLOBAL DIRECTIVE -- 

SUBJ=$1 # 4 digit DNS ID #
TOPDIR=/cifs/hariri-long
OUTDIR=$TOPDIR/Studies/DNS/Imaging/derivatives/epiMinProc_faces/sub-${SUBJ}
fthr=0.5; dthr=2.5; # FD and DVARS thresholds
runname=glm_AFNI_splitRuns_noShapes
maskfile=$TOPDIR/Templates/DNS/WholeBrain/DNS500template_MNI_BrainExtractionMask_2mm.nii.gz

FACESORDER=`grep "DNS$SUBJ" $TOPDIR/Studies/DNS/Imaging/DataLocations.csv | cut -d, -f12`;
echo "***** Faces order is $FACESORDER *****"

rm -r $OUTDIR/$runname
mkdir -p $OUTDIR/$runname/contrasts

# create FD and DVARS outlier file to use for censoring
for i in `seq 195`; do 
	FD=`head -$i $OUTDIR/FD.1D | tail -1`; 
	if [[ $FD == *"e"* ]]; then FD=0; fi  ### sometimes its so small that it gets spit out in scientific notation which will cause below to fail, so just set to 0
	if [ $i -eq 1 ]; then DVARS=0; else DVARS=`head -$((i-1)) $OUTDIR/DVARS.1D | tail -1`; fi; 
	if [[ $DVARS == *"e"* ]]; then DVARS=0; fi  ### sometimes its so small that it gets spit out in scientific notation which will cause below to fail, so just set to 0
	echo $(( 1 - $(echo "$FD > $fthr || $DVARS > $dthr" | bc -l) )); 
done > $OUTDIR/$runname/outliers.1D; 

head -53 $OUTDIR/$runname/outliers.1D | tail -43 > $OUTDIR/$runname/outliers_block1.1D; 
head -97 $OUTDIR/$runname/outliers.1D | tail -43 > $OUTDIR/$runname/outliers_block2.1D; 
head -141 $OUTDIR/$runname/outliers.1D | tail -43 > $OUTDIR/$runname/outliers_block3.1D; 
head -185 $OUTDIR/$runname/outliers.1D | tail -43 > $OUTDIR/$runname/outliers_block4.1D; 

cd $OUTDIR/$runname

## Faces block 1 > adjacent shapes blocks
outname=glm_output_1
# arguments to stim_times are in seconds!
3dDeconvolve -input $OUTDIR/epiWarped_blur6mm.nii.gz'[10..52]' -xout -mask $maskfile -num_stimts 1 \
  -stim_times 1 '1D: 18' 'SPMG1(50)' -stim_label 1 Faces1 \
  -censor outliers_block1.1D \
  -x1D Decon_1 -x1D_stop
3dREMLfit -input $OUTDIR/epiWarped_blur6mm.nii.gz'[10..52]' -matrix Decon_1.xmat.1D -mask $maskfile \
  -Rbeta ${outname}_betas.nii.gz \
  -noFDR 

## Faces block 2 > adjacent shapes blocks
outname=glm_output_2
# arguments to stim_times are in seconds!
3dDeconvolve -input $OUTDIR/epiWarped_blur6mm.nii.gz'[54..96]' -xout -mask $maskfile -num_stimts 1 \
  -stim_times 1 '1D: 18' 'SPMG1(50)' -stim_label 1 Faces2 \
  -censor outliers_block2.1D \
  -x1D Decon_2 -x1D_stop
3dREMLfit -input $OUTDIR/epiWarped_blur6mm.nii.gz'[54..96]' -matrix Decon_2.xmat.1D -mask $maskfile \
  -Rbeta ${outname}_betas.nii.gz \
  -noFDR 

## Faces block 3 > adjacent shapes blocks
outname=glm_output_3
# arguments to stim_times are in seconds!
3dDeconvolve -input $OUTDIR/epiWarped_blur6mm.nii.gz'[98..140]' -xout -mask $maskfile -num_stimts 1 \
  -stim_times 1 '1D: 18' 'SPMG1(50)' -stim_label 1 Faces3 \
  -censor outliers_block3.1D \
  -x1D Decon_3 -x1D_stop
3dREMLfit -input $OUTDIR/epiWarped_blur6mm.nii.gz'[98..140]' -matrix Decon_3.xmat.1D -mask $maskfile \
  -Rbeta ${outname}_betas.nii.gz \
  -noFDR 

## Faces block 4 > adjacent shapes blocks
outname=glm_output_4
# arguments to stim_times are in seconds!
3dDeconvolve -input $OUTDIR/epiWarped_blur6mm.nii.gz'[142..184]' -xout -mask $maskfile -num_stimts 1 \
  -stim_times 1 '1D: 18' 'SPMG1(50)' -stim_label 1 Faces4 \
  -censor outliers_block4.1D \
  -x1D Decon_4 -x1D_stop
3dREMLfit -input $OUTDIR/epiWarped_blur6mm.nii.gz'[142..184]' -matrix Decon_4.xmat.1D -mask $maskfile \
  -Rbeta ${outname}_betas.nii.gz \
  -noFDR 

# add habituation contrast
3dcalc -prefix habit_1g2g3g4.nii.gz  -a glm_output_1_betas.nii.gz'[2]' -b glm_output_1_betas.nii.gz'[0]' \
	-c glm_output_2_betas.nii.gz'[2]' -d glm_output_2_betas.nii.gz'[0]' \
	-e glm_output_3_betas.nii.gz'[2]' -f glm_output_3_betas.nii.gz'[0]' \
	-g glm_output_4_betas.nii.gz'[2]' -h glm_output_4_betas.nii.gz'[0]' -expr '(0.75*(a+b)+0.25*(c+d)-0.25*(e+f)-0.75*(g+h))'

# now relabel the files according to expression
case $FACESORDER in
	1) fear=1; neut=2; ange=3; surp=4; ;; # FNAS
	2) fear=2; neut=1; ange=4; surp=3; ;; # NFSA
	3) fear=3; neut=4; ange=1; surp=2; ;; # ASFN
	4) fear=4; neut=3; ange=2; surp=1; ;; # SANF
	*)  echo "Invalid faces order $FACESORDER!!! Exiting."
		exit; ;;
esac	
mv glm_output_${fear}_betas.nii.gz fear_betas.nii.gz
mv glm_output_${neut}_betas.nii.gz neutral_betas.nii.gz
mv glm_output_${ange}_betas.nii.gz anger_betas.nii.gz
mv glm_output_${surp}_betas.nii.gz surprise_betas.nii.gz
  
# for each of the *_betas.nii.gz, there are 3 sub-bricks: 0: Run#1Pol#0, 1: Run#1Pol#1, 2: Faces#0
# when we model without a shapes regressor, the "faces" coeficient represents the "faces>shapes" contrast, and the Pol0 coef is the baseline, or "shape" beta
# so, the faces BETA is obtained by adding the Pol0 coef to the faces coef
3dcalc -prefix anger_gr_neutral.nii.gz -a anger_betas.nii.gz'[2]' -b anger_betas.nii.gz'[0]' -c neutral_betas.nii.gz'[2]' -d neutral_betas.nii.gz'[0]' -expr '(a+b-(c+d))' 
3dcalc -prefix fear_gr_neutral.nii.gz -a fear_betas.nii.gz'[2]' -b fear_betas.nii.gz'[0]' -c neutral_betas.nii.gz'[2]' -d neutral_betas.nii.gz'[0]' -expr '(a+b-(c+d))' 
3dcalc -prefix anger+fear_gr_neutral.nii.gz  -a anger_betas.nii.gz'[2]' -b anger_betas.nii.gz'[0]' -c fear_betas.nii.gz'[2]' -d fear_betas.nii.gz'[0]' -e neutral_betas.nii.gz'[2]' -f neutral_betas.nii.gz'[0]' -expr '((a+b+c+d)/2-(e+f))' 
3dcalc -prefix faces_gr_shapes_avg.nii.gz  -a anger_betas.nii.gz'[2]' -b fear_betas.nii.gz'[2]' -c neutral_betas.nii.gz'[2]' -d surprise_betas.nii.gz'[2]' -expr '((a+b+c+d)/4)' 

3dTcat -prefix anger_gr_shapes.nii.gz anger_betas.nii.gz'[2]'
3dTcat -prefix anger_baseline_beta.nii.gz anger_betas.nii.gz'[0]'
3dTcat -prefix fear_gr_shapes.nii.gz fear_betas.nii.gz'[2]'
3dTcat -prefix fear_baseline_beta.nii.gz fear_betas.nii.gz'[0]'
3dTcat -prefix neutral_gr_shapes.nii.gz neutral_betas.nii.gz'[2]'
3dTcat -prefix neutral_baseline_beta.nii.gz neutral_betas.nii.gz'[0]'
3dTcat -prefix surprise_gr_shapes.nii.gz surprise_betas.nii.gz'[2]'
3dTcat -prefix surprise_baseline_beta.nii.gz surprise_betas.nii.gz'[0]'

rm fear_betas.nii.gz
rm neutral_betas.nii.gz
rm anger_betas.nii.gz
rm surprise_betas.nii.gz


# -- BEGIN POST-USER -- 
echo "----JOB [$SLURM_JOB_ID] STOP [`date`]----" 
mv /dscrhome/$USER/glm_faces.$SLURM_JOB_ID.out $OUTDIR/$runname/glm_faces.$SLURM_JOB_ID.out 
# -- END POST-USER -- 
