#!/bin/bash
#
# Script: anat_DNS_antBEfailed.sh
# Purpose: Secondary pipeline for processing T1 anatomical images for the DNS study. Use this if anat_DNS.sh failed because ant Brain extraction did not work properly. This script will run freesurfer brain extraction first instead and then use that as input to antCT and rest of processing.
# Author: Maxwell Elliott
#


###########!!!!!!!!!Pipeline to do!!!!!!!!!!!!!#############
#1)make citations #citations
#2)Follow up on #pipeNotes using ctrl f pipeNotes.... Made these when I knew a trick or something I needed to do later

###########!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!###########################

###############################################################################
#
# Environment set up
#
###############################################################################

sub=$1 #$1 or flag -s  #20161103_21449 #pipenotes= Change away from HardCoding later 
subDir=/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/${sub}_BEfsRedo #pipenotes= Change away from HardCoding later
oldSubDir=/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/${sub}
QADir=${subDir}/QA
antDir=${subDir}/antCT
freeDir=/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/FreeSurfer_AllSubs/${sub}_BEfsRedo
tmpDir=${antDir}/tmp
antPre="highRes_" #pipenotes= Change away from HardCoding later
templateDir=/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/templates/DNS500 #pipenotes= update/Change away from HardCoding later
templatePre=DNS500template_MNI #pipenotes= update/Change away from HardCoding later
#T1=$2 #/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Data/Anat/20161103_21449/bia5_21449_006.nii.gz #pipenotes= update/Change away from HardCoding later
threads=$2
if [ ${#threads} -eq 0 ]; then threads=1; fi # antsRegistrationSyN won't work properly if $threads is empty
#baseDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
baseDir=/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Scripts/pipeline2.0_DNS # using BASH_SOURCE doesn't work for cluster jobs bc they are saved as local copies to nodes (ARK)
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$threads
export OMP_NUM_THREADS=$threads
export ANTSPATH=/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/ants-2.2.0/bin/
export QA_TOOLS=/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/QAtools_v1.2/
export PATH=$PATH:$ANTSPATH:${baseDir}/scripts/:/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/huginBin/bin/ #add dependent scripts to path #pipenotes= update/Change to DNS scripts

T1pre=$(grep $sub /mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/DataLocations.csv | cut -d "," -f3 | sed 's/ //g')
if [[ $T1pre == "not_collected" || $T1pre == "dont_use" ]];then
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!NO T1, Trying to Run on Coplanar so that EPIs might be salvaged!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!Make sure you know what you are doing if you use this sub in any analysis!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	T1pre=$(grep $sub /mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/DataLocations.csv | cut -d "," -f2 | sed 's/ //g')
	echo "Make sure you know what you are doing if you use this sub in any analysis" > ${antDir}/000000.COPLANARnotT1.00000000
	echo "Make sure you know what you are doing if you use this sub in any analysis" > ${freeDir}/000000.COPLANARnotT1.00000000
fi


export SUBJECTS_DIR=/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/FreeSurfer_AllSubs/
export FREESURFER_HOME=/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/scripts/freesurfer


#Delete all old directories that were bad
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "Deleting previous runs of anat_DNS.sh and epi_minProc_DNS.sh"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
rm -r ${freeDir} ${subDir}/antCT

##Set up directory
mkdir -p $QADir
cd $subDir
mkdir -p $antDir
mkdir -p $tmpDir
if [[ ${T1pre} == *.nii.gz ]];then
	T1=/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/${T1pre}
else
		###Check to make sure T1 has correct number of slices other exit and complain
		lenT1=$(ls /mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/${T1pre}/*.dcm | wc -l)
	if [[ $lenT1 == 162 ]];then
		to3d -anat -prefix tmpT1.nii.gz /mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/${T1pre}/*.dcm
		mv tmpT1.nii.gz ${tmpDir}/
		T1=${tmpDir}/tmpT1.nii.gz
	else
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!T1 is the Wrong Size, wrong number of slices!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!Make Sure you Know what you are doing!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		to3d -anat -prefix tmpT1.nii.gz /mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/${T1pre}/*.dcm
		mv tmpT1.nii.gz ${tmpDir}/
		T1=${tmpDir}/tmpT1.nii.gz
	fi
fi
###Rigidly align, to avoid future processing issues
antsRegistrationSyN.sh -d 3 -t r -f ${templateDir}/${templatePre}.nii.gz -m $T1 -n $threads -o ${antDir}/${antPre}r
if [[ ! -f ${freeDir}/surf/rh.pial ]];then
	###Prep for Freesurfer with PreSkull Stripped
	#Citation: followed directions from https://surfer.nmr.mgh.harvard.edu/fswiki/UserContributions/FAQ (search skull)
	echo ""
	echo "#########################################################################################################"
	echo "#####################################FreeSurfer Surface Generation#######################################"
	echo "#########################################################################################################"
	echo ""
	rm -r ${freeDir}
	cd /mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/FreeSurfer_AllSubs/
	${FREESURFER_HOME}/bin/recon-all_noLink -all -s ${sub}_BEfsRedo -openmp $threads -i ${antDir}/${antPre}rWarped.nii.gz
	echo $freeDir
	recon-all -s $sub_BEfsRedo -localGI -openmp $threads
else
	echo ""
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!Skipping FreeSurfer, Completed Previously!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo ""
fi
#Run SUMA
if [[ ! -f ${freeDir}/SUMA/std.60.lh.area.niml.dset ]];then
	echo ""
	echo "#########################################################################################################"
	echo "######################################Map Surfaces to SUMA and AFNI######################################"
	echo "#########################################################################################################"
	echo ""
	cd ${freeDir}
	rm -r ${freeDir}/SUMA
	##Add back missing orig files
	#mri_convert ${antDir}/${antPre}ExtractedBrain0N4.nii.gz ${freeDir}/mri/001.mgz
	#mri_convert ${freeDir}/mri/001.mgz ${freeDir}/mri/orig.mgz
	#mkdir ${freeDir}/orig
	@SUMA_Make_Spec_FS_lgi -NIFTI -ld 60 -sid FreeSurfer
	#Convert to GIFTIs for potential use with PALM for TFCE
	#ConvertDset -o_gii -input ${freeDir}/SUMA/std.60.lh.area.niml.dset -prefix ${freeDir}/SUMA/std.60.lh.area
	#ConvertDset -o_gii -input ${freeDir}/SUMA/std.60.rh.area.niml.dset -prefix ${freeDir}/SUMA/std.60.rh.area
	#ConvertDset -o_gii -input ${freeDir}/SUMA/std.60.lh.thickness.niml.dset -prefix ${freeDir}/SUMA/std.60.lh.thickness
	#ConvertDset -o_gii -input ${freeDir}/SUMA/std.60.rh.thickness.niml.dset -prefix ${freeDir}/SUMA/std.60.rh.thickness
else
	echo ""
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!Skipping SUMA_Make_Spec, Completed Previously!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo ""
fi
if [[ ! -f ${antDir}/${antPre}CorticalThicknessNormalizedToTemplate.nii.gz ]];then
	#Make Montage of sub T1 brain extraction to check quality

	echo ""
	echo "#########################################################################################################"
	echo "########################################ANTs Cortical Thickness##########################################"
	echo "#########################################################################################################"
	echo ""
	3dresample -inset ${freeDir}/SUMA/aseg.nii.gz -master ${oldSubDir}/antCT/highRes_BrainSegmentationPosteriors1.nii.gz -prefix ${tmpDir}/resampAseg.nii.gz
	3dmask_tool -input ${tmpDir}/resampAseg.nii.gz -prefix ${tmpDir}/tmp2.test.nii.gz -dilate_input 4 -4 -fill_holes
	3dcalc -a ${oldSubDir}/antCT/${antPre}rWarped.nii.gz -b ${tmpDir}/tmp2.test.nii.gz -expr 'a*b' -prefix ${tmpDir}/test.nii.gz
	###Run antCT but skip brain Extract (step 1) by naming FS brain extraction with the correct convention
	3dcalc -a ${tmpDir}/test.nii.gz -expr 'step(a)' -prefix ${antDir}/${antPre}BrainExtractionMask.nii.gz
	3dcalc -a ${antDir}/${antPre}BrainExtractionMask.nii.gz -b $${oldSubDir}/antCT/${antPre}rWarped.nii.gz -expr 'a*b' -prefix ${antDir}/${antPre}ExtractedBrain.nii.gz
	antsCorticalThickness.sh -d 3 -a ${antDir}/${antPre}rWarped.nii.gz -e ${templateDir}/${templatePre}.nii.gz -m ${templateDir}/${templatePre}_BrainCerebellumProbabilityMask.nii.gz -p ${templateDir}/${templatePre}_BrainSegmentationPosteriors%d.nii.gz -t ${templateDir}/${templatePre}_Brain.nii.gz -o ${antDir}/${antPre}
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


#cleanup
#mv highRes_* antCT/ #pipeNotes: add more deletion and clean up to minimize space, think about deleting Freesurfer and some of SUMA output
rm -r ${antDir}/tmp ${freeDir}/SUMA/lh.* ${freeDir}/SUMA/rh.* ${freeDir}/SUMA/FreeSurfer_.*spec #${freeDir}/bem ${freeDir}/label ${freeDir}/morph ${freeDir}/mpg ${freeDir}/mri ${freeDir}/rgb ${freeDir}/src ${freeDir}/surf ${freeDir}/tiff ${freeDir}/tmp ${freeDir}/touch ${freeDir}/trash 
rm ${antDir}/${antPre}BrainNormalizedToTemplate.nii.gz ${antDir}/${antPre}TemplateToSubject*
gzip ${freeDir}/SUMA/*.nii 
 
