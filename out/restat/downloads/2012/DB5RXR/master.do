
* List of do-files with brief explanation of output produced by dofiles
 

*******************************
*PART 1: PREPARE MAIN DATASET
*******************************

* 0. 
make_empdecomppanel1_update.do 
	* makes empdecomppanel1_update.dta, which is the main plantlevel panel used in
	* the analysis: this is merged in in do-file 8 below

* 1.
tilrettelegg_1.do
	* Use outward FDI files from SSB and 
	* construct panel of these

* 2.
sifonpanel.do
	* Use the SIFON files from SSB, merge with manufacturing
	* statistics and save annual files of manufacturing plants with
	* foregin ownership info from SIFON: saves industriYYYY.dta
		
* 3. 
foumerge.do
	* Creates a manufacturing plantpanel that includes info
	* on foreign ownership from SIFON, some cleaning of very small plants
	* saves foumerge.dta
			
* 4.
norskemultinasjonale_dummy_rev09.do
	* Saves mne.dta which is a panel of manufacturing plants with 
	* dummy for foreign and domestic MNE status is included
	* These dummies are based on the SIFON register and register of
	* outward FDI, prepared in the previous 3 dofiles.


* 5. 
matchpanel.do
	* 1. Merge registerdata and industry data files (foumerge.dta)
	* 2. Some basic checks of the data
	* 4. Drop plants that never get a match
	* 5.Generate a matched panel containing all individuals working in
	*    matched manufacturing plants, and information (=pid year) for 
	*    individuals 1 year before and 1 year after they are observed 
	*    in a manufacturing plant from inddta. The only saved file is 
	*    matchpanel.dta

* 6.
matchyearfiles.do
	* Use matchpanel.dta from matchpanel.do and split it in separate
	* year files merging in info from both industry data and register
	* data. Must be rerun to pick other variables from REG_DIR, but 
	* additional vars from industry data can be added later
	* Save as matchYYYY.dta-files. These are the only saved files.
		* Remember that matchYYYY.dta files contain some obs with pid==.
		* and some with bnr==.
		

* 7.
movepanel_rev09.do
	* Make movepanel.dta. Contains info of all individuals
	* with match in foumerge (not only full time workers)
	* and info of these individuals the year before or after they are 
	* observed in a manufacturing plant. Add in dummy for multinational status 
	* from mne.dta made in dofile 4 above.
	

* 8.
wageregpanel.do
	*  1. Make panel with necessary variables :wagereg1temp.dta
	*  For use in wage regressions. 


************************************************
* PART 2. DESCRIPTIVES FOR SEC 2 AND 3 OF PAPER
************************************************
* 9.
table1.do
	* Make table 1 of paper  

* 10.
workercharacteristics.do
	* Makes Table 2 of paper
 	
* 11.
wagereg_ind_rev09_tables.do
	* Makes table 3 of paper


* 12. 
wagereg_felsdvreg.do
	* Uses a Stata command for 2way fixed
	* effects wage regressions. Save fixed effects
	* in ${pap4data}wagereg_felsdvreg.dta and
	* use this data to produce figure 1 and table 4


*******************************************************
* PART 4: DESCRIPTIVES ON MOBILITY, SECTION 4 OF PAPER
*******************************************************

* 10.
movers4.do
	* Makes table 5

* 11.
MNEexperience1_rev09.do
	* Makes tables 6 and 7


**********************************************
* PART 5: PRODUCTIVITY REGRESSIONS, SECTION 5
********************************************** 


*********
* 5 A. Prepare plant level data on MNE experience, non-MNE experience
********

* 12.
experience.do
	* Count the number of
	* matched workers per plant of various groups:
	* by education, experience, MNE/nonMNEexperience, new
	* Count the total years of education, experience and 
	* wages of each of these groups. 
	* These variables are saved in new_workers.dta.
	* To be used to construct various plant level shares
	* used in plant level productivity regressions.

* 13.
experience2.do
	* Check mean differences in new workers to nonMNEs 
	* with different types of experience


* 14.
experience4.do
	* Generate plant level measures of the average 
	* individual fixed effect of new workers with
	* and without MNEexp from the felsdvreg command: 
	* Saves data in ${pap4data}new_workers_meanfe.dta

* 15.
experience_annual.do
	* Count the number of new workers with MNEexp 
	* and non-MNEexp each year, also by tenure in ladt job.
	* Save data in new_workers_annual.dta. Robustness check
	* on 3 year count of recent MNEexp in plant level 
	* productivity regressions. 


************
* 5 B. Prepare plant level panel. 
**************

* 16.
regression_prepare_rev09.do
	* Saves regpanel.dta to be used for plant 
	* level regressions.
	

* 17.
productivitymeasures.do
	* Creates multilateral TFP indexes
	* Saves in ${pap4data}productivity.dta
	* Can be merged onto regressionpanel 
	* in one of the regression do-files below.

************
* 5 C. Regression do files: plant level productivity. 
**************



* 18. 
regression_MNEexp_rev09_tables.do
	* Makes table 8, 9 and 11 of paper


* 19. 
wagereg_densityplot_nonMNEworkers.do
	* Makes figure 2 of paper

***************************************************
* PART 6: WAGES BEFORE AND AFTER MOVE, SECTION 6
***************************************************

* 20.
movers_info1.do
	* makes table 12 of paper


* 21.
movers_rev09.do
	* Do movers earn more or less than non movers before mobility?
	* 1. Compare movers from MNEs to nonMNEs with stayers in MNEs
	* 2. Compare movers from MNEs to other MNEs to stayers in MNEs
	* 3. Include 1 and 2 in same regression. 1 2 3 done in a program
	* 4. Repeat program for 1-3, but redefine MNE the opposite way, so 
	* 	this compares movers from nonMNEs to MNEs 
	*	with stayers in nonMNEs.

* 22.
movers_rev09_tables.do
	*Tables 10 and 13 of paper



