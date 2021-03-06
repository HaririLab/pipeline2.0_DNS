#!/bin/bash
# run with qsub -t 1:N run_firstlevel_AFNI.bash (where N is number of subjects
# gets subject IDS from DNS.01/Analysis/All_Imaging/DNSids.txt

# --- BEGIN GLOBAL DIRECTIVE -- 
#SBATCH --output=/dscrhome/%u/glm_numLS.%j.out 
#SBATCH --error=/dscrhome/%u/glm_numLS.%j.out 
# SBATCH --mail-user=%u@duke.edu
# SBATCH --mail-type=END
#SBATCH --mem=12000 # max is 64G on common partition, 64-240G on common-large
# -- END GLOBAL DIRECTIVE -- 



SUBJ=$1 # 4 digit
TOPDIR=/cifs/hariri-long
OUTDIR=$TOPDIR/Studies/DNS/Imaging/derivatives/epiMinProc_numLS/sub-${SUBJ}
fthr=0.5; dthr=2.5; # FD and DVARS thresholds
runname=glm_AFNI
maskfile=$TOPDIR/Templates/DNS/WholeBrain/DNS500template_MNI_BrainExtractionMask_2mm.nii.gz
outname=glm_output

mkdir -p $OUTDIR/$runname/contrasts

# create FD and DVARS outlier file to use for censoring
for i in `seq 354`; do 
	FD=`head -$i $OUTDIR/FD.1D | tail -1`; 
	if [[ $FD == *"e"* ]]; then FD=0; fi  ### sometimes its so small that it gets spit out in scientific notation which will cause below to fail, so just set to 0
	if [ $i -eq 1 ]; then DVARS=0; else DVARS=`head -$((i-1)) $OUTDIR/DVARS.1D | tail -1`; fi; 
	if [[ $DVARS == *"e"* ]]; then DVARS=0; fi  ### sometimes its so small that it gets spit out in scientific notation which will cause below to fail, so just set to 0
	echo $(( 1 - $(echo "$FD > $fthr || $DVARS > $dthr" | bc -l) )); 
done > $OUTDIR/$runname/outliers.1D; 

###### Read behavioral data ######
mkdir $OUTDIR/onsets
SUBJ_NUM=$(grep DNS$SUBJ $TOPDIR/Studies/DNS/Imaging/DataLocations.csv | cut -d, -f10 | cut -d/ -f3 | cut -d_ -f2)
if [ -e $TOPDIR/Studies/DNS/Imaging/ResponseData/NumLS/eprime_txt/NumLS-$SUBJ_NUM-1.txt ]; then
	perl $TOPDIR/Scripts/pipeline2.0_DNS/Behavioral/getNumLSEprime_AFNI.pl $TOPDIR/Studies/DNS/Imaging/ResponseData/NumLS/eprime_txt/NumLS-$SUBJ_NUM-1.txt $OUTDIR/onsets
else
	echo "***Can't locate NumLS eprime txt file $TOPDIR/Studies/DNS/Imaging/ResponseData/NumLS/eprime_txt/NumLS-$SUBJ_NUM-1.txt for subject $SUBJ. NumLS glm will not be run!***";
	exit 32;
fi

# incorrect_ct=`less ../onsets/Incorrect_onsets.txt | wc -l`; ### actually this won't work bc even if there are numbers in this file, wc will register as 0 (there is no new line!)
any_incorrect=`grep "." $OUTDIR/onsets/Incorrect_onsets.txt | grep "0" | wc -l`; ### this should work, will be 1 if the file is non-empty and 0 otherwise

# create contrast files
######### don't forget to change # of leading 0s if you change polort!!!
if [ $any_incorrect -gt 0 ]; then 
	echo "0 0 0 0 0 0 -1 1 0 0 0 0 0 0 0 0" > $OUTDIR/$runname/contrasts/judg_gr_motor.txt
	echo "0 0 0 0 0 0 -1 0 0 0 0 0 1 0 0 0" > $OUTDIR/$runname/contrasts/compJudg_gr_judg.txt
	echo "0 0 0 0 0 0 -1 0 0 0 0 0 1 0 0 0" > $OUTDIR/$runname/contrasts/recallJudg_gr_motor.txt
	echo "0 0 0 0 0 0 0 -1 0 0 0 0 0 1 0 0" > $OUTDIR/$runname/contrasts/recallCompJudg_gr_judg.txt
	echo "0 0 0 0 0 0 0 0 0 0 0 0 -1 1 0 0" > $OUTDIR/$runname/contrasts/recallCompJudg_gr_recallJudg.txt
	echo "0 0 0 0 0 0 0 0 -1 0 0 0 0 1 0 0" > $OUTDIR/$runname/contrasts/recallCompJudg_gr_compJudg.txt
	echo "0 0 0 0 0 0 0 0 0 0 0 0 0 1 -1 0" > $OUTDIR/$runname/contrasts/recallCompJudg_gr_recallJudgPostComp.txt
