## This script is for calculating the task regressors that do not vary across subjects (for faces, cards, and facename)
## For GFC, need to calculate task regressors without censoring because task regression happens along with cenosring in the 3dtproject step
## (ie so we can't use the design matrix in the minproc/glm dir because it's been censored)

TOPDIR=/cifs/hariri-long
OUTDIR=$TOPDIR/Scripts/pipeline2.0_DNS/config
TMPDIR=/work/long/tmp_GFCreg

mkdir -p $OUTDIR
mkdir -p $TMPDIR

## faces
# create design matrix without censoring
N=195
3dDeconvolve -nodata $N 2 -xout -num_stimts 5 -x1D $TMPDIR/Decon_Faces.xmat.1D -x1D_stop \
  -stim_times 1 '1D: 0 88 176 264 352' 'SPMG1(38)' -stim_label 1 Shapes \
  -stim_times 2 '1D: 38' 'SPMG1(50)' -stim_label 2 Faces1 \
  -stim_times 3 '1D: 126' 'SPMG1(50)' -stim_label 3 Faces2 \
  -stim_times 4 '1D: 214' 'SPMG1(50)' -stim_label 4 Faces3 \
  -stim_times 5 '1D: 302' 'SPMG1(50)' -stim_label 5 Faces4 
grep -v "#" $TMPDIR/Decon_Faces.xmat.1D | head -$N | cut -d" " -f4- > $OUTDIR/stim_regressors_faces.txt # the cut command takes columns 4 through the end (first regressors are for detrending)


## facename
# create design matrix without censoring
N=162
3dDeconvolve -nodata $N 2 -xout -num_stimts 3 -x1D $TMPDIR/Decon_Facename.xmat.1D -x1D_stop \
 -stim_times 1 '1D: 4 82 160 238' 'SPMG1(21)' -stim_label 1 Encoding \
 -stim_times 2 '1D: 29 107 185 263' 'SPMG1(21)' -stim_label 2 Distractor \
 -stim_times 3 '1D: 54 132 210 288' 'SPMG1(24)' -stim_label 3 Recall 
grep -v "#" $TMPDIR/Decon_Facename.xmat.1D | head -$N | cut -d" " -f4- > $OUTDIR/stim_regressors_facename.txt # the cut command takes columns 4 through the end
 
## cards
# create design matrix without censoring
N=171
3dDeconvolve -nodata $N 2 -xout -num_stimts 3 -x1D $TMPDIR/Decon_Cards.xmat.1D -x1D_stop \
 -stim_times 1 '1D: 76 190 304' 'SPMG1(38)' -stim_label 1 Ctrl \
 -stim_times 2 '1D: 0 114 228' 'SPMG1(38)' -stim_label 2 PF \
 -stim_times 3 '1D: 38 152 266' 'SPMG1(38)' -stim_label 3 NF 
grep -v "#" $TMPDIR/Decon_Cards.xmat.1D | head -$N | cut -d" " -f4- > $OUTDIR/stim_regressors_cards.txt # the cut command takes columns 4 through the end
 

