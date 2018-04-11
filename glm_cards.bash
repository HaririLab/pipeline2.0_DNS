#!/bin/bash
# run with qsub -t 1:N run_firstlevel_AFNI.bash (where N is number of subjects
# gets subject IDS from DNS.01/Analysis/All_Imaging/DNSids.txt

# --- BEGIN GLOBAL DIRECTIVE -- 
#$ -o $HOME/$JOB_NAME.$JOB_ID.out
#$ -e $HOME/$JOB_NAME.$JOB_ID.out
# -- END GLOBAL DIRECTIVE -- 

SUBJ=$1 
BASEDIR=$(findexp DNS.01)
OUTDIR=$BASEDIR/Analysis/All_Imaging/$SUBJ/cards/
TMPOUTDIR=$TMPDIR
fthr=0.5; dthr=2.5; # FD and DVARS thresholds
runname=glm_AFNI

mkdir -p $TMPOUTDIR/contrasts
# create contrast files
######### don't forget to change # of leading 0s if you change polort!!!
echo "0 0 0 0 0 1 -1" > $TMPOUTDIR/contrasts/PF_gr_NF.txt
echo "0 0 0 0 -1 1 0" > $TMPOUTDIR/contrasts/PF_gr_Ctrl.txt
echo "0 0 0 0 -1 0 1" > $TMPOUTDIR/contrasts/NF_gr_Ctrl.txt

mkdir -p $TMPOUTDIR/stimfiles
cd $TMPOUTDIR/stimfiles
	
if [ -e $OUTDIR/CARDS_TIMINGS.txt ]; then # this was an early subject before task was fixed so that each trial had a constant length
	# read individual timings into array "timings"
	# CARDS_TIMINGS has 19 lines with one value per line in the following order: nTRs, PF onsets (in TRs, 3 lines), PF durations (3 lines), NF ... , Ctrl ...
	readarray timings < $OUTDIR/CARDS_TIMINGS.txt
	for i in `seq 0 19`; do tmp=`echo ${timings[$i]} | sed 's/*^[0-9]//g'`; timings[$i]=$tmp; done # get rid of white space
	nTRs=${timings[0]}
	
	echo "***************3dDeconvolve -nodata $nTRs 1.0 -num_stimts 1 -stim_times 1 '1D: '${timings[15]} 'SPMG1('${timings[18]}')' -x1D tmp.x1D**************"
	# create individual timing regressors
	# grepping for all non-commented lines (-v "#") will yield one blank line at the end, so do head $nTRs to get rid of that
	3dDeconvolve -nodata $nTRs 2.0 -num_stimts 1 -stim_times 1 '1D: '$((timings[1]*2)) 'SPMG1('$((timings[4]*2))')' -x1D tmp.x1D
	grep -v "#" tmp.x1D | head -$nTRs | awk '{print $3}' > PF1.txt; rm tmp.x1D
	3dDeconvolve -nodata $nTRs 2.0 -num_stimts 1 -stim_times 1 '1D: '$((timings[2]*2)) 'SPMG1('$((timings[5]*2))')' -x1D tmp.x1D
	grep -v "#" tmp.x1D | head -$nTRs |  awk '{print $3}' > PF2.txt; rm tmp.x1D
	3dDeconvolve -nodata $nTRs 2.0 -num_stimts 1 -stim_times 1 '1D: '$((timings[3]*2)) 'SPMG1('$((timings[6]*2))')' -x1D tmp.x1D
	grep -v "#" tmp.x1D | head -$nTRs |  awk '{print $3}' > PF3.txt; rm tmp.x1D
	paste PF1.txt PF2.txt PF3.txt | awk '{print ($1+$2+$3)}' > PF.txt
	3dDeconvolve -nodata $nTRs 2.0 -num_stimts 1 -stim_times 1 '1D: '$((timings[7]*2)) 'SPMG1('$((timings[10]*2))')' -x1D tmp.x1D
	grep -v "#" tmp.x1D | head -$nTRs |  awk '{print $3}' > NF1.txt; rm tmp.x1D
	3dDeconvolve -nodata $nTRs 2.0 -num_stimts 1 -stim_times 1 '1D: '$((timings[8]*2)) 'SPMG1('$((timings[11]*2))')' -x1D tmp.x1D
	grep -v "#" tmp.x1D | head -$nTRs |  awk '{print $3}' > NF2.txt; rm tmp.x1D
	3dDeconvolve -nodata $nTRs 2.0 -num_stimts 1 -stim_times 1 '1D: '$((timings[9]*2)) 'SPMG1('$((timings[12]*2))')' -x1D tmp.x1D
	grep -v "#" tmp.x1D | head -$nTRs |  awk '{print $3}' > NF3.txt; rm tmp.x1D
	paste NF1.txt NF2.txt NF3.txt | awk '{print ($1+$2+$3)}' > NF.txt
	3dDeconvolve -nodata $nTRs 2.0 -num_stimts 1 -stim_times 1 '1D: '$((timings[13]*2)) 'SPMG1('$((timings[16]*2))')' -x1D tmp.x1D
	grep -v "#" tmp.x1D | head -$nTRs |  awk '{print $3}' > Ctrl1.txt; rm tmp.x1D                     
	3dDeconvolve -nodata $nTRs 2.0 -num_stimts 1 -stim_times 1 '1D: '$((timings[14]*2)) 'SPMG1('$((timings[17]*2))')' -x1D tmp.x1D
	grep -v "#" tmp.x1D | head -$nTRs |  awk '{print $3}' > Ctrl2.txt; rm tmp.x1D                     
	3dDeconvolve -nodata $nTRs 2.0 -num_stimts 1 -stim_times 1 '1D: '$((timings[15]*2)) 'SPMG1('$((timings[18]*2))')' -x1D tmp.x1D
	grep -v "#" tmp.x1D | head -$nTRs |  awk '{print $3}' > Ctrl3.txt; rm tmp.x1D
	paste Ctrl1.txt Ctrl2.txt Ctrl3.txt | awk '{print ($1+$2+$3)}' > Ctrl.txt

