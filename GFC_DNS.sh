#!/bin/bash
#
# Script: GFC_DNS.sh
# Purpose: Take a minimally preprocessed Task Scan and finish preprocessing like you would for rest, removing main effects of task
# Author: Maxwell Elliott

###############################################################################
#
# Environment set up
#
###############################################################################

# --- BEGIN GLOBAL DIRECTIVE -- 
#SBATCH --output=/dscrhome/%u/GFC_DNS.%j.out 
#SBATCH --error=/dscrhome/%u/GFC_DNS.%j.out 
# SBATCH --mail-user=%u@duke.edu
# SBATCH --mail-type=END
#SBATCH --mem=12000 # max is 64G on common partition, 64-240G on common-large
# -- END GLOBAL DIRECTIVE -- 

sub=$1
task=$2

TOPDIR=/cifs/hariri-long
minProcDir=$TOPDIR/Studies/DNS/Imaging/derivatives/epiMinProc_$task/sub-$sub

sub=$(echo $minProcDir | rev | cut -d "/" -f1 | rev)
subDir=$(echo $minProcDir | rev | cut -d "/" -f3- | rev)
outDir=${minProcDir}
tmpDir=${outDir}/tmp
minProcEpi=${outDir}/epiWarped.nii.gz
templateDir=$TOPDIR/Templates/DNS/WholeBrain #pipenotes= update/Change away from HardCoding later
templatePre=DNS500template_MNI_ #pipenotes= update/Change away from HardCoding later
antDir=${subDir}/ANTs/$sub
configDir=$TOPDIR/Scripts/pipeline2.0_DNS/config
antPre="highRes_" #pipenotes= Change away from HardCoding later
FDthresh=.25 #pipenotes= Change away from HardCoding later, also find citations for what you decide likely power 2014, minimun of .5 fd 20DVARS suggested
DVARSthresh=1.55 #pipenotes= Change away from HardCoding later, also find citations for what you decide

echo "----JOB [$SLURM_JOB_ID] SUBJ $sub START [`date`] on HOST [$HOSTNAME]----"
echo "----CALL: $0 $@----"

size=$(ls -l {outDir}/parcellations/power264.txt | awk '{print $5}')
if [[ $size -gt 0 ]]; then
	echo ""
	echo "!!!!!!!!!!!!!!!!!!! GFC has already bee processed for this Dir!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!Double check to make sure this is correct or delete and rerun!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!EXITING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo ""
	exit
fi

