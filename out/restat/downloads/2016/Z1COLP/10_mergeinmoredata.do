clear
set more off
#delimit ;
/*****************************************************************************************************************;
**This dofile starts from expandedDHSGPS_mergedrecoded and generates mergedallrecoded;
other pre-generated datasets this dofile also uses:
DHSGPS_matchedwith2004
hh_simulatedmindistance_YYYY_grid
some more raw files
*****************************************************************************************************************/;

*****************************************************************************************************************;
*Paths;
*****************************************************************************************************************;

*access files in subdirectory generated by data creating dofiles;
local indataset "dtafiles/expandedDHSGPS_mergedrecoded";
local arsenicdataset "dtafiles/HouseholdArsenic_2004.dta";
local outdataset "dtafiles/mergedallrecoded.dta";


*****************************************************************************************************************;
*Main
*****************************************************************************************************************;

use "`indataset'", clear;
cap drop _merge;


**Added 1999 survey to get district, which we get for 2004 and 2007 from the community leader surveys below;
preserve;
use "rawdta/DHS1999/BDHR41DT/BDHR41FL.DTA", clear;
keep hv001 hv002 shdist;
gen hhid=9*1000000+hv001*1000+hv002;
keep hhid shdist;
tempfile district1999;
save `district1999', replace;
restore;

merge m:1 hhid using `district1999';
drop if _merge==2;
drop _merge;


**merging in community leader survey to get village piped water and district**;
preserve;
use "rawdta/DHS2007/BDSQ51DT/bdCQ51FL.DTA", clear;
gen dhsidyear=2007*1000+coclust;
keep dhsidyear co113 codist;
tempfile community2007;
save `community2007', replace;

use "rawdta/DHS2004/bdsq4idt/bdSQ4IFL.dta", clear;
gen dhsidyear=2004*1000+cclust;
keep dhsidyear c113 cdist;
tempfile community2004;
save `community2004', replace;
restore;

merge m:1 dhsidyear using `community2007';
drop _merge;
merge m:1 dhsidyear using `community2004';
drop _merge;

gen villagepipedwater=1 if co113==1|c113==11|c113==12;
replace villagepipedwater=0 if villagepipedwater==. & ((co113!=. & year==2007) | (c113!=. & year==2004));
replace villagepipedwater=. if co113==99|c113==99;

label variable villagepipedwater "village leader lists piped water as primary water source in cluster";

gen district=cdist;
replace district=codist if district==. & codist!=.;
replace district=shdist if district==. & shdist!=.;

drop cdist codist shdist co113 c113;

**merge in simulated measures;
preserve;
use "dtafiles/hh_simulatedmindistance_2007_grid.dta", clear;
for var  mean_mindistanceU-wfraction_mindistanceC_1m: rename X X_G;
sort dhsid; 
gen year=2007;
tempfile sim2007;
save `sim2007', replace;

use "dtafiles/hh_simulatedmindistance_2004_grid.dta";
for var  mean_mindistanceU-wfraction_mindistanceC_1m: rename X X_G;
sort dhsid; 
gen year=2004;
tempfile sim2004;
save `sim2004', replace;

use "dtafiles/hh_simulatedmindistance_1999_grid.dta";
for var  mean_mindistanceU-wfraction_mindistanceC_1m: rename X X_G;
sort dhsid; 
gen year=1999;
append using `sim2007';
append using `sim2004';

gen dhsidnum= real(substr(dhsid,-3,3));
gen dhsidyear=year*1000+dhsidnum;
sort dhsidyear;
tempfile sims;
save `sims', replace;
restore;

merge m:1 dhsidyear using `sims';
rename _m mergewithsimulated;
drop dhsidnum;

