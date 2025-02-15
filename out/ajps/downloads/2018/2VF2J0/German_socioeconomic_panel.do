

**********************************************************************************************************
*SKILL SPECIFICITY AND ATTITUDES TOWARDS IMMIGRATION, by Sergi Pardos-Prado and Carla Xena-Galindo       *
*                                                                                                        *
*Syntax file to reproduce 'LONGITUDINAL ANALYSIS' section, using "German_socioeconomic_panel.dta" dataset*
*                                                                                                        *
*Software used: Stata MP version 14                                                                      *
**********************************************************************************************************


***********************************************
*CODING AND RECODING VARIABLES BEFORE ANALYSIS*
***********************************************



sort pid syear /*sorting individual - year dataset*/
xtset pid syear /*setting panel data structure: years in individual panels*/

findit plottig /*to find and install Bischoff's graph schemes for graph layouts, if not installed yet*/

set scheme plottig /*once 'plottig' graph schemes have been installed*/


** Immigration variables **
capture drop borngermany isco88_2dg isco88_3dg nativeno tot_nativeno percentimmigr
gen borngermany = plj0010
recode borngermany (1=1) (2=0) (else=.)
* 1= yes --> native 0 = no --> immigrant
** Create ISCO variables **
gen isco88_2dg = substr(isco_str, 1, 2)
destring isco88_2dg, replace
*isco variable with 2 digit groups
gen isco88_3dg = substr(isco_str, 1, 3)
destring isco88_3dg, replace
*isco variable with 3 digit groups
*br isco88_2dg isco88_3dg
* For a definition of major groups see http://www.ilo.org/public/english/bureau/stat/isco/isco88/major.htm *
** Create immigration variables (3 digits)**
bysort isco88_3dg syear: egen nativeno = total(borngermany)
bysort isco88_3dg syear: egen tot_nativeno = count(borngermany)
lab var nativeno "total non-immigrants per year & isco group 3 digits"
** Create ISCO & immigration variables (3 digits) **
* Variable as a % of immigrants within each ISCO group (3 digits) *

capture drop percentimmigr

gen percentimmigr = ((tot_nativeno-nativeno)/tot_nativeno)*100
lab var percentimmigr "% immigrants by country/round & isco group 3 digits"

** Create immigration variables (2 digits)**
capture drop nativeno2d tot_nativeno2d percentimmigr2d
bysort isco88_2dg syear: egen nativeno2d = total(borngermany)
bysort isco88_2dg syear: egen tot_nativeno2d = count(borngermany)
lab var nativeno2d "total non-immigrants per year & isco group 2 digits"
* Variable as a % of immigrants within each ISCO group (2 digits) *
gen percentimmigr2d = ((tot_nativeno2d-nativeno2d)/tot_nativeno2d)*100
lab var percentimmigr2d "% immigrants by country/round & isco group 2 digits"

* Skill Specificity variables *

capture drop x  group length totgroup totworkforce numerator denominator iscosklevel skill1 skillsp 
capture drop skillsp
capture drop isco_str
gen x=1 if isco!=.
tostring isco, gen(isco_str)
gen group= substr(isco_str, 1,1)
gen length=length(isco_str)
replace group="0" if length==3 
bysort surveyyear group: egen totgroup = total(x) if x != .
*total N per group, wave
tab totgroup if group == "1"  & surveyyear == 2008
bysort surveyyear: egen totworkforce = total(x) if x != .
tab totworkforce if surveyyear == 2008
*total N (workforce) per wave
gen numerator = 0.08 if group == "1" 
replace numerator = 0.14 if group == "2"
replace numerator = 0.19 if group == "3"
replace numerator = 0.06 if group == "4" | group == "5" | group == "9"
replace numerator = 0.04 if group == "6"
replace numerator = 0.18 if group == "7" | group == "8" 
replace numerator = 0.003 if group == "0" 
/* eg: 'plant & machine operators and assemblers' (ISCO major group 8), contains 70 unit groups. 
 Total unit groups (for 10 major groups) is 390 --> 70/390=0.18  
 (see http://www.ilo.org/public/english/bureau/stat/isco/isco88/publ3.htm) */
gen denominator = totgroup/totworkforce
gen skillsp = (numerator/denominator)
*skillsp is average skill specialisation within major group: 'baseline' measure
//a.k.a 'absolute skill specificity'
**ILO does not assign an "ISCO skill-level" to ISCO88-1d group "1" (Legislators, senior officials, managers). 
//Iversen & Soskice assign the highest "ISCO skill-level" (4) to this group. 
//This measure is reffered to in Iversen & Soskice (APSR 2001) as "ISCO level of skills"
**ILO does not assign an "ISCO skill-level" to ISCO88 group "0" (Armed Forces).
// We could drop out observations in this category as they represent
// a very small percentage of the whole sample (N= 495)
gen iscosklevel = 4 if group == "1" | group == "2" 
replace iscosklevel = 3 if group == "3"
replace iscosklevel = 2 if group == "4" | group == "5" | group == "6" | group == "7" | group == "8"
replace iscosklevel = 1 if group == "9" 
replace iscosklevel =. if group == "0" 
gen skill1 = skillsp/iscosklevel if iscosklevel !=. & skillsp !=.
*skill1: relative to ISCO 4levels
capture drop school educ educyears skill2 skill22
*Variable that only includes school leaving degree
recode  pgsbil (-2/-1 7=.)  (6=1 "no degree") (1=2 "Low secondary") (2=3 "Middle secondary") ///
(3/4=4 "Upper secondary") (5=0 "other"), gen(school)
*Variable that also includes further education after school
capture drop educ
gen educ=school
replace educ = 5 if pgbbil01>0 & pgbbil01<7 & (school==2 | school==3 | school==1 | school==0) | pgbbil03==2
replace educ = 6 if pgbbil01>0 & pgbbil01<7 & school==4 | pgbbil03==2
replace educ = 7 if pgbbil02>0 & pgbbil02<11 | pgbbil03==3
capture lab def educlabel 0"Other" 1"No degree" 2"Low secondary" 3"Middle secondary" 4"Upper secondary" ///
5  "vocational" 6 "Upp sec + vocational" 7 "University degree"
lab val educ educlabel
* Years of education
capture drop educyears
gen educyears = pgbilzt
recode educyears -2=. -1=.
*skill2: relative to education 
capture drop skill2
gen skill2 = skillsp/educ if educ!=0

