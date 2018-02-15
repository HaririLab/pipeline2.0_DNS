# Following instructions here: https://afni.nimh.nih.gov/CD-CorrAna


# --- BEGIN GLOBAL DIRECTIVE -- 
#$ -o $HOME/$JOB_NAME.$JOB_ID.out
#$ -e $HOME/$JOB_NAME.$JOB_ID.out
# -- END GLOBAL DIRECTIVE -- 

################################# need to update this for individual timings subjects ##########################
BASEDIR=$(findexp DNS.01)
ID=$1
ROI=$BASEDIR/Analysis/SPM/ROI/NEW_PIPELINE/VS/left_VS_10mm.nii # $2
OUTNAME=LVS_10mm_scaled #$3
PROCDIR=$BASEDIR/Analysis/All_Imaging/$ID/cards/
OUTDIR=$BASEDIR/Analysis/All_Imaging/$ID/cards/gPPI/$OUTNAME
nTRs=171

echo "----JOB [$JOB_NAME.$JOB_ID] SUBJ $ID START [`date`] on HOST [$HOSTNAME]----"

mkdir -p $OUTDIR/contrasts

# extract the average time series of the ROI
## andy (2013) uses 3dSynthesize to remove drift & motion effects and extract the seed ts from teh resulting cleaned data (doesn't use the cleaned data after that)
## > however the afni instructions don't mention this and just suggest using the preprocessed ts from afni_proc, then uses 3dDetrend (which Andy skips)
3dmaskave -mask $ROI -quiet $PROCDIR/epiWarped_blur6mm.nii.gz > $OUTDIR/Seed.1D
# Use \' to transpose Seed.1D

# detrend seed time series and transpose to column
## I'm not totally sure if 3 is the right polort to use here (doesn't say in the tutorial), but someone said here that they used it and Gang said it was fine: https://afni.nimh.nih.gov/afni/community/board/read.php?1,155395,155395#msg-155395
3dDetrend -polort 3 -prefix $OUTDIR/SeedR $OUTDIR/Seed.1D\'
1dtranspose $OUTDIR/SeedR.1D $OUTDIR/Seed_ts.1D
rm $OUTDIR/SeedR.1D

## Run 1dUpsample here for non-TR synchronized onsets?

# generate impulse response function
## change dt if non-TR sync'd
waver -dt 2 -GAM -inline 1@1 > $OUTDIR/GammaHR.1D
# deconvolve seed time series
# -FALTUNG fset fpre pen fac
3dTfitter -RHS $OUTDIR/Seed_ts.1D -FALTUNG $OUTDIR/GammaHR.1D $OUTDIR/Seed_Neur 012 0

# create files for conditions
## (tutorial gives instructions for how to do this with non-TR sync'd)
for j in `seq 1 3`; do 
	for i in `seq 1 19`; do echo 1 >> $OUTDIR/PF.1D; echo 0 >> $OUTDIR/NF.1D; echo 0 >> $OUTDIR/Ctrl.1D; done
	for i in `seq 1 19`; do echo 0 >> $OUTDIR/PF.1D; echo 1 >> $OUTDIR/NF.1D; echo 0 >> $OUTDIR/Ctrl.1D; done
	for i in `seq 1 19`; do echo 0 >> $OUTDIR/PF.1D; echo 0 >> $OUTDIR/NF.1D; echo 1 >> $OUTDIR/Ctrl.1D; done
done

# create the interaction regressors
### see instructions for additional steps if not sync'ed to TR grids
1deval -a $OUTDIR/Seed_Neur.1D\' -b $OUTDIR/PF.1D -expr 'a*b' > $OUTDIR/Interaction_NeurPF.1D
1deval -a $OUTDIR/Seed_Neur.1D\' -b $OUTDIR/NF.1D -expr 'a*b' > $OUTDIR/Interaction_NeurNF.1D
1deval -a $OUTDIR/Seed_Neur.1D\' -b $OUTDIR/Ctrl.1D -expr 'a*b' > $OUTDIR/Interaction_NeurCtrl.1D
waver -GAM -peak 1 -TR 2  -input $OUTDIR/Interaction_NeurPF.1D -numout $nTRs > $OUTDIR/Interaction_PF.1D
waver -GAM -peak 1 -TR 2  -input $OUTDIR/Interaction_NeurNF.1D -numout $nTRs > $OUTDIR/Interaction_NF.1D
waver -GAM -peak 1 -TR 2  -input $OUTDIR/Interaction_NeurCtrl.1D -numout $nTRs > $OUTDIR/Interaction_Ctrl.1D

