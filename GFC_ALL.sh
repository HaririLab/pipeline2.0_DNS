#!/bin/bash

TOPDIR=/cifs/hariri-long
derivDir=$TOPDIR/Studies/DNS/Imaging/derivatives
GFCscript=$TOPDIR/Scripts/pipeline2.0_DNS/GFC_DNS.sh
DNStemplate=$TOPDIR/Templates/DNS/WholeBrain

# for task in cards facename faces numLS; do
for task in numLS; do
	for f in $derivDir/epiMinProc_$task/sub-????; do
		sub=$(basename $f)
		subnum=$(echo $sub | sed 's/sub-//' )
		echo $subnum
		if [ -e $derivDir/epiMinProc_$task/$sub/epiWarped.nii.gz ]; then sbatch $GFCscript $subnum $task ; fi
	done
done


# contains() {
	# [[ $1 =~ (^| )$2($| ) ]] && exit(0) || exit(1)
# }

# #clean numLS run_3ddeconvolve paths
# #make sure to run as "bash GFC_ALL.sh" otherwise will not recognize \.
# for f in $derivDir/epiMinProc_numLS/sub-????/glm_AFNI/run_3ddeconvolve.sh; do
# # for f in $derivDir/epiMinProc_numLS/sub-1519/glm_AFNI/run_3ddeconvolve.sh; do
	# sub=$(echo $f | rev | cut -d "/" -f3 | rev)
	# outDir=$derivDir/epiMinProc_numLS/$sub
	# #home DONE
	# if [[ "$sub" =~ ^(sub-1187|sub-1214|sub-1220|sub-1241|sub-1261|sub-1359|sub-1372|sub-1390|sub-1408|sub-1435|sub-1437|sub-1454|sub-1471|sub-1483|sub-1500|sub-1513)$ ]]; then
		# sed -ci "s,\/home/ark19/linux/experiments/DNS.01//Analysis/All_Imaging/DNS[0-9]*/numLS/,$outDir,g" $outDir/glm_AFNI/run_3ddeconvolve.sh
		# sed -ci "s,\/home/ark19/linux/experiments/DNS.01//Analysis/Max/templates/DNS500,$DNStemplate,g" $outDir/glm_AFNI/run_3ddeconvolve.sh
		# echo ""
	# #munin DONE
	# elif [[ "$sub" == sub-1166 ]]; then
		# sed -ci "s,\/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/DNS[0-9]*/numLS/,$outDir,g" $outDir/glm_AFNI/run_3ddeconvolve.sh
		# sed -ci "s,\/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/templates/DNS500,$DNStemplate,g" $outDir/glm_AFNI/run_3ddeconvolve.sh
	# #tmp DONE
	# elif [[ "$sub" =~ ^(sub-1232|sub-1254|sub-1262|sub-1295|sub-1341|sub-1353|sub-1416|sub-1419|sub-1526)$ ]]; then
		# sed -ci "s,\/tmp/[0-9a-z\.]*,$outDir,g" $outDir/glm_AFNI/run_3ddeconvolve.sh
		# sed -ci "s,\/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/All_Imaging/DNS[0-9]*/numLS/,$outDir,g" $outDir/glm_AFNI/run_3ddeconvolve.sh
		# sed -ci "s,\/mnt/BIAC/munin4.dhe.duke.edu/Hariri/DNS.01/Analysis/Max/templates/DNS500,$DNStemplate,g" $outDir/glm_AFNI/run_3ddeconvolve.sh
	# #..  DONE
	# else
		# sed -ci "s,\.\.,$outDir,g" $outDir/glm_AFNI/run_3ddeconvolve.sh
		# sed -ci "s,\/home/ark19/linux/experiments/DNS.01//Analysis/All_Imaging//DNS[0-9]*/numLS,$outDir,g" $outDir/glm_AFNI/run_3ddeconvolve.sh
		# sed -ci "s,\/home/ark19/linux/experiments/DNS.01//Analysis/Max/templates/DNS500,$DNStemplate,g" $outDir/glm_AFNI/run_3ddeconvolve.sh
	# fi
# done