capture drop skill22
gen skill22 = skillsp/educyears

* Other data management
capture drop dv
recode immigrconcern 1=1 2/3=0 else=., gen(dv) /*concern over immigration binary*/

capture drop income
xtile income=netinclastmonth, nquantile(5) /*recodification of income in quintiles*/

capture drop age
gen age=syear-yearbirth /*age linear*/

capture drop temporary
gen temporary=timecontract==2 /*temporary contract dummy*/

capture drop mean_income
capture drop income_fixed
egen mean_income=mean(income), by(pid) /*mean income per individual for hybrid models in appendix*/
gen income_fixed=income-mean_income /*intra-individual de-meaned income for hybrid models in appendix*/

capture drop difficnewjob_dummy
recode difficnewjob 3=1 1/2=0 else=., gen(difficnewjob_dummy) /*difficulty to find a new job dummy*/

capture drop mean_difficulty
capture drop difficulty_fixed
egen mean_difficulty=mean(difficnewjob), by(pid) /*mean perception of difficulty to find job per individual for hybrid models in appendix*/
gen difficulty_fixed=difficnewjob-mean_difficulty /*intra-individual de-meaned perception of difficulty to find job for hybrid models in appendix*/

recode immigrconcern 1=3 2=2 3=1 else=., gen(concern_rec) /*concern over immigration linear*/

recode unemployed_reg 1=1 2=0 else=., gen(unemployed2) /*unemployed dummy*/

gen tenure = syear-currentjobyear /*years spent doing same job*/
egen tenure2 = mean(tenure), by(syear isco88_2dg) /*occupation-year average of years spent during same job*/

*Transition rates from t-1 to t (diagonal matrix) for each ISCO group

gen isco_alt=.
replace isco_alt=1 if isco88_2dg==11
replace isco_alt=2 if isco88_2dg==12
replace isco_alt=3 if isco88_2dg==13
replace isco_alt=4 if isco88_2dg==21
replace isco_alt=5 if isco88_2dg==22
replace isco_alt=6 if isco88_2dg==23
replace isco_alt=7 if isco88_2dg==24
replace isco_alt=8 if isco88_2dg==31
replace isco_alt=9 if isco88_2dg==32
replace isco_alt=10 if isco88_2dg==33
replace isco_alt=11 if isco88_2dg==34
replace isco_alt=12 if isco88_2dg==41
replace isco_alt=13 if isco88_2dg==42
replace isco_alt=14 if isco88_2dg==51
replace isco_alt=15 if isco88_2dg==52
replace isco_alt=16 if isco88_2dg==61
replace isco_alt=17 if isco88_2dg==71
replace isco_alt=18 if isco88_2dg==72
replace isco_alt=19 if isco88_2dg==73
replace isco_alt=20 if isco88_2dg==74
replace isco_alt=21 if isco88_2dg==81
replace isco_alt=22 if isco88_2dg==82
replace isco_alt=23 if isco88_2dg==83
replace isco_alt=24 if isco88_2dg==91
replace isco_alt=25 if isco88_2dg==92
replace isco_alt=26 if isco88_2dg==93
replace isco_alt=27 if isco88_2dg==99




sort pid syear 
xtset pid syear 

gen lag_isco88_2dg=l.isco88_2dg

capture drop transition
gen transition=.