else
	echo "0 0 0 0 0 0 -1 1 0 0 0 0 0 0 0" > $OUTDIR/$runname/contrasts/judg_gr_motor.txt
	echo "0 0 0 0 0 0 -1 0 0 0 0 0 1 0 0" > $OUTDIR/$runname/contrasts/compJudg_gr_judg.txt
	echo "0 0 0 0 0 0 -1 0 0 0 0 0 1 0 0" > $OUTDIR/$runname/contrasts/recallJudg_gr_motor.txt
	echo "0 0 0 0 0 0 0 -1 0 0 0 0 0 1 0" > $OUTDIR/$runname/contrasts/recallCompJudg_gr_judg.txt
	echo "0 0 0 0 0 0 0 0 0 0 0 0 -1 1 0" > $OUTDIR/$runname/contrasts/recallCompJudg_gr_recallJudg.txt
	echo "0 0 0 0 0 0 0 0 -1 0 0 0 0 1 0" > $OUTDIR/$runname/contrasts/recallCompJudg_gr_compJudg.txt
	echo "0 0 0 0 0 0 0 0 0 0 0 0 0 1 -1" > $OUTDIR/$runname/contrasts/recallCompJudg_gr_recallJudgPostComp.txt
fi

cd $OUTDIR/$runname
# arguments to stim_times are in seconds!
# glt arg should always be 1
# using polort 5 here per recommendation in afni_proc.py help documentation
# 2/5/18: changed -Rbuck to .nii from .nii.gz bc this seems to solve a sort of compatibility issue for extracting values in SPM later on!
if [ $any_incorrect -gt 0 ]; then 
	echo "3dDeconvolve -input $OUTDIR/epiWarped_blur6mm.nii.gz -xout -polort 5 -mask $maskfile -num_stimts 10 \\" >> run_3ddeconvolve.sh
else
	echo "3dDeconvolve -input $OUTDIR/epiWarped_blur6mm.nii.gz -xout -polort 5 -mask $maskfile -num_stimts 9 \\" >> run_3ddeconvolve.sh
fi
echo "-stim_times 1 $OUTDIR/onsets/M_onsets.txt 'SPMG1(3)' -stim_label 1 Motor \\" >> run_3ddeconvolve.sh
echo "-stim_times 2 $OUTDIR/onsets/J_onsets.txt 'SPMG1(3)' -stim_label 2 Size_judgment_only \\" >> run_3ddeconvolve.sh
echo "-stim_times 3 $OUTDIR/onsets/CJ_onsets.txt 'SPMG1(3)' -stim_label 3 Computation_and_judgment \\" >> run_3ddeconvolve.sh
echo "-stim_times 4 $OUTDIR/onsets/E_onsets.txt 'SPMG1(0.5)' -stim_label 4 Encoding_no_comp \\" >> run_3ddeconvolve.sh
echo "-stim_times 5 $OUTDIR/onsets/EC_onsets.txt 'SPMG1(0.5)' -stim_label 5 Encoding_with_comp \\" >> run_3ddeconvolve.sh
echo "-stim_times 6 $OUTDIR/onsets/Maintenance_onsets.txt 'SPMG1(4)' -stim_label 6 Maintenance \\" >> run_3ddeconvolve.sh
echo "-stim_times 7 $OUTDIR/onsets/E_RJ_onsets.txt 'SPMG1(3)' -stim_label 7 Recall_and_judgment \\" >> run_3ddeconvolve.sh
echo "-stim_times 8 $OUTDIR/onsets/E_RCJ_onsets.txt 'SPMG1(3)' -stim_label 8 Recall_comp_and_judg \\" >> run_3ddeconvolve.sh
echo "-stim_times 9 $OUTDIR/onsets/EC_RJ_onsets.txt 'SPMG1(3)' -stim_label 9 Recall_and_judg_after_comp \\" >> run_3ddeconvolve.sh
if [ $any_incorrect -gt 0 ]; then echo "-stim_times 10 $OUTDIR/onsets/Incorrect_onsets.txt 'SPMG1(3)' -stim_label 10 Incorrect_trials \\" >> run_3ddeconvolve.sh; fi # incorrect trials
echo "-censor outliers.1D \\" >> run_3ddeconvolve.sh
echo "-full_first -fout -tout -errts ${outname}_errts.nii.gz \\" >> run_3ddeconvolve.sh
echo "-glt 1 $OUTDIR/$runname/contrasts/judg_gr_motor.txt -glt_label 1 judg_gr_motor \\" >> run_3ddeconvolve.sh
echo "-glt 1 $OUTDIR/$runname/contrasts/compJudg_gr_judg.txt -glt_label 2 compJudg_gr_judg \\" >> run_3ddeconvolve.sh
echo "-glt 1 $OUTDIR/$runname/contrasts/recallJudg_gr_motor.txt -glt_label 3 recallJudg_gr_motor \\" >> run_3ddeconvolve.sh
echo "-glt 1 $OUTDIR/$runname/contrasts/recallCompJudg_gr_judg.txt -glt_label 4 recallCompJudg_gr_judg \\" >> run_3ddeconvolve.sh
echo "-glt 1 $OUTDIR/$runname/contrasts/recallCompJudg_gr_recallJudg.txt -glt_label 5 recallCompJudg_gr_recallJudg \\" >> run_3ddeconvolve.sh
echo "-glt 1 $OUTDIR/$runname/contrasts/recallCompJudg_gr_compJudg.txt -glt_label 6 recallCompJudg_gr_compJudg \\" >> run_3ddeconvolve.sh
echo "-glt 1 $OUTDIR/$runname/contrasts/recallCompJudg_gr_recallJudgPostComp.txt -glt_label 7 recallCompJudg_gr_recallJudgPostComp \\" >> run_3ddeconvolve.sh
echo "-x1D_stop" >> run_3ddeconvolve.sh
echo "" >> run_3ddeconvolve.sh
echo "3dREMLfit -input $OUTDIR/epiWarped_blur6mm.nii.gz -matrix Decon.xmat.1D -mask $maskfile \\" >> run_3ddeconvolve.sh
echo "-Rbuck ${outname}.nii \\" >> run_3ddeconvolve.sh
echo "-noFDR -tout -Rerrts ${outname}_Rerrts.nii.gz" >> run_3ddeconvolve.sh
 
