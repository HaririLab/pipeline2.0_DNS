#!/bin/bash


sub=$1 #$1 or flag -s  #20161103_21449 #pipenotes= Change away from HardCoding later 
subDir=/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/${sub}_rerun5 #pipenotes= Change away from HardCoding later
oldSubDir=/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/${sub}
QADir=${subDir}/QA
antDir=${subDir}/antCT
freeDir=/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/FreeSurfer_AllSubs/${sub}
tmpDir=${antDir}/tmp
antPre="highRes_" #pipenotes= Change away from HardCoding later
templateDir=/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/templates/DNS500 #pipenotes= update/Change away from HardCoding later
templatePre=DNS500template_MNI #pipenotes= update/Change away from HardCoding later
#T1=$2 #/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Data/Anat/20161103_21449/bia5_21449_006.nii.gz #pipenotes= update/Change away from HardCoding later
threads=1 #default in case thread argument is not passed
threads=$2
baseDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PATH=$PATH:${baseDir}/scripts/  #add dependent scripts to path #pipenotes= update/Change to DNS scripts
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$threads
export OMP_NUM_THREADS=$threads
export ANTSPATH=/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/ants-2.2.0/bin/

T1pre=$(grep $sub /mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/DataLocations.csv | cut -d "," -f3 | sed 's/ //g')

export SUBJECTS_DIR=/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/FreeSurfer_AllSubs/
export FREESURFER_HOME=/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/freesurfer
rm -r ${antDir} ${QADir}
##Set up directory
mkdir -p $QADir
cd $subDir
mkdir -p $antDir
mkdir -p $tmpDir


###Rigidly align, to avoid future processing issues
3dresample -inset ${freeDir}/SUMA/aseg.nii.gz -master ${oldSubDir}/antCT/highRes_BrainSegmentationPosteriors1.nii.gz -prefix ${tmpDir}/resampAseg.nii.gz
3dmask_tool -input ${tmpDir}/resampAseg.nii.gz -prefix ${tmpDir}/tmp2.test.nii.gz -dilate_input 4 -4 -fill_holes
3dcalc -a ${oldSubDir}/antCT/${antPre}rWarped.nii.gz -b ${tmpDir}/tmp2.test.nii.gz -expr 'a*b' -prefix ${tmpDir}/test.nii.gz


if [[ ! -f ${antDir}/${antPre}CorticalThicknessNormalizedToTemplate.nii.gz ]];then
	#Make Montage of sub T1 brain extraction to check quality

	echo ""
	echo "#########################################################################################################"
	echo "########################################ANTs Cortical Thickness##########################################"
	echo "#########################################################################################################"
	echo ""
	###Run antCT but skip brain Extract (step 1) by naming FS brain extraction with the correct convention
	3dcalc -a ${tmpDir}/test.nii.gz -expr 'step(a)' -prefix ${antDir}/${antPre}BrainExtractionMask.nii.gz
	3dcalc -a ${antDir}/${antPre}BrainExtractionMask.nii.gz -b $${oldSubDir}/antCT/${antPre}rWarped.nii.gz -expr 'a*b' -prefix ${antDir}/${antPre}ExtractedBrain.nii.gz
	antsCorticalThickness.sh -d 3 -a ${oldSubDir}/antCT/${antPre}rWarped.nii.gz -e ${templateDir}/${templatePre}.nii.gz -m ${templateDir}/${templatePre}_BrainCerebellumProbabilityMask.nii.gz -p ${templateDir}/${templatePre}_BrainSegmentationPosteriors%d.nii.gz -t ${templateDir}/${templatePre}_Brain.nii.gz -o ${antDir}/${antPre}
else
	echo ""
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!Skipping antCT, Completed Previously!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo ""
fi
if [[ ! -f ${antDir}/${antPre}CorticalThicknessNormalizedToTemplate_blur8mm.nii.gz ]];then
	3dBlurInMask -input ${antDir}/${antPre}CorticalThicknessNormalizedToTemplate.nii.gz -mask ${templateDir}/${templatePre}AvgGMSegWarped25connected.nii.gz -FWHM 8 -prefix ${antDir}/${antPre}CorticalThicknessNormalizedToTemplate_blur8mm.nii.gz