### ARK: scale Interaction regressor to have a peak of 1!  Testing this out to see if it changes results
max=$(awk -v max=-999 '{if($1>max){max=$1}}END{print max}' $OUTDIR/Interaction_PF.1D )
1deval -a $OUTDIR/Interaction_PF.1D -expr "a/$max" > $OUTDIR/Interaction_PF_scaled.1D
max=$(awk -v max=-999 '{if($1>max){max=$1}}END{print max}' $OUTDIR/Interaction_NF.1D )
1deval -a $OUTDIR/Interaction_NF.1D -expr "a/$max" > $OUTDIR/Interaction_NF_scaled.1D
max=$(awk -v max=-999 '{if($1>max){max=$1}}END{print max}' $OUTDIR/Interaction_Ctrl.1D )
1deval -a $OUTDIR/Interaction_Ctrl.1D -expr "a/$max" > $OUTDIR/Interaction_Ctrl_scaled.1D

# create contrast files
echo "0 0 0 0 0 0 0 0 1 -1 0" > $OUTDIR/contrasts/gPPI_PF_gr_NF.txt
echo "0 0 0 0 0 0 0 -1 1 0 0" > $OUTDIR/contrasts/gPPI_PF_gr_Ctrl.txt
echo "0 0 0 0 0 0 0 -1 0 1 0" > $OUTDIR/contrasts/gPPI_NF_gr_Ctrl.txt

# create the linear model
cd $OUTDIR
maskfile=$BASEDIR/Analysis/Max/templates/DNS500/DNS500template_MNI_BrainExtractionMask_2mm.nii.gz
outname=glm_output
# arguments to stim_times are in seconds!
# glt arg should always be 1
# using polort 3 here per recommendation in afni_proc.py help documentation
## wasn't sure if censor should be any different/included here, but seems fine since they do here and gang doesn't call them out on it https://afni.nimh.nih.gov/afni/community/board/read.php?1,155395,155395#msg-155395
3dDeconvolve -input $PROCDIR/epiWarped_blur6mm.nii.gz -xout -polort 3 -mask $maskfile -num_stimts 7 \
-stim_times 1 '1D: 76 190 304' 'SPMG1(38)' -stim_label 1 Control \
-stim_times 2 '1D: 0 114 228' 'SPMG1(38)' -stim_label 2 Positive_feedback \
-stim_times 3 '1D: 38 152 266' 'SPMG1(38)' -stim_label 3 Negative_feedback \
-stim_file 4 Interaction_PF_scaled.1D -stim_label 4 Interaction_PF \
-stim_file 5 Interaction_NF_scaled.1D -stim_label 5 Interaction_NF \
-stim_file 6 Interaction_Ctrl_scaled.1D -stim_label 6 Interaction_Ctrl \
-stim_file 7 Seed_ts.1D -stim_label 7 Seed_ts \
-censor $PROCDIR/glm_AFNI/outliers.1D \
-glt 1 contrasts/gPPI_PF_gr_NF.txt -glt_label 1 gPPI_PF_gr_NF \
-glt 1 contrasts/gPPI_PF_gr_Ctrl.txt -glt_label 2 gPPI_PF_gr_Ctrl \
-glt 1 contrasts/gPPI_NF_gr_Ctrl.txt -glt_label 3 gPPI_NF_gr_Ctrl \
-x1D_stop

3dREMLfit -input $PROCDIR/epiWarped_blur6mm.nii.gz -matrix Decon.xmat.1D -mask $maskfile \
  -Rbuck ${outname}.nii \
  -noFDR -tout
  
# extract coefs and tstats for workign with in SPM  
# first volume in output bucket (index 0!) is Full_Fstat, then there are 2 volumes for each condition (Coef, Tstat)
# so, the first contrast volume # is 2*(N conditions) + 1
3dTcat -prefix ${outname}_coefs.nii ${outname}.nii'[15]' ${outname}.nii'[17]' ${outname}.nii'[19]' 
3dTcat -prefix ${outname}_tstats.nii ${outname}.nii'[16]' ${outname}.nii'[18]' ${outname}.nii'[20]'  

gzip ${outname}_tstats.nii
rm ${outname}.nii
 
# -- BEGIN POST-USER -- 
echo "----JOB [$JOB_NAME.$JOB_ID] STOP [`date`]----" 
mv $HOME/$JOB_NAME.$JOB_ID.out $OUTDIR/$JOB_NAME.$JOB_ID.out	 
# -- END POST-USER --   
  
