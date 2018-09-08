11/9/2017										
										
While developing the DNS preprocessing2.0 pipeline, we discovered some issues with the way we originally modeled the faces task (and in fact the design itself). 										
										
Details of the issues:										
1) Per the DNS faces expression counterbalancing scheme (below), Fear & Neutral as well as Angry & Surprise are always temporally adjacent, and as such may influence each other in ways that we cannot untangle. 										
(additionally, F&S and A&N are adjacent half the time, and F&A and N&S never are)										
We discovered this by observing that the correlations between the betas for F&N and A&S are higher than all other pairwise correlations (while F&A and N&S are the lowest)										
	FNAS									
	NFSA									
	ASFN									
	SANF									
2) The default 1/128 Hz highpass filter in SPM may not be appropriate for our longer-than-usual faces blocks (50s, whereas recommend length is no greater than ~30s),										
 a conclusion that we came to by noticing that correlations between pipe1.0 and pipe2.0 values for single face > shapes estimates were much lower than expected,										
and that a primary difference between the two pipes is the filter cutoff we used (for pipe1.0, we used the SPM highpass filter with the 1/128 Hz cutoff, 										
whereas for pipe2.0 we used the AFNI 3rd-order polynomial regressors that are closer to what a 1/256 Hz cutoff would be in SPM) 										
3) Even the more-relaxed filter in AFNI (polynomial regressors) used in pipe2.0 seem to contribute to inflated correlations between adjacent blocks (e.g. F&N)										
In fact, we ran our models on simulated data with equal beta weights across blocks, and found the same correlation pattern between adjacent blocks after applying the filter, suggesting that at least a large part of this observation is due to the filter.										
										
Possible solution:										
So far, we have experimented with dividing the hammer run for each subject into four "chunks", one for each face block and the two shapes blocks on either side of the given face block.										
(for the two shapes blocks included with each faces block, only the half of the block adjacent to that faces block is used, in order to avoid the situation where, for example, 										
signal from the first faces block bleeds into the first half of the second shapes block and so contaminates the estimation of the second faces block if it is used there as well)										
This way, we greatly reduce the length of the run in the estimation of each model, reducing the presence of low frequency noise and as such allowing us to relax the filter used										
Preliminary test-retest analyses with 19 subjects in the Dunedin study indicate an increased reliability (ICC~0.6) with estimates from this model compared to the original, especially for the "> neutral" contrasts in the left basolateral or whole amygdala:										
(ICCs are calculated by extracting the mean of the voxels in the given anatomical ROI for each subject at each time point, 										
and then calculating ICC(3,1) in R. Bilateral values are done the same way, starting with extracting the mean from all ROI voxels in both hemispheres)										
	ICCs:	L_BL	R_BL	bilat_BL	L_whole	R_whole	bilat_whole	L_CM	R_CM	bilat_CM
	Anger+Fear>Neutral	0.7470625	0.418102	0.6621686	0.6371861	0.3324453	0.5661017	0.145444	0.09539367	0.185426
	Anger>Neutral	0.8104193	0.4401223	0.6912839	0.7667378	0.3743379	0.628687	0.5494797	0.242695	0.4131579
	Fear>Neutral	0.1874193	0.5082353	0.4276856	0.3540946	0.5384952	0.5300988	0.2159168	0.3310838	0.2985915
	Habituation	0.730635802	0.490337213	0.691002196	0.742327547	0.45292975	0.679385144	0.690513521	0.43914188	0.604318461
***As such, Ahmad has decided to focus on the "> neutral" contrats in the basolateral amygdala***										
										
Remaining quandaries:										
Though we have good reason to believe that the data from this new "chunked" model provide more valid estimates of expression-specific amygdala reactivity than those generated with our standard model for the hammer task, some issues remain:										
1) We have evidence to suggest that even with dividing the runs this way, there are still temporal adjaceny effects between faces blocks that we cannot untangle. 										
As such we still believe that we cannot confidently make strong claims about expression-specific effects										
(i.e., we can reason that a finding with the Fear > Neutral contrast probably relates to a response to general threatening faces, but not that it's necessarily entirely specific to fearful faces)										
2) We have not published (or seen others publish) with the "chunked" model and do not yet know how reviewers will respond.										
3) The decision to use these data was based in large part on the reliability findings in the Dunedin study (45-year-old general population sample), and we cannot be entirely certain that they translate to DNS										
