clear all
cd "C:\Users\ddoherty\Documents\Flip Flop\analysis\"
insheet using "exp_study_1.csv", comma name

drop if country!="United States"
rename whichstatedoyoulivein state

*** Drop cases randomly assigned to an alternative experiment for different project published elsewhere. 
tab experiment, gen(exp_)
rename exp_1 exp_flipflop
rename exp_2 exp_scandal
keep if exp_flip
drop exp*

keep state generallyspeakingdoyouusuallythi wouldyoucallyourselfastrongdemoc wouldyoucallyourselfastrongrepub doyouthinkofyourselfasclosertoth whatistheyearofyourbirth whatisthehighestlevelofeducation whatwasyourtotalfamilyincomein20 *whatracialore* whatisyourgender howinterestedareyouinpoliticsand wehearalotoftalkthesedaysaboutli whenitcomestoabortion flipflop abortion_position thinkingaboutthesocialsecuritysy ss_position buildmorenuclearpowerplantsasawa nuclear_position ifyoulivedinrepresentativejonesd basedonwhatyouknowaboutrepresent howdoyoufeelaboutrepresentativej doyouthinkmarkjonesishonestandtr representativesmustoftenmakediff nuclearpowerhowlikelydoyouthinki taxeshowlikelydoyouthinkitisthat socialsecurityhowlikelydoyouthin medicarehowlikelydoyouthinkitist foreignpolicyhowlikelydoyouthink environmentalpolicyhowlikelydoyo immigrationhowlikelydoyouthinkit abortionhowlikelydoyouthinkitist
save "..\ReplicationArchive\study1.dta", replace




clear all

insheet using "exp_study_2.csv", comma name
drop if country!="United States"
rename whichstatedoyoulivein state
****FIX ERROR IN INTERNAL LABELING of THESE HIDDEN VALUES IN SGIZMO (Question IDs used in the randomization script were right, but internal labels were not). 
rename nuke_pos nuke_pos_err
rename isis_pos isis_pos_err
rename abort_pos isis_pos
rename isis_pos_err nuke_pos
rename nuke_pos_err abort_pos


***Subjective judgements about OK to change positions
keep state generallyspeakingdoyouusuallythi wouldyoucallyourselfastrongdemoc wouldyoucallyourselfastrongrepub doyouthinkofyourselfasclosertoth whatistheyearofyourbirth whatisthehighestlevelofeducation whatwasyourtotalfamilyincomein20 *whatracialore* whatisyourgender howinterestedareyouinpoliticsand wehearalotoftalkthesedaysaboutli *_pos fflop_* *regar* dealingwiththeislamicstateiniraq constructionofnewnuclearpowerpla v56 v58 *conf* lawsthatensurethatwomenhaveacces increasingtheageatwhichpeoplebor sendingamericangroundtroopsintoi issuingmorefederalpermitstoallow makinglowincomeadultswithoutchil increasingfuelefficiencystandard legalizingsamesexmarriageinallst reducingspendingonnationaldefens *like* v92 v93 ifyoulivedinrepresentativejonesd basedonwhatyouknowaboutrepresent howdoyoufeelaboutrepresentativej doyouthinkrepresentativejonesish representativesintheushousemusto

save "..\ReplicationArchive\study2.dta", replace