foreach x of num 2000(1)2014{
tab isco88_2dg lag_isco88_2dg if syear==`x' & isco88_2dg !=-3 & lag_isco88_2dg !=-3 & unemployed2==0, col nofreq matcell(x_`x')
	foreach i of num 1(1)27{
	scalar define total_`i'_`x'=x_`x'[1,`i']+x_`x'[2,`i']+x_`x'[3,`i']+x_`x'[4,`i']+x_`x'[5,`i']+x_`x'[6,`i']+x_`x'[7,`i']+x_`x'[8,`i']+x_`x'[9,`i']+x_`x'[10,`i']+x_`x'[11,`i']+x_`x'[12,`i']+x_`x'[13,`i']+x_`x'[14,`i']+x_`x'[15,`i']+x_`x'[16,`i']+x_`x'[17,`i']+x_`x'[18,`i']+x_`x'[19,`i']+x_`x'[20,`i']+x_`x'[21,`i']+x_`x'[22,`i']+x_`x'[23,`i']+x_`x'[24,`i']+x_`x'[25,`i']+x_`x'[26,`i']+x_`x'[27,`i']
	scalar isco_`i'_`x'=x_`x'[`i',`i']/total_`i'_`x'
	replace transition=isco_`i'_`x' if isco_alt==`i' & syear==`x'
	}
}



*Individual mean of all skill specificity variables per individual for hybrid models in Appendix

capture drop mean_skillsp
capture drop mean_skill1
capture drop mean_skill22
capture drop mean_our
capture drop mean_tenure
capture drop mean_transition
egen mean_skillsp=mean(skillsp), by(pid)
egen mean_skill1=mean(skill1), by(pid)
egen mean_skill22=mean(skill22), by(pid)
egen mean_our=mean(our), by(pid)
egen mean_tenure=mean(tenure2), by(pid)
egen mean_transition=mean(transition), by(pid)

*Intra-individual de-meaned skill specificity variables for hybrid models in Appendix


capture drop skillsp_fixed
capture drop skill1_fixed
capture drop skill22_fixed
capture drop our_fixed
capture drop tenure_fixed
capture drop transition_fixed
gen skillsp_fixed=skillsp-mean_skillsp
gen skill1_fixed=skill1-mean_skill1
gen skill22_fixed=skill22-mean_skill22
gen our_fixed=our-mean_our
gen tenure_fixed=tenure2-mean_tenure
gen transition_fixed=transition-mean_transition


*Missing variable count to select only valid observations across individuals. ///
/// First missing count variable includes all variables except for transition, to avoid losing the first time observation ///
/// (since transition is a difference between t-1 and t). Second count variable includes the variable transition.

capture drop missing
egen missing = rmiss(percentimmigr difficnewjob_dummy skillsp skill1 skill22 income manualwork unemployed_reg gender age churchatt temporary educyears tenure2)
egen missing2 = rmiss(percentimmigr difficnewjob_dummy skillsp skill1 skill22 income manualwork unemployed_reg gender age churchatt temporary educyears tenure2 transition)



*********
*TABLE 2*
*********


xtlogit difficnewjob_dummy c.skillsp income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, fe
est store m1
margins, dydx(skillsp manualwork income educyears) post 
coefplot, xline(0) levels(95) xtitle(Average Marginal Effects) coeflabel(skillsp = "Skill Specificity" income = "Income" ///
manualwork = "Working Class" educyears = "Education") ylabel(, labsize(medium)) xtitle("AMEs predicting difficulty new job", size(medium)) byopts(xrescale) name(A, replace)

xtlogit difficnewjob_dummy our income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, fe
est store m2
margins, dydx(our manualwork income educyears) post   
coefplot, xline(0) levels(95) xtitle(Average Marginal Effects) coeflabel(our = "Occup Unempl" income = "Income" ///
manualwork = "Working Class" educyears = "Education") ylabel(, labsize(medium)) xtitle("AMEs predicting difficulty new job", size(medium)) byopts(xrescale) name(B, replace)

xtlogit difficnewjob_dummy tenure2 income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, fe
est store m3
margins, dydx(tenure2 manualwork income educyears) post
coefplot, xline(0) levels(95) xtitle(Average Marginal Effects) coeflabel(tenure2 = "Tenure" income = "Income" ///
manualwork = "Working Class" educyears = "Education") ylabel(, labsize(medium)) xtitle("AMEs predicting difficulty new job", size(medium)) byopts(xrescale) name(C, replace)

xtlogit difficnewjob_dummy transition income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing2==0, fe
est store m4
margins, dydx(transition manualwork income educyears) post
coefplot, xline(0) levels(90) xtitle(Average Marginal Effects) coeflabel(transition = "Transition" income = "Income" ///
manualwork = "Working Class" educyears = "Education") ylabel(, labsize(medium)) xtitle("AMEs predicting difficulty new job", size(medium)) byopts(xrescale) name(D, replace)




*********
*TABLE 3*
*********


xtlogit dv difficnewjob_dummy skillsp income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, fe
est store m5
margins, dydx(difficnewjob_dummy manualwork income educyears) post
coefplot, xline(0) levels(95) xtitle(Average Marginal Effects) coeflabel(difficnewjob_dummy = "Difficulty New Job" income = "Income" ///
manualwork = "Working Class" educyears = "Education") ylabel(, labsize(medium)) xtitle("AMEs predicting anti-immigrant concern", size(medium)) byopts(xrescale) name(A2, replace)


xtlogit dv difficnewjob_dummy our income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, fe
est store m6
margins, dydx(difficnewjob_dummy manualwork income educyears) post   
coefplot, xline(0) levels(95) xtitle(Average Marginal Effects) coeflabel(difficnewjob_dummy = "Difficulty New Job" income = "Income" ///
manualwork = "Working Class" educyears = "Education") ylabel(, labsize(medium)) xtitle("AMEs predicting anti-immigrant concern", size(medium)) byopts(xrescale) name(B2, replace)


xtlogit dv difficnewjob_dummy tenure2 income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, fe
est store m7
margins, dydx(difficnewjob_dummy manualwork income educyears) post
coefplot, xline(0) levels(95) xtitle(Average Marginal Effects) coeflabel(difficnewjob_dummy = "Difficulty New Job" income = "Income" ///
manualwork = "Working Class" educyears = "Education") ylabel(, labsize(medium)) xtitle("AMEs predicting anti-immigrant concern", size(medium)) byopts(xrescale) name(C2, replace)


xtlogit dv difficnewjob_dummy transition income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing2==0, fe
est store m8
margins, dydx(difficnewjob_dummy manualwork income educyears) post
coefplot, xline(0) levels(95) xtitle(Average Marginal Effects) coeflabel(difficnewjob_dummy = "Difficulty New Job" income = "Income" ///
manualwork = "Working Class" educyears = "Education") ylabel(, labsize(medium)) xtitle("AMEs predicting anti-immigrant concern", size(medium)) byopts(xrescale) name(D2, replace)


**********
*FIGURE 5*
**********
  
 graph combine A A2
 
 graph combine B B2
 
 graph combine C C2
 
 graph combine D D2
 

 *Mentioned in page 19 in the text: Z tests showing skill specificity coefficients significantly different across models.

dis (0.17 - 0.04) / sqrt(0.05^2 + 0.04^2) /*Z score: difference between skill specificity coefficient across model 1 and model 5*/

dis (0.09 - 0.06) / sqrt(0.01^2 + 0.01^2) /*Z score: difference between skill specificity coefficient across model 2 and model 6*/

dis (0.02 - 0.005) / sqrt(0.01^2 + 0.005^2) /*Z score: difference between tenure coefficient across model 3 and model 7*/

dis (0.28 - (-0.19)) / sqrt(0.17^2 + 0.14^2) /*Z score: difference between transition coefficient across model 4 and model 8*/




****************************
*DIFFERENCES IN DIFFERENCES*
****************************

*********
*TABLE 4*
*********

capture drop treated
gen treated=0
replace treated=1 if syear==2003 & unemployed2==1
replace treated=1 if syear==2004 & unemployed2==1
replace treated=1 if syear==2005 & unemployed2==1

xtset pid syear

xtreg concern_rec treated i.syear, fe vce(cluster pid)
est store diff1

xtreg concern_rec treated i.syear if l.skillsp>0.82, fe vce(cluster pid)
est store diff2

xtreg concern_rec treated i.syear if l.skillsp<0.82, fe vce(cluster pid)
est store diff3



*With our


xtreg concern_rec treated i.syear if l.our>6.71, fe vce(cluster pid)
est store diff4

xtreg concern_rec treated i.syear if l.our<6.71, fe vce(cluster pid)
est store diff5

*With tenure

xtreg concern_rec treated i.syear if l.tenure2>11.6, fe vce(cluster pid)
est store diff6

xtreg concern_rec treated i.syear if l.tenure2<11.6, fe vce(cluster pid)
est store diff7


*With transition


xtreg concern_rec treated i.syear if l.transition>0.71, fe vce(cluster pid)
est store diff8

xtreg concern_rec treated i.syear if l.transition<0.71, fe vce(cluster pid)
est store diff9




************************************************************************************************************************
*UPPER PANEL TABLE 5 (EXPLORING MECHANISMS): unemployed at t-1 more likely to find a mini/midi job during Hartz reforms*
************************************************************************************************************************

tab plb0187

capture drop minijob
recode plb0187 1/2=1 3=0 else=., gen(minijob)

capture drop hartz
gen hartz=0
replace hartz=1 if syear==2003
replace hartz=1 if syear==2004
replace hartz=1 if syear==2005

capture drop unemp_hartz
gen unemp_hartz=0
replace unemp_hartz=1 if l.unemployed2==1 & hartz==1


xtreg minijob unemp_hartz i.syear, fe vce(cluster pid)
est store mj1
xtreg minijob unemp_hartz i.syear if l.skillsp>0.82, fe vce(cluster pid)
est store mj2
xtreg minijob unemp_hartz i.syear if l.skillsp<0.82, fe vce(cluster pid)
est store mj3
xtreg minijob unemp_hartz i.syear if l.our>6.71, fe vce(cluster pid)
est store mj4
xtreg minijob unemp_hartz i.syear if l.our<6.71, fe vce(cluster pid)
est store mj5
xtreg minijob unemp_hartz i.syear if l.tenure2>11.6, fe vce(cluster pid)
est store mj6
xtreg minijob unemp_hartz i.syear if l.tenure2<11.6, fe vce(cluster pid)
est store mj7
xtreg minijob unemp_hartz i.syear if l.transition>0.71, fe vce(cluster pid)
est store mj8
xtreg minijob unemp_hartz i.syear if l.transition<0.71, fe vce(cluster pid)
est store mj9


****************************************************************************************************************************************************
*LOWER PANEL TABLE 5 (EXPLORING MECHANISMS): unemployed at t-1 who got a minijob during Hartz reforms are less likely to worry about getting as job*
****************************************************************************************************************************************************

  
capture drop mini_unemp_hartz
gen mini_unemp_hartz=0
replace mini_unemp_hartz =1 if minijob==1 & l.unemployed2==1 & hartz==1


xtreg difficnewjob mini_unemp_hartz i.syear, fe vce(cluster pid)
est store mj10
xtreg difficnewjob mini_unemp_hartz i.syear if l.skillsp>0.82, fe vce(cluster pid)
est store mj11
xtreg difficnewjob mini_unemp_hartz i.syear if l.skillsp<0.82, fe vce(cluster pid)
est store mj12
xtreg difficnewjob mini_unemp_hartz i.syear if l.our>6.71, fe vce(cluster pid)
est store mj13
xtreg difficnewjob mini_unemp_hartz i.syear if l.our<6.71, fe vce(cluster pid)
est store mj14
xtreg difficnewjob mini_unemp_hartz i.syear if l.tenure2>11.6, fe vce(cluster pid)
est store mj15
xtreg difficnewjob mini_unemp_hartz i.syear if l.tenure2<11.6, fe vce(cluster pid)
est store mj16
xtreg difficnewjob mini_unemp_hartz i.syear if l.transition>0.71, fe vce(cluster pid)
est store mj17
xtreg difficnewjob mini_unemp_hartz i.syear if l.transition<0.71, fe vce(cluster pid)
est store mj18

  
*MENTIONED IN PAGE 24 IN THE TEXT: Abadie's semi-parametric diff-in-diff estimator. Control group weihted by propensity to be selected into treatment.
  

findit absdid /*find and installed absdid package if not installed yet*/  
  
capture drop treated
gen treated=0
replace treated=1 if syear==2003 & unemployed2==1
replace treated=1 if syear==2004 & unemployed2==1
replace treated=1 if syear==2005 & unemployed2==1

  
absdid concern_rec, tvar(treated) xvar(income manualwork gender age temporary educyears skillsp our)
  
  

*****************
*ONLINE APPENDIX*
*****************

*TABLE B1

sum dv difficnewjob_dummy skillsp our tenure2 transition income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing == 0


**********
*TABLE B2*
**********

xtlogit difficnewjob_dummy skill1 income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, fe
est store r1
xtlogit difficnewjob_dummy skill22 income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, fe
est store r2

xtlogit difficnewjob_dummy skill1 income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, re
est store r3
xtlogit difficnewjob_dummy skill22 income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, re
est store r4


**********
*TABLE B3*
**********

xtlogit dv difficnewjob_dummy skill1 income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, fe
est store r7
xtlogit dv difficnewjob_dummy skill22 income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, fe
est store r8
xtlogit dv difficnewjob_dummy skill1 income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, re
est store r7
xtlogit dv difficnewjob_dummy skill22 income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, re
est store r8


**********
*TABLE B4*
**********

melogit difficnewjob_dummy skillsp_fixed mean_skillsp income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0 || isco: || pid:
est store hyb1

melogit difficnewjob_dummy our_fixed mean_our income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0 || isco: || pid:
est store hyb2

melogit difficnewjob_dummy tenure_fixed mean_tenure income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0 || isco: || pid:
est store hyb3

melogit difficnewjob_dummy transition_fixed mean_transition income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0 || isco: || pid:
est store hyb4

melogit dv difficulty_fixed mean_difficulty skillsp_fixed mean_skillsp manualwork income unemployed_reg gender age churchatt temporary educyears if missing==0 || isco: || pid:
est store hyb5

melogit dv difficulty_fixed mean_difficulty our_fixed mean_our manualwork income unemployed_reg gender age churchatt temporary educyears if missing==0 || isco: || pid:
est store hyb6

melogit dv difficulty_fixed mean_difficulty tenure_fixed mean_tenure manualwork income unemployed_reg gender age churchatt temporary educyears if missing==0 || isco: || pid:
est store hyb7

melogit dv difficulty_fixed mean_difficulty transition_fixed mean_transition manualwork income unemployed_reg gender age churchatt temporary educyears if missing==0 || isco: || pid:
est store hyb8


**********
*TABLE B5*
**********

xtlogit difficnewjob_dummy skillsp income manualwork unemployed_reg gender age churchatt temporary educyears i.isco88_1dg if missing==0, fe
est store occ_fix1

xtlogit difficnewjob_dummy our income manualwork unemployed_reg gender age churchatt temporary educyears i.isco88_1dg if missing==0, fe
est store occ_fix2

xtlogit difficnewjob_dummy tenure2 income manualwork unemployed_reg gender age churchatt temporary educyears i.isco88_1dg if missing==0, fe
est store occ_fixed3

xtlogit difficnewjob_dummy transition income manualwork unemployed_reg gender age churchatt temporary educyears i.isco88_1dg if missing==0, fe
est store occ_fixed4

**********
*TABLE B6*
**********

xtlogit dv difficnewjob_dummy skillsp income manualwork unemployed_reg gender age churchatt temporary educyears i.isco88_1dg if missing==0, fe
est store occ_fix5

xtlogit dv difficnewjob_dummy our income manualwork unemployed_reg gender age churchatt temporary educyears i.isco88_1dg if missing==0, fe
est store occ_fix6

xtlogit dv difficnewjob_dummy tenure2 income manualwork unemployed_reg gender age churchatt temporary educyears i.isco88_1dg if missing==0, fe
est store occ_fix7

xtlogit dv difficnewjob_dummy transition income manualwork unemployed_reg gender age churchatt temporary educyears i.isco88_1dg if missing==0, fe
est store occ_fix8


**********
*TABLE B7*
**********

sem (skillsp income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr -> difficnewjob) ///
(difficnewjob skillsp income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr -> concern_rec), vce(cluster pid)
 
estat teffects

sem (our income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr -> difficnewjob) ///
(difficnewjob our income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr -> concern_rec),  vce(cluster pid)
  
 estat teffects
 
 
sem (tenure2 income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr -> difficnewjob) ///
(difficnewjob tenure2 income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr -> concern_rec),  vce(cluster pid)
  
 estat teffects
 
 
sem (transition income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr -> difficnewjob) ///
(difficnewjob transition income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr -> concern_rec), vce(cluster pid)
  
 estat teffects
 


*TABLE B8

xtlogit difficnewjob_dummy skillsp income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, re
est store m1a
xtlogit difficnewjob_dummy our income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, re
est store m2a
xtlogit difficnewjob_dummy tenure2 income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, re
est store m3a
xtlogit difficnewjob_dummy transition income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing2==0, re
est store m4a

  
*TABLE B9

xtlogit dv difficnewjob_dummy skillsp income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, re
est store m5a
xtlogit dv difficnewjob_dummy our income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, re
est store m6a
xtlogit dv difficnewjob_dummy tenure2 income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, re
est store m7a
xtlogit dv difficnewjob_dummy transition income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing2==0, re
est store m8a

***********  
*TABLE B10*
***********

xtreg concern_rec c.skillsp##i.temporary difficnewjob_dummy income manualwork unemployed_reg gender age churchatt  educyears percentimmigr if missing==0, fe
est store tempr1

xtreg concern_rec c.our##i.temporary difficnewjob_dummy income manualwork unemployed_reg gender age churchatt  educyears percentimmigr if missing==0, fe
est store tempr2

xtreg concern_rec c.tenure2##i.temporary difficnewjob_dummy income manualwork unemployed_reg gender age churchatt  educyears percentimmigr if missing==0, fe /*significant! Temporary contract more anti-immigrant among individuals with high levels of tenure in their previous job*/
est store tempr3

xtreg concern_rec c.transition##i.temporary difficnewjob_dummy income manualwork unemployed_reg gender age churchatt  educyears percentimmigr if missing2==0, fe /*significant! Temporary contract more anti-immigrant in professions with high levels of permanency*/
est store tempr4


***********
*TABLE B11*
***********


xtreg difficnewjob skillsp income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, fe
est store lin1
xtreg difficnewjob our income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, fe
est store lin2
xtreg difficnewjob tenure2 income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, fe
est store lin3
xtreg difficnewjob transition income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing2==0, fe
est store lin4

***********
*TABLE B12*
***********

xtreg concern_rec difficnewjob skillsp income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, fe
est store lin5
xtreg concern_rec difficnewjob our income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, fe
est store lin6
xtreg concern_rec difficnewjob tenure2 income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing==0, fe
est store lin7
xtreg concern_rec difficnewjob transition income manualwork unemployed_reg gender age churchatt temporary educyears percentimmigr if missing2==0, fe
est store lin8


***********
*TABLE B13*
***********

xtlogit difficnewjob_dummy c.skillsp##c.educyears income manualwork unemployed_reg gender age churchatt temporary percentimmigr if missing==0, fe
est store lint1
xtlogit difficnewjob_dummy c.our##c.educyears income manualwork unemployed_reg gender age churchatt temporary percentimmigr if missing==0, fe
est store lint2
xtlogit difficnewjob_dummy c.tenure2##c.educyears income manualwork unemployed_reg gender age churchatt temporary percentimmigr if missing==0, fe
est store lint3
xtlogit difficnewjob_dummy c.transition##c.educyears income manualwork unemployed_reg gender age churchatt temporary percentimmigr if missing2==0, fe
est store lint4  


**********
*TABLE 14*
**********

xtlogit dv difficnewjob_dummy##c.educyears skillsp income manualwork unemployed_reg gender age churchatt temporary percentimmigr if missing==0, fe
est store lint5
xtlogit dv difficnewjob_dummy##c.educyears our income manualwork unemployed_reg gender age churchatt temporary percentimmigr if missing==0, fe
est store lint6
xtlogit dv difficnewjob_dummy##c.educyears tenure2 income manualwork unemployed_reg gender age churchatt temporary percentimmigr if missing==0, fe
est store lint7
xtlogit dv difficnewjob_dummy##c.educyears transition income manualwork unemployed_reg gender age churchatt temporary percentimmigr if missing2==0, fe
est store lint8  




**********
*TABLE 15*
**********

  hausman m1 m1a
  hausman m2 m2a
  hausman m3 m3a
  hausman m4 m4a
  
  

***********************
** FIGURE 7 APPENDIX **
***********************

est restore lint1

capture drop MV conb conse a upper lower
generate MV=(_n+6)
replace MV=. if MV>18
label var MV"Education"

matrix b=e(b)
matrix V=e(V)
scalar b1=b[1,1]
scalar b2=b[1,2]
scalar b3=b[1,3]
scalar varb1=V[1,1]
scalar varb2=V[2,2]
scalar varb3=V[3,3]
scalar covb1b3=V[1,3]
scalar covb2b3=V[2,3]

gen conb=b1+b3*MV
gen conse=sqrt(varb1+varb3*(MV^2)+2*covb1b3*MV)
gen a=1.96*conse
gen upper=conb+a
gen lower=conb-a


graph twoway (scatter conb MV, yaxis(1) msymbol(circle) msize(small) mcolor(black) yline(0) xline(0)  ///
 graphregion(color(white)) ///
 xtitle("Education", size(3.5)) xlabel(7(1)18, labsize(3.5)) ylabel(-0.2 1, labsize(3.5) axis(1)) fcolor(gs6) ytitle(Effect Skill Specificity, size(3.5))  legend(off)) ///
 (rcap lower upper MV, lcolor(black) vertical) || kdensity educyears, yaxis(2) ///
 lpattern(solid) lwidth(thin) ytitle(Density Education, size(3.5) axis(2)) ylabel(0 0.4, labsize(2.5) axis(2)) name(skillsp_edu, replace)




*IE our over Education

est restore lint2

capture drop MV conb conse a upper lower
generate MV=(_n+6)
replace MV=. if MV>18
label var MV"Education"

matrix b=e(b)
matrix V=e(V)
scalar b1=b[1,1]
scalar b2=b[1,2]
scalar b3=b[1,3]
scalar varb1=V[1,1]
scalar varb2=V[2,2]
scalar varb3=V[3,3]
scalar covb1b3=V[1,3]
scalar covb2b3=V[2,3]

gen conb=b1+b3*MV
gen conse=sqrt(varb1+varb3*(MV^2)+2*covb1b3*MV)
gen a=1.96*conse
gen upper=conb+a
gen lower=conb-a


graph twoway (scatter conb MV, yaxis(1) msymbol(circle) msize(small) mcolor(black) yline(0) xline(0)  ///
 graphregion(color(white)) ///
 xtitle("Education", size(3.5)) xlabel(7(1)18, labsize(3.5)) ylabel(-0.2 1, labsize(3.5) axis(1)) fcolor(gs6) ytitle(Effect Occup. Unemployment, size(3.5))  legend(off)) ///
 (rcap lower upper MV, lcolor(black) vertical) || kdensity educyears, yaxis(2) ///
 lpattern(solid) lwidth(thin) ytitle(Density Education, size(3.5) axis(2)) ylabel(0 0.4, labsize(2.5) axis(2)) name(our_edu, replace)



*IE tenure2 over Education


est restore lint3

capture drop MV conb conse a upper lower
generate MV=(_n+6)
replace MV=. if MV>18
label var MV"Education"

matrix b=e(b)
matrix V=e(V)
scalar b1=b[1,1]
scalar b2=b[1,2]
scalar b3=b[1,3]
scalar varb1=V[1,1]
scalar varb2=V[2,2]
scalar varb3=V[3,3]
scalar covb1b3=V[1,3]
scalar covb2b3=V[2,3]

gen conb=b1+b3*MV
gen conse=sqrt(varb1+varb3*(MV^2)+2*covb1b3*MV)
gen a=1.96*conse
gen upper=conb+a
gen lower=conb-a


graph twoway (scatter conb MV, yaxis(1) msymbol(circle) msize(small) mcolor(black) yline(0) xline(0)  ///
 graphregion(color(white)) ///
 xtitle("Education", size(3.5)) xlabel(7(1)18, labsize(3.5)) ylabel(-0.2 1, labsize(3.5) axis(1)) fcolor(gs6) ytitle(Effect Tenure, size(3.5))  legend(off)) ///
 (rcap lower upper MV, lcolor(black) vertical) || kdensity educyears, yaxis(2) ///
 lpattern(solid)  lwidth(thin) ytitle(Density Education, size(3.5) axis(2)) ylabel(0 0.4, labsize(2.5) axis(2)) name(tenure_edu, replace)



* IE transition over Education


est restore lint4

capture drop MV conb conse a upper lower
generate MV=(_n+6)
replace MV=. if MV>18
label var MV"Education"

matrix b=e(b)
matrix V=e(V)
scalar b1=b[1,1]
scalar b2=b[1,2]
scalar b3=b[1,3]
scalar varb1=V[1,1]
scalar varb2=V[2,2]
scalar varb3=V[3,3]
scalar covb1b3=V[1,3]
scalar covb2b3=V[2,3]

gen conb=b1+b3*MV
gen conse=sqrt(varb1+varb3*(MV^2)+2*covb1b3*MV)
gen a=1.96*conse
gen upper=conb+a
gen lower=conb-a


graph twoway (scatter conb MV, yaxis(1) msymbol(circle) msize(small) mcolor(black) yline(0) xline(0)  ///
 graphregion(color(white)) ///
 xtitle("Education", size(3.5)) xlabel(7(1)18, labsize(3.5)) ylabel(-0.2 1, labsize(3.5) axis(1)) fcolor(gs6) ytitle(Effect Transition, size(3.5))  legend(off)) ///
 (rcap lower upper MV, lcolor(black) vertical) || kdensity educyears, yaxis(2) ///
 lpattern(solid) lwidth(thin) ytitle(Density Education, size(3.5) axis(2)) ylabel(0 0.4, labsize(2.5) axis(2)) name(transition_edu, replace)



graph combine skillsp_edu our_edu tenure_edu transition_edu


***********************
** FIGURE 8 APPENDIX **
***********************

est restore lint5

capture drop MV conb conse a upper lower
generate MV=(_n+6)
replace MV=. if MV>18
label var MV"Education"

matrix b=e(b)
matrix V=e(V)
scalar b1=b[1,1]
scalar b2=b[1,2]
scalar b3=b[1,3]
scalar varb1=V[1,1]
scalar varb2=V[2,2]
scalar varb3=V[3,3]
scalar covb1b3=V[1,3]
scalar covb2b3=V[2,3]

gen conb=b1+b3*MV
gen conse=sqrt(varb1+varb3*(MV^2)+2*covb1b3*MV)
gen a=1.96*conse
gen upper=conb+a
gen lower=conb-a


graph twoway (scatter conb MV, yaxis(1) msymbol(circle) msize(small) mcolor(black) yline(0) xline(0)  ///
 graphregion(color(white)) ///
 xtitle("Education", size(3.5)) xlabel(7(1)18, labsize(3.5)) ylabel(-0.2 1, labsize(3.5) axis(1)) fcolor(gs6) ytitle(Eff. Diff New Job | Skill Specificity, size(3))  legend(off)) ///
 (rcap lower upper MV, lcolor(black) vertical) || kdensity educyears, yaxis(2) ///
 lpattern(solid)  lwidth(thin) ytitle(Density Education, size(3.5) axis(2)) ylabel(0 0.4, labsize(2.5) axis(2)) name(diffnewjob_edu_skill, replace)




*IE Diff new job over Education | Occupational Unemployment

est restore lint6

capture drop MV conb conse a upper lower
generate MV=(_n+6)
replace MV=. if MV>18
label var MV"Education"

matrix b=e(b)
matrix V=e(V)
scalar b1=b[1,1]
scalar b2=b[1,2]
scalar b3=b[1,3]
scalar varb1=V[1,1]
scalar varb2=V[2,2]
scalar varb3=V[3,3]
scalar covb1b3=V[1,3]
scalar covb2b3=V[2,3]

gen conb=b1+b3*MV
gen conse=sqrt(varb1+varb3*(MV^2)+2*covb1b3*MV)
gen a=1.96*conse
gen upper=conb+a
gen lower=conb-a


graph twoway (scatter conb MV, yaxis(1) msymbol(circle) msize(small) mcolor(black) yline(0) xline(0)  ///
 graphregion(color(white)) ///
 xtitle("Education", size(3.5)) xlabel(7(1)18, labsize(3.5)) ylabel(-0.2 1, labsize(3.5) axis(1)) fcolor(gs6) ytitle(Eff. Diff New Job | Occ. Unemp, size(3))  legend(off)) ///
 (rcap lower upper MV, lcolor(black) vertical) || kdensity educyears, yaxis(2) ///
 lpattern(solid)  lwidth(thin) ytitle(Density Education, size(3.5) axis(2)) ylabel(0 0.4, labsize(2.5) axis(2)) name(diffnewjob_edu_our, replace)




* IE Diff new job over Education | Tenure 

est restore lint7

capture drop MV conb conse a upper lower
generate MV=(_n+6)
replace MV=. if MV>18
label var MV"Education"

matrix b=e(b)
matrix V=e(V)
scalar b1=b[1,1]
scalar b2=b[1,2]
scalar b3=b[1,3]
scalar varb1=V[1,1]
scalar varb2=V[2,2]
scalar varb3=V[3,3]
scalar covb1b3=V[1,3]
scalar covb2b3=V[2,3]

gen conb=b1+b3*MV
gen conse=sqrt(varb1+varb3*(MV^2)+2*covb1b3*MV)
gen a=1.96*conse
gen upper=conb+a
gen lower=conb-a


graph twoway (scatter conb MV, yaxis(1) msymbol(circle) msize(small) mcolor(black) yline(0) xline(0)  ///
 graphregion(color(white)) ///
 xtitle("Education", size(3.5)) xlabel(7(1)18, labsize(3.5)) ylabel(-0.2 1, labsize(3.5) axis(1)) fcolor(gs6) ytitle(Eff. Diff New Job | Tenure, size(3))  legend(off)) ///
 (rcap lower upper MV, lcolor(black) vertical) || kdensity educyears, yaxis(2) ///
 lpattern(solid)  lwidth(thin) ytitle(Density Education, size(3.5) axis(2)) ylabel(0 0.4, labsize(2.5) axis(2)) name(diffnewjob_edu_tenure, replace)



*IE Diff new job over Education | Transition

est restore lint8

capture drop MV conb conse a upper lower
generate MV=(_n+6)
replace MV=. if MV>18
label var MV"Education"

matrix b=e(b)
matrix V=e(V)
scalar b1=b[1,1]
scalar b2=b[1,2]
scalar b3=b[1,3]
scalar varb1=V[1,1]
scalar varb2=V[2,2]
scalar varb3=V[3,3]
scalar covb1b3=V[1,3]
scalar covb2b3=V[2,3]

gen conb=b1+b3*MV
gen conse=sqrt(varb1+varb3*(MV^2)+2*covb1b3*MV)
gen a=1.96*conse
gen upper=conb+a
gen lower=conb-a


graph twoway (scatter conb MV, yaxis(1) msymbol(circle) msize(small) mcolor(black) yline(0) xline(0)  ///
 graphregion(color(white)) ///
 xtitle("Education", size(3.5)) xlabel(7(1)18, labsize(3.5)) ylabel(-0.2 1, labsize(3.5) axis(1)) fcolor(gs6) ytitle(Eff. Diff New Job | Transition, size(3))  legend(off)) ///
 (rcap lower upper MV, lcolor(black) vertical) || kdensity educyears, yaxis(2) ///
 lpattern(solid)  lwidth(thin) ytitle(Density Education, size(3.5) axis(2)) ylabel(0 0.4, labsize(2.5) axis(2)) name(diffnewjob_edu_transition, replace)



graph combine diffnewjob_edu_skill  diffnewjob_edu_our  diffnewjob_edu_tenure  diffnewjob_edu_transition

 
 
  
  
 **********
 *TABLE C1*
 **********
 
capture drop treated
gen treated=0
replace treated=1 if syear==1999 & unemployed2==1


xtreg concern_rec treated i.syear, fe vce(cluster pid)
est store pretreat1


capture drop treated
gen treated=0
replace treated=1 if syear==2000 & unemployed2==1


xtreg concern_rec treated i.syear, fe vce(cluster pid)
est store pretreat2
 
 
capture drop treated
gen treated=0
replace treated=1 if syear==2001 & unemployed2==1


xtreg concern_rec treated i.syear, fe vce(cluster pid)
est store pretreat3


capture drop treated
gen treated=0
replace treated=1 if syear==2002 & unemployed2==1

xtreg concern_rec treated i.syear, fe vce(cluster pid)
est store placebo1


capture drop treated
gen treated=0
replace treated=1 if syear==2006 & unemployed2==1


xtreg concern_rec treated i.syear, fe vce(cluster pid)
est store placebo2


   
  
**********************
*TABLE C2 UPPER PANEL*
**********************

gen spd=0
replace spd = 1 if plh0012 ==1

recode plh0013 5=1 4=2 3=3 2=4 1=5 else=., gen(strength)
gen spd_strength=.
replace spd_strength = strength if spd==1


gen cdu=0
replace cdu = 1 if plh0012 ==2 | plh0012 ==3 | plh0012 ==4

gen cdu_strength=.
replace cdu_strength = strength if cdu==1


gen insider = .
replace insider = 0 if unemployed2==1 | temporary ==1
replace insider = 1 if unemployed2==0 | temporary ==0


capture drop treated
gen treated=0
replace treated=1 if syear==2003 & insider==1
replace treated=1 if syear==2004 & insider==1
replace treated=1 if syear==2005 & insider==1

sum skillsp
xtset pid syear

xtlogit spd treated i.syear, fe
est store spd1
xtlogit spd treated i.syear if l.skillsp>0.82, fe
est store spd2
xtlogit spd treated i.syear if l.our>6.71, fe
est store spd3
xtlogit spd treated i.syear if l.tenure2>11.6, fe
est store spd4
xtlogit spd treated i.syear if l.transition>0.71, fe
est store spd5

**********************
*TABLE C2 LOWER PANEL*
**********************

xtreg spd_strength treated i.syear, fe vce(cluster pid)
est store spd_stre1
xtreg spd_strength treated i.syear if l.skillsp>0.82, fe vce(cluster pid)
est store spd_stre2
xtreg spd_strength treated i.syear if l.our>6.71, fe vce(cluster pid)
est store spd_stre3
xtreg spd_strength treated i.syear if l.tenure2>11.6, fe vce(cluster pid)
est store spd_stre4
xtreg spd_strength treated i.syear if l.transition>0.71, fe vce(cluster pid)
est store spd_stre5

**********************
*TABLE C3 UPPER PANEL*
**********************


xtlogit cdu treated i.syear, fe
est store cdu1
xtlogit cdu treated i.syear if l.skillsp>0.82, fe
est store cdu2
xtlogit cdu treated i.syear if l.our>6.71, fe
est store cdu3
xtlogit cdu treated i.syear if l.tenure2>11.6, fe
est store cdu4
xtlogit cdu treated i.syear if l.transition>0.71, fe
est store cdu5

**********************
*TABLE C3 LOWER PANEL*
**********************

xtreg cdu_strength treated i.syear, fe vce(cluster pid)
est store cdu_stre1
xtreg cdu_strength treated i.syear if l.skillsp>0.82, fe vce(cluster pid)
est store cdu_stre2
xtreg cdu_strength treated i.syear if l.our>6.71, fe vce(cluster pid)
est store cdu_stre3
xtreg cdu_strength treated i.syear if l.tenure2>11.6, fe vce(cluster pid)
est store cdu_stre4
xtreg cdu_strength treated i.syear if l.transition>0.71, fe vce(cluster pid)
est store cdu_stre5



***********
*FIGURE C9*
***********  

egen dvmean_unempl = mean(dv) if unemployed2==1, by(syear)
egen dvmean_nonunempl = mean(dv) if unemployed2==0, by(syear)

label var dvmean_unempl"Unemployed"
label var dvmean_nonunempl"Not unemployed"

graph twoway (line dvmean_unempl syear if  syear<2004, sort lcolor(black) lpattern(solid) xlabel(#7, valuelabel ///
labsize(small))) (line dvmean_nonunempl syear if syear<2004, sort lcolor(black) xline(2002.5) lpattern(dash))



