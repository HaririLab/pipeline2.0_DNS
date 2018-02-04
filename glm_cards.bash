#!/bin/bash
# run with qsub -t 1:N run_firstlevel_AFNI.bash (where N is number of subjects
# gets subject IDS from DNS.01/Analysis/All_Imaging/DNSids.txt

index=${SGE_TASK_ID}
BASEDIR=$HOME/experiments/DNS.01/
OUTDIR=$BASEDIR/Analysis/All_Imaging/
fthr=0.5; dthr=2.5; # FD and DVARS thresholds
runname=glm_AFNI

# SUBJ=`head -$index $OUTDIR/DNSids_NHC527.txt | tail -1`
SUBJ=$1 #`head -$index $OUTDIR/cards.txt | tail -1`

mkdir -p $OUTDIR/$SUBJ/cards/$runname/contrasts

# create FD and DVARS outlier file to use for censoring
for i in `seq 171`; do 
	FD=`head -$i $OUTDIR/$SUBJ/cards/FD.1D | tail -1`; 
	if [[ $FD == *"e"* ]]; then FD=0; fi  ### sometimes its so small that it gets spit out in scientific notation which will cause below to fail, so just set to 0
	if [ $i -eq 1 ]; then DVARS=0; else DVARS=`head -$((i-1)) $OUTDIR/$SUBJ/cards/DVARS.1D | tail -1`; fi; 
	if [[ $DVARS == *"e"* ]]; then DVARS=0; fi  ### sometimes its so small that it gets spit out in scientific notation which will cause below to fail, so just set to 0
	echo $(( 1 - $(echo "$FD > $fthr || $DVARS > $dthr" | bc -l) )); 
done > $OUTDIR/$SUBJ/cards/$runname/outliers.1D; 

# create contrast files
######### don't forget to change # of leading 0s if you change polort!!!
echo "0 0 0 0 0 1 -1" > $OUTDIR/$SUBJ/cards/$runname/contrasts/PF_gr_NF.txt
echo "0 0 0 0 -1 1 0" > $OUTDIR/$SUBJ/cards/$runname/contrasts/PF_gr_Ctrl.txt
echo "0 0 0 0 -1 0 1" > $OUTDIR/$SUBJ/cards/$runname/contrasts/NF_gr_Ctrl.txt

cd $OUTDIR/$SUBJ/cards/$runname
maskfile=$BASEDIR/Analysis/Max/templates/DNS500/DNS500template_MNI_BrainExtractionMask_2mm.nii.gz
outname=glm_output
# arguments to stim_times are in seconds!
# glt arg should always be 1
# using polort 3 here per recommendation in afni_proc.py help documentation
3dDeconvolve -input $OUTDIR/$SUBJ/cards/epiWarped_blur6mm.nii.gz -xout -polort 3 -mask $maskfile -num_stimts 3 \
-stim_times 1 '1D: 76 190 304' 'SPMG1(38)' -stim_label 1 Control \
-stim_times 2 '1D: 0 114 228' 'SPMG1(38)' -stim_label 2 Positive_feedback \
-stim_times 3 '1D: 38 152 266' 'SPMG1(38)' -stim_label 3 Negative_feedback \
-censor outliers.1D \
-glt 1 contrasts/PF_gr_NF.txt -glt_label 1 PF_gr_NF \
-glt 1 contrasts/PF_gr_Ctrl.txt -glt_label 2 PF_gr_Ctrl \
-glt 1 contrasts/NF_gr_Ctrl.txt -glt_label 3 NF_gr_Ctrl \
-x1D_stop

3dREMLfit -input $OUTDIR/$SUBJ/cards/epiWarped_blur6mm.nii.gz -matrix Decon.xmat.1D -mask $maskfile \
  -Rbuck ${outname}.nii.gz \
  -noFDR -tout -Rerrts ${outname}_Rerrts.nii.gz
  
# extract coefs and tstats for workign with in SPM  
# first volume in output bucket (index 0!) is Full_Fstat, then there are 2 volumes for each condition (Coef, Tstat)
# so, the first contrast volume # is 2*(N conditions) + 1
3dTcat -prefix ${outname}_coefs.nii ${outname}.nii.gz'[7]' ${outname}.nii.gz'[9]' ${outname}.nii.gz'[11]' 
3dTcat -prefix ${outname}_tstats.nii.gz ${outname}.nii.gz'[8]' ${outname}.nii.gz'[10]' ${outname}.nii.gz'[12]' 

# calculate variance of residual time series, I think this is analogous to SPM's ResMS image, in case we want this at some point
3dTstat -stdev -prefix ${outname}_Rerrts_sd.nii.gz ${outname}_Rerrts.nii.gz 
fslmaths ${outname}_Rerrts_sd.nii.gz -sqr ${outname}_Rerrts_var.nii.gz
rm ${outname}_Rerrts.nii.gz
rm ${outname}_Rerrts_sd.nii.gz
rm ${outname}.nii.gz  