if [[ $task != rest ]]; then # for rest, all the prep has already been done

	# Check assumptions
	if [[ ! -f ${minProcEpi} ]];then
		echo ""
		echo "!!!!!!!!!!!!!!!!!!!!!!!No minimally processed epi Scan Found!!!!!!!!!!!!!!!!!!!!!!!"
		echo "!!!!!!!!!!!!!!!!!!need to run epi_minProc first before this script!!!!!!!!!!!!!!!!!"
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!EXITING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		echo ""
		exit
	fi


	mkdir -p $tmpDir

	###Extract CompCor Components
	voxSize=$(@GetAfniRes ${minProcEpi})
	numTR=$(3dinfo -nv ${minProcEpi})
	3dresample -input ${templateDir}/${templatePre}Brain.nii.gz -dxyz $voxSize -prefix ${tmpDir}/refTemplate4epi.nii.gz
	antsApplyTransforms -d 3 -t ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz -t ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat -o ${tmpDir}/BrainSegmentationPosteriors1Warped2Template.nii.gz -r ${tmpDir}/refTemplate4epi.nii.gz -i ${antDir}/${antPre}BrainSegmentationPosteriors1.nii.gz
	antsApplyTransforms -d 3 -t ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz -t ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat -o ${tmpDir}/BrainSegmentationPosteriors3Warped2Template.nii.gz -r ${tmpDir}/refTemplate4epi.nii.gz -i ${antDir}/${antPre}BrainSegmentationPosteriors3.nii.gz
	3dcalc -a ${tmpDir}/BrainSegmentationPosteriors3Warped2Template.nii.gz -b ${tmpDir}/BrainSegmentationPosteriors1Warped2Template.nii.gz -expr 'step(a-0.95)+step(b-0.95)' -prefix ${tmpDir}/seg.wm.csf.nii.gz
	3dmerge -1clust_depth 5 5 -prefix ${tmpDir}/seg.wm.csf.depth.nii.gz ${tmpDir}/seg.wm.csf.nii.gz
	3dcalc -a ${tmpDir}/seg.wm.csf.depth.nii.gz -expr 'step(a-1)' -prefix ${tmpDir}/seg.wm.csf.erode.nii.gz ##pipenotes:for DBIS may want to edit this to move further away from WM because of smaller voxels
	3dcalc -a ${tmpDir}/seg.wm.csf.erode.nii.gz -b ${outDir}/epiWarped.nii.gz -expr 'a*b' -prefix ${tmpDir}/rest.wm.csf.nii.gz #MLS: space doesn't match?
	3dpc -pcsave 5 -prefix ${tmpDir}/pcRest.wm.csf ${tmpDir}/rest.wm.csf.nii.gz
	mv ${tmpDir}/pcRest.wm.csf_vec.1D ${outDir}/

	####Setup Censoring
	awk -v thresh=$FDthresh '{if($1 > thresh) print NR}' ${outDir}/FD.1D | awk '{print ($1 - 1) " " $2}' > ${outDir}/FDcensorTRs.1D #find TRs above threshold and subtract 1 from list to 0 index for afni's liking
	awk -v thresh=$DVARSthresh '{if($1 > thresh) print NR}' ${outDir}/DVARS.1D | awk '{print ($1) " " $2}' > ${outDir}/DVARScensorTRs.1D #find TRs above threshold and Don't subtract 1 from list because DVARS is based on change from first TR and has one less value, value 1 will therefore be for afni 1 index (TR number 2)
	cat ${outDir}/FDcensorTRs.1D ${outDir}/DVARScensorTRs.1D | sort -g | uniq > ${outDir}/censorTRs.1D #combine DVARS and FD TRs above threshold 
	###cat ${outDir}/pcRest*.wm.csf_vec.1D > ${outDir}/allCompCorr.1D #MLS necessary?


	###Get Task Regressors
	# numLS is the only task where the task design varies by subject, so just for that one we need to calculate the individual design matrix without censoring
	if [[ $task == "numLS" ]]; then 
		N_conditions=$(grep num_stimts $minProcDir/glm_AFNI/run_3ddeconvolve.sh | awk '{print $10}')
		echo "N_conditions $N_conditions"
		N_TRs=354;
		# echo "outDir=$outDir" > $tmpDir/run_3ddeconvolve_noCensor.sh
		echo "3dDeconvolve -nodata $N_TRs 2 -xout -num_stimts $N_conditions -x1D $tmpDir/Decon_noCensor.xmat.1D -x1D_stop \\" >> $tmpDir/run_3ddeconvolve_noCensor.sh
		# grep stim_times $minProcDir/glm_AFNI/run_3ddeconvolve.sh | sed 's/\/tmp\/[0-9a-z\.]*/$outDir/g' >> $tmpDir/run_3ddeconvolve_noCensor.sh
		grep stim_times $minProcDir/glm_AFNI/run_3ddeconvolve.sh >> $tmpDir/run_3ddeconvolve_noCensor.sh
		sh $tmpDir/run_3ddeconvolve_noCensor.sh
		grep -v "#" $tmpDir/Decon_noCensor.xmat.1D | head -$N_TRs | cut -d" " -f4- > $outDir/stim_regressors.txt
		stim_regressors=$outDir/stim_regressors.txt
	else # otherwise just pull from the pre-calculated file (done with GFC_getTaskRegressors.sh)
		stim_regressors=$configDir/stim_regressors_${task}.txt
	fi


	####Project everything out
	####################### replaced allmotion.1D with motion_spm_deg.1D and allmotion_deriv.1D with motion_deriv.1D
	clist=$(cat ${outDir}/censorTRs.1D)
	lenC=$(echo $clist | wc -w )
	if [[ $lenC == 0 ]];then
		3dTproject -input ${outDir}/epiWarped.nii.gz -mask ${templateDir}/${templatePre}BrainExtractionMask_2mmDil1.nii.gz  -prefix ${outDir}/epiPrepped_blur6mm.nii.gz -ort ${outDir}/motion.1D -ort ${outDir}/motion_deriv.1D -ort $stim_regressors -ort ${outDir}/pcRest.wm.csf_vec.1D -polort 1 -bandpass 0.008 0.9999 -blur 6
	##comments: Decided against a more restricted blur in mask with different compartments for cerebellum etc, because that approach seemed to be slighly harming tSNR actually and did not help with peak voxel or extent analyses when applied to Faces contrast. Decided to use a dilated Brain Extraction mask because this at least gets rid of crap that is way outside of brain. This saves space (slightly) and aids with cleaner visualizations. A GM mask can still later be applied for group analyses, this way we at least leave that up to the user.
	else
		3dTproject -input ${outDir}/epiWarped.nii.gz -mask ${templateDir}/${templatePre}BrainExtractionMask_2mmDil1.nii.gz -prefix ${outDir}/epiPrepped_blur6mm.nii.gz -CENSORTR $clist -ort ${outDir}/motion.1D -ort ${outDir}/motion_deriv.1D -ort $stim_regressors -ort ${outDir}/pcRest.wm.csf_vec.1D -polort 1 -bandpass 0.008 0.9999 -blur 6
	##comments: Decided against a more restricted blur in mask with different compartments for cerebellum etc, because that approach seemed to be slighly harming tSNR actually and did not help with peak voxel or extent analyses when applied to Faces contrast. Decided to use a dilated Brain Extraction mask because this at least gets rid of crap that is way outside of brain. This saves space (slightly) and aids with cleaner visualizations. A GM mask can still later be applied for group analyses, this way we at least leave that up to the user.
	fi

fi # end if task != rest

#extract power 264 time series
#### note to Maria: the roi2ts.R script is now in the pipeline2.0_common dir!
mkdir -p ${outDir}/parcellations
$TOPDIR/Scripts/pipeline2.0_common/roi2ts.R -r $TOPDIR/Templates/DNS/Atlases/Power2011_264/power264_2mm.nii.gz -i ${outDir}/epiPrepped_blur6mm.nii.gz > ${outDir}/parcellations/power264.txt


###Clean up
rm -r $tmpDir


# -- BEGIN POST-USER -- 
echo "----JOB [$SLURM_JOB_ID] STOP [`date`]----" 
mv /dscrhome/$USER/GFC_DNS.$SLURM_JOB_ID.out $outDir/GFC_DNS.$SLURM_JOB_ID.out		 
# -- END POST-USER -- 