sh run_3ddeconvolve.sh

# extract coefs and tstats for workign with in SPM  
# first volume in output bucket (index 0!) is Full_Fstat, then there are 2 volumes for each condition (Coef, Tstat)
# so, the first contrast volume # is 2*(N conditions) + 1
if [ $any_incorrect -gt 0 ]; then
	3dTcat -prefix ${outname}_coefs.nii ${outname}.nii'[21]' ${outname}.nii'[23]' ${outname}.nii'[25]' ${outname}.nii'[27]' ${outname}.nii'[29]' ${outname}.nii'[31]' ${outname}.nii'[33]'
	3dTcat -prefix ${outname}_tstats.nii.gz ${outname}.nii.gz'[22]' ${outname}.nii.gz'[24]' ${outname}.nii.gz'[26]' ${outname}.nii.gz'[28]' ${outname}.nii.gz'[30]' ${outname}.nii.gz'[32]' ${outname}.nii.gz'[34]'
else
	3dTcat -prefix ${outname}_coefs.nii ${outname}.nii'[19]' ${outname}.nii'[21]' ${outname}.nii'[23]' ${outname}.nii'[25]' ${outname}.nii'[27]' ${outname}.nii'[29]' ${outname}.nii'[31]'
	3dTcat -prefix ${outname}_tstats.nii.gz ${outname}.nii.gz'[20]' ${outname}.nii.gz'[22]' ${outname}.nii.gz'[24]' ${outname}.nii.gz'[26]' ${outname}.nii.gz'[28]' ${outname}.nii.gz'[30]' ${outname}.nii.gz'[32]'
fi

# calculate variance of residual time series, I think this is analogous to SPM's ResMS image, in case we want this at some point
3dTstat -stdev -prefix ${outname}_Rerrts_sd.nii.gz ${outname}_Rerrts.nii.gz 
fslmaths ${outname}_Rerrts_sd.nii.gz -sqr ${outname}_Rerrts_var.nii.gz
rm ${outname}_Rerrts.nii.gz
rm ${outname}_Rerrts_sd.nii.gz
rm ${outname}.nii  ### this file contains coef, fstat, and tstat for each condition and contrast, so since we are saving coefs and tstats separately for SPM, i think the only thing we lose here is fstat, which we probably dont want anyway


# -- BEGIN POST-USER -- 
echo "----JOB [$SLURM_JOB_ID] STOP [`date`]----" 
mv /dscrhome/$USER/glm_numLS.$SLURM_JOB_ID.out $OUTDIR/$runname/glm_numLS.$SLURM_JOB_ID.out 
# -- END POST-USER -- 