fi
###Make VBM and smooth
if [[ ! -f ${antDir}/${antPre}JacModVBM_blur8mm.nii.gz ]];then
	antsApplyTransforms -d 3 -r ${templateDir}/${templatePre}.nii.gz -i ${antDir}/${antPre}BrainSegmentationPosteriors2.nii.gz -t ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz -t ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat -o ${antDir}/${antPre}GMwarped.nii.gz
	antsApplyTransforms -d 3 -r ${templateDir}/${templatePre}.nii.gz -i ${antDir}/${antPre}BrainSegmentationPosteriors4.nii.gz -t ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz -t ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat -o ${antDir}/${antPre}SCwarped.nii.gz
	antsApplyTransforms -d 3 -r ${templateDir}/${templatePre}.nii.gz -i ${antDir}/${antPre}BrainSegmentationPosteriors5.nii.gz -t ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz -t ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat -o ${antDir}/${antPre}BSwarped.nii.gz
	antsApplyTransforms -d 3 -r ${templateDir}/${templatePre}.nii.gz -i ${antDir}/${antPre}BrainSegmentationPosteriors6.nii.gz -t ${antDir}/${antPre}SubjectToTemplate1Warp.nii.gz -t ${antDir}/${antPre}SubjectToTemplate0GenericAffine.mat -o ${antDir}/${antPre}CBwarped.nii.gz
	3dcalc -a ${antDir}/${antPre}GMwarped.nii.gz -b ${antDir}/${antPre}SCwarped.nii.gz -c ${antDir}/${antPre}CBwarped.nii.gz -d ${antDir}/${antPre}BSwarped.nii.gz -e ${templateDir}/${templatePre}_blurMask25.nii.gz -i ${antDir}/${antPre}SubjectToTemplateLogJacobian.nii.gz -expr '(a*equals(e,1)+b*equals(e,2)+c*equals(e,3)+d*equals(e,4))*i' -prefix ${antDir}/${antPre}JacModVBM.nii.gz
	3dcalc -a ${antDir}/${antPre}GMwarped.nii.gz -b ${antDir}/${antPre}SCwarped.nii.gz -c ${antDir}/${antPre}CBwarped.nii.gz -d ${antDir}/${antPre}BSwarped.nii.gz -e ${templateDir}/${templatePre}_blurMask25.nii.gz -expr '(a*equals(e,1)+b*equals(e,2)+c*equals(e,3)+d*equals(e,4))' -prefix ${antDir}/${antPre}noModVBM.nii.gz
	3dBlurInMask -input ${antDir}/${antPre}JacModVBM.nii.gz -Mmask ${templateDir}/${templatePre}_blurMask25.nii.gz -FWHM 8 -prefix ${antDir}/${antPre}JacModVBM_blur8mm.nii.gz
	3dBlurInMask -input ${antDir}/${antPre}noModVBM.nii.gz -Mmask ${templateDir}/${templatePre}_blurMask25.nii.gz -FWHM 8 -prefix ${antDir}/${antPre}noModVBM_blur8mm.nii.gz
fi
if [[ ! -f ${QADir}/anat.BrainExtractionCheckAxial.png ]];then
	echo ""
	echo "#########################################################################################################"
	echo "####################################Make QA montages######################################"
	echo "#########################################################################################################"
	echo ""
	##Make Cortical Thickness QA montage
	ConvertScalarImageToRGB 3 ${antDir}/${antPre}CorticalThickness.nii.gz ${tmpDir}/corticalThicknessRBG.nii.gz none red none 0 1 #convert for Ants Montage
	3dcalc -a ${tmpDir}/corticalThicknessRBG.nii.gz -expr 'step(a)' -prefix ${tmpDir}/corticalThicknessRBGstep.nii.gz 
	CreateTiledMosaic -i ${antDir}/${antPre}BrainSegmentation0N4.nii.gz -r ${tmpDir}/corticalThicknessRBG.nii.gz -o ${QADir}/anat.antCTCheck.png -a 0.35 -t -1x-1 -d 2 -p mask -s [5,mask,mask] -x ${tmpDir}/corticalThicknessRBGStep.nii.gz -f 0x1  #Create Montage taking images in axial slices every 5 slices
	###Make Brain Extraction QA montages
	ConvertScalarImageToRGB 3 ${antDir}/${antPre}ExtractedBrain0N4.nii.gz ${tmpDir}/highRes_BrainRBG.nii.gz none red none 0 10
	3dcalc -a ${tmpDir}/highRes_BrainRBG.nii.gz -expr 'step(a)' -prefix ${tmpDir}/highRes_BrainRBGstep.nii.gz
	CreateTiledMosaic -i ${antDir}/${antPre}BrainSegmentation0N4.nii.gz -r ${tmpDir}/highRes_BrainRBG.nii.gz -o ${QADir}/anat.BrainExtractionCheckAxial.png -a 0.5 -t -1x-1 -d 2 -p mask -s [5,mask,mask] -x ${tmpDir}/highRes_BrainRBGstep.nii.gz -f 0x1
	CreateTiledMosaic -i ${antDir}/${antPre}BrainSegmentation0N4.nii.gz -r ${tmpDir}/highRes_BrainRBG.nii.gz -o ${QADir}/anat.BrainExtractionCheckSag.png -a 0.5 -t -1x-1 -d 0 -p mask -s [5,mask,mask] -x ${tmpDir}/highRes_BrainRBGstep.nii.gz -f 0x1
fi