**Generate treatment variable interactions with post2002 and birthyear dummies;
forvalues i=1996(1)2007 {;
	local j=substr(string(`i'),-2,2);
	gen wfraction_mindistanceC_1m_G_b`j'=wfraction_mindistanceC_1m_G*byear`i';
};

foreach measure in "fraction_mindistanceC_1m_G" 
	"wfraction_mindistanceC_1m_G" {; //"fraction_mindistanceC_2m_G" "wfraction_mindistanceC_2m_G" {;
	gen `measure'_2002=`measure'*post2002;
};

*Switching in 2004;
preserve;

use "`arsenicdataset'", clear;
keep contaminatedorsurface dhsid04 v002 heardofarsenic;
sort dhsid04 v002;
tempfile arsenic;
save `arsenic', replace;

restore;
sort dhsid04 v002;
merge dhsid04 v002 using `arsenic';
drop if _m==2;
drop _m;

egen dhsid2004_year=group(dhsidyear childbyear);
gen heardofarsenic_2002=heardofarsenic*post2002;

**Merge in nearest 2004 cluster for 2007 and 1999 clusters;
merge m:1 dhsidyear using "dtafiles/DHSGPS_matchedwith2004.dta";
drop _merge;

preserve;
use "rawdta/DHS2007/BDIR51DT/BDIR51FL.DTA", clear;

*HW: generating because survey year missing for some reason;
gen year=2007;

ren v001 dhsid07;
ren v002 hhnum;
label variable hhnum "household number within cluster";
label variable dhsid07 "cluster id 2007";

ren v106 educ;
label variable educ "highest level of education";
replace educ=. if educ==9;

ren v743a sayhealth;
label variable sayhealth "who has final say on woman's health care";
replace sayhealth=. if sayhealth==.;

ren v743b sayhhpurchases;
label variable sayhhpurchases "who has final say on large hh purchases";
replace sayhhpurchases=. if sayhhpurchases==9;

ren v743c saydailyneeds;
label variable saydailyneeds "who has final say on daily purchases";
replace saydailyneeds=. if saydailyneeds==9;

ren v743d sayvisits;
label variable sayvisits "who has final say on visits to relatives";
replace sayvisits=. if sayvisits==9;

ren v743e sayfood;
label variable sayfood "who has final say on food to be cooked";
replace sayfood=. if sayfood==9;

keep year hhnum dhsid07 v003 educ sayhealth sayhhpurchases saydailyneeds sayvisits sayfood;

tempfile data2007;
save `data2007', replace;

use "rawdta/DHS2004/BDIR4JDT/BDIR4JFL.DTA", clear;

gen year=2004;

ren v001 dhsid04;
ren v002 hhnum;
label variable hhnum "household number within cluster";
label variable dhsid04 "cluster id 2004";

ren v106 educ;
label variable educ "highest level of education";
replace educ=. if educ==9;

ren v743a sayhealth;
label variable sayhealth "who has final say on woman's health care";
replace sayhealth=. if sayhealth==.;
ren v743b sayhhpurchases;
label variable sayhhpurchases "who has final say on large hh purchases";
replace sayhhpurchases=. if sayhhpurchases==9;
ren v743c saydailyneeds;
label variable saydailyneeds "who has final say on daily purchases";
replace saydailyneeds=. if saydailyneeds==9;
ren v743d sayvisits;
label variable sayvisits "who has final say on visits to relatives";
replace sayvisits=. if sayvisits==9;
ren v743e sayfood;
label variable sayfood "who has final say on food to be cooked";
replace sayfood=. if sayfood==9;

keep year dhsid04 hhnum v003 educ sayhealth sayhhpurchases saydailyneeds sayvisits sayfood;

tempfile data2004;
save `data2004', replace;

use "rawdta/DHS1999/BDIR41DT/BDIR41FL.DTA", clear;

gen year=1999;
ren v001 dhsid99;
ren v002 hhnum;
label variable hhnum "household number within cluster";

ren v106 educ;
label variable educ "highest level of education";
replace educ=. if educ==9;

keep year v003 hhnum dhsid99 educ;

append using `data2004';
append using `data2007';

foreach var in health hhpurchases dailyneeds visits food {;
	gen autonomy_`var'=inlist(say`var',1,2,3) if say`var'!=9 & say`var'!=.;
	gen autonomy_`var'2=inlist(say`var',1)*3+inlist(say`var',2,3)*2+inlist(say`var',4,5)*1
		if say`var'!=9 & say`var'!=.;
	gen autonomy_`var'3=inlist(say`var',1)*1+inlist(say`var',2,3)*.5+inlist(say`var',4,5)*0
		if say`var'!=9 & say`var'!=.;
};

gen double motherid=7*1000000000+dhsid07*1000000+hhnum*1000+v003;
replace motherid=4*1000000000+dhsid04*1000000+hhnum*1000+v003 if year==2004;
replace motherid=9*1000000000+dhsid99*1000000+hhnum*1000+v003 if year==1999;

sort motherid;

keep autonomy_* motherid educ;
format motherid %15.0g;

sort motherid;

tempfile motherdata;
save `motherdata', replace;

restore;

**Generate mother id for later merging in women's data;
gen double motherid=7*1000000000+dhsid07*1000000+v002*1000+v003;
replace motherid=4*1000000000+dhsid04*1000000+v002*1000+v003 if year==2004;
replace motherid=9*1000000000+dhsid99*1000000+v002*1000+v003 if year==1999;

sort motherid;
merge motherid using `motherdata';
drop if _m==2;
drop _m;

gen autonomy=autonomy_health+autonomy_hhpurchases+autonomy_dailyneeds+autonomy_visits+autonomy_food;
gen moreautonomy=autonomy>=3 if autonomy!=.;

gen anyeduc=educ>0 if educ!=.;

**Drop 3 districts where BGS did no testing after confirming that districts 3,46 and 84
**are ones where no cluster has any wells within 5 miles ;

bys district: egen avgtested=mean(numwalkable5);
*label variable distcont "mean of pctcontaminated5 by district";
assert avgtested==0 if inlist(district,3,46,84);
assert avgtested!=0 if !inlist(district,3,46,84);
drop if avgtested==0;
drop avgtested;

label variable dhsidyear "unique year-cluster identifier";

*order variables we'll use;
#delimit ;
order v002 v003 dhsid04 dhsidyear year dhsid04matched district urbanrural urban motherid dhsid2004_year //cluster and survey year identifiers and weights
monthsbreast exclusivebf plainwater stillbreastfeeding exclusivebf6 exclusivebf614 exclusivebf12 monthsbf* //duration of breastfeeding
post2002 fractioncont5 as_walkable5_g numcontaminated5 numcontaminated5_2002 fractioncont5_2002 as_walkable5_g_2002  //contamination and interactions
wfraction_mindistanceC_1m_G wfraction_mindistanceC_1m_G_2002 wfraction_mindistanceC_1m_G_b* fraction_mindistanceC_1m_G fraction_mindistanceC_1m_G_2002 //contamination and interactions
contaminatedorsurface heardofarsenic heardofarsenic_2002 // 2004 switching variables
mean_mindistanceU_G wmean_mindistanceU_G fraction_mindistanceU_1m_G wfraction_mindistanceU_1m_G //clean well access measures
childbyear byear1996 byear1997 byear1998 byear1999 byear2000 byear2001 byear2002 byear2003 byear2004 byear2005 byear2006 byear2007 //birth years
childagewithdied childpotentialage childage childdied malechild ageatdeath //child age and gender 
htasdreal wthtsdreal diarrhea //health outcomes
age mothereducyrs fathereducyrs electricity muslim momwthtsd motherworks anyindivclubs moreautonomy anyeduc
pipedwater tubewell surfacewater villagepipedwater  //demographic variables
caseid v000 //groups
;
gen last=1;
drop v000-last;

saveold "`outdataset'", replace;