else
	nTRs=171
	3dDeconvolve -nodata $nTRs 2.0 -num_stimts 1 -stim_times 1 '1D: 76 190 304' 'SPMG1(38)' -x1D tmp.x1D
	grep -v "#" tmp.x1D | head -$nTRs |  awk '{print $3}' > Ctrl.txt; rm tmp.x1D
	3dDeconvolve -nodata $nTRs 2.0 -num_stimts 1 -stim_times 1 '1D: 0 114 228' 'SPMG1(38)' -x1D tmp.x1D
	grep -v "#" tmp.x1D | head -$nTRs |  awk '{print $3}' > PF.txt; rm tmp.x1D
	3dDeconvolve -nodata $nTRs 2.0 -num_stimts 1 -stim_times 1 '1D: 38 152 266' 'SPMG1(38)' -x1D tmp.x1D
	grep -v "#" tmp.x1D | head -$nTRs |  awk '{print $3}' > NF.txt; rm tmp.x1D
fi

# create FD and DVARS outlier file to use for censoring
for i in `seq $nTRs`; do 
	FD=`head -$i $OUTDIR/FD.1D | tail -1`; 
	if [[ $FD == *"e"* ]]; then FD=0; fi  ### sometimes its so small that it gets spit out in scientific notation which will cause below to fail, so just set to 0
	if [ $i -eq 1 ]; then DVARS=0; else DVARS=`head -$((i-1)) $OUTDIR/DVARS.1D | tail -1`; fi; 
	if [[ $DVARS == *"e"* ]]; then DVARS=0; fi  ### sometimes its so small that it gets spit out in scientific notation which will cause below to fail, so just set to 0
	echo $(( 1 - $(echo "$FD > $fthr || $DVARS > $dthr" | bc -l) )); 
done > $TMPOUTDIR/outliers.1D; 

cd $TMPOUTDIR
maskfile=$BASEDIR/Analysis/Max/templates/DNS500/DNS500template_MNI_BrainExtractionMask_2mm.nii.gz
outname=glm_output
lastTRindex=$((nTRs-1))
# arguments to stim_times are in seconds!
# glt arg should always be 1
# using polort 3 here per recommendation in afni_proc.py help documentation
3dDeconvolve -input $OUTDIR/epiWarped_blur6mm.nii.gz'[0..'${lastTRindex}']' -xout -polort 3 -mask $maskfile -num_stimts 3 \
-stim_file 1 stimfiles/Ctrl.txt -stim_label 1 Control \
-stim_file 2 stimfiles/PF.txt -stim_label 2 Positive_feedback \
-stim_file 3 stimfiles/NF.txt -stim_label 3 Negative_feedback \
-censor outliers.1D \
-glt 1 contrasts/PF_gr_NF.txt -glt_label 1 PF_gr_NF \
-glt 1 contrasts/PF_gr_Ctrl.txt -glt_label 2 PF_gr_Ctrl \
-glt 1 contrasts/NF_gr_Ctrl.txt -glt_label 3 NF_gr_Ctrl \
-x1D_stop

# 2/5/18: changed -Rbuck to .nii from .nii.gz bc this seems to solve a sort of compatibility issue for extracting values in SPM later on!
3dREMLfit -input $OUTDIR/epiWarped_blur6mm.nii.gz'[0..'${lastTRindex}']' -matrix Decon.xmat.1D -mask $maskfile \
  -Rbuck ${outname}.nii \
  -noFDR -tout -Rerrts ${outname}_Rerrts.nii.gz
  
# extract coefs and tstats for workign with in SPM  
# first volume in output bucket (index 0!) is Full_Fstat, then there are 2 volumes for each condition (Coef, Tstat)
# so, the first contrast volume # is 2*(N conditions) + 1
3dTcat -prefix ${outname}_coefs.nii ${outname}.nii'[7]' ${outname}.nii'[9]' ${outname}.nii'[11]' 
3dTcat -prefix ${outname}_tstats.nii.gz ${outname}.nii.gz'[8]' ${outname}.nii.gz'[10]' ${outname}.nii.gz'[12]' 

# calculate variance of residual time series, I think this is analogous to SPM's ResMS image, in case we want this at some point
3dTstat -stdev -prefix ${outname}_Rerrts_sd.nii.gz ${outname}_Rerrts.nii.gz 
fslmaths ${outname}_Rerrts_sd.nii.gz -sqr ${outname}_Rerrts_var.nii.gz
rm ${outname}_Rerrts.nii.gz
rm ${outname}_Rerrts_sd.nii.gz
rm ${outname}.nii

rm $TMPOUTDIR/stimfiles/*[123].txt
rm $TMPOUTDIR/stimfiles/3dDeconvolve.err
rm $TMPOUTDIR/stimfiles/tmp.x1D_XtXinv.xmat.1D

mkdir -p $OUTDIR/$runname/
cp -r $TMPOUTDIR/* $OUTDIR/$runname/

# -- BEGIN POST-USER -- 
echo "----JOB [$JOB_NAME.$JOB_ID] STOP [`date`]----" 
mv $HOME/$JOB_NAME.$JOB_ID.out $OUTDIR/$runname/$JOB_NAME.$JOB_ID.out	 
# -- END POST-USER -- 
