clear
set more off
#delimit ;
/*****************************************************************************************************************;
**This dofile starts from expandedDHSGPS_Mergedallyears and generates expandedDHSGPS_mergedrecoded;

*****************************************************************************************************************/;

*****************************************************************************************************************;
*Paths;
*****************************************************************************************************************;

*access files in subdirectory generated by data creating dofiles;
local indataset2004 "dtafiles/expandedDHSGPS_Mergedhh2004.dta";
local indataset2007 "dtafiles/expandedDHSGPS_Mergedhh2007.dta";
local indataset1999 "dtafiles/expandedDHSGPS_Mergedhh1999.dta";

local outdataset "dtafiles/expandedDHSGPS_mergedrecoded.dta";

*****************************************************************************************************************;
*Main;
*****************************************************************************************************************;

use "`indataset2004'";
append using "`indataset2007'";

append using "`indataset1999'";

**HW: Renaming, recoding and generating variables**;
ren v714 motherworks;
replace motherworks=. if motherworks==9;
ren v715 fathereducyrs;
replace fathereducyrs=. if fathereduc==98|fathereduc==99;
ren v133 mothereducyrs;
replace mothereducyrs=. if mothereducyrs==99;

ren v119 electricity;
replace electricity=. if electricity==7;

ren v012 age;

ren v130 religion;
gen muslim=1 if religion==1;
replace muslim=0 if muslim==. & !inlist(religion,99,.);
drop religion;

ren v025 urbanrural;
label variable urbanrural "cluster in urban or rural area";
gen urban=1 if urbanrural==1;
label variable urban "dummy variable for in an urban area";
replace urban=0 if urbanrural==2;

gen childdied=1 if b5==0;
replace childdied=0 if childdied==.;

gen stillbreastfeeding=1 if durationbreast==95;
replace stillbreastfeeding=0 if stillbreastfeeding==. & !inlist(durationbreast,.,99,98);
replace stillbreastfeeding=. if childdied==1;

replace monthsbreast=0 if monthsbreast==94;
replace monthsbreast=. if monthsbreast==99;
replace monthsbreast=. if monthsbreast==97;
replace monthsbreast=. if monthsbreast==98;

**HW: Age of child's death**;
gen ageatdeath=b6-100;
replace ageatdeath=ageatdeath/30; 
gen ageatdeathmonths=b6-200;
replace ageatdeath=ageatdeathmonths if ageatdeathmonths>0;
gen ageatdeathyears=b6-300;
replace ageatdeathyears=ageatdeathyears*12;
replace ageatdeath=ageatdeathyears if ageatdeathyears>0;
drop ageatdeathmonths;
drop ageatdeathyears;

**HW: Birth year is coded differently in 1999 file, change format to match 2004 and 2007**;
replace childbyear=1994 if childbyear==94;
replace childbyear=1995 if childbyear==95;
replace childbyear=1996 if childbyear==96;
replace childbyear=1997 if childbyear==97;
replace childbyear=1998 if childbyear==98;
replace childbyear=1999 if childbyear==99;
replace childbyear=2000 if childbyear==0;

**GKS: for some reason some ages are missing, so reset using month of survey and month of birth;
gen childpotentialage=(year-childbyear)*12+(v006-b1);
replace childpotentialage=(year+1-childbyear)*12+(v006-b1) if v007==0;

replace childage=childpotentialage if childage==.;

gen childagewithdied=childage;
replace childagewithdied=ageatdeath if childdied==1;

**HW: Cleaning variables for other liquids given to children;
replace plainwater=. if plainwater==8|plainwater==9;
replace babyformula=. if babyformula==8|babyformula==9;
replace otherliq=. if otherliq==8|otherliq==9;
replace sugarwater=. if sugarwater==8|sugarwater==9;
replace cowgoat=. if cowgoat==8|cowgoat==9;

** GKS: Fix 2004 plain water - otherliq variables since yesterday only asked if given in 7 days is a yes;
replace plainwater=0 if s449a==0 & year==2004;
replace sugarwater=0 if s449b==0 & year==2004;
replace babyformula=0 if s449c==0 & year==2004;
replace cowgoat=0 if s449d==0 & year==2004;
replace otherliq=0 if s449e==0 & year==2004;

gen exclusivebf=1 if plainwater==0 & babyformula==0 & otherliq==0 & sugarwater==0 & cowgoat==0 & stillbreastfeeding==1 ;
replace exclusivebf=0 if exclusivebf==. & stillbreastfeeding==1;
replace exclusivebf=. if plainwater==. | babyformula==. | otherliq==. | sugarwater==. | cowgoat==.;
replace exclusivebf=. if childdied==1;

label variable exclusivebf "child is exclusively breastfeeding";
label variable stillbreastfeeding "child is currently breastfeeding";

**GKS: water source variable is coded differently in each year;
gen pipedwater=1 if watersource==10|watersource==11|watersource==12;
replace pipedwater=0 if pipedwater==. & !inlist(watersource,97,98,99,.);

gen tubewell=1 if year==1999 & inlist(watersource,20,21);
replace tubewell=1 if year==2004 & inlist(watersource,20,21,22,23,30);
replace tubewell=1 if year==2007 & inlist(watersource,20,21);
replace tubewell=0 if tubewell==. & !inlist(watersource,97,98,99,.);

gen surfacewater=1 if year==1999 & inlist(watersource,30,31,32);
replace surfacewater=1 if year==2004 & inlist(watersource,40,41,42);
replace surfacewater=1 if year==2007 & inlist(watersource,40,41,42,43);
replace surfacewater=0 if surfacewater==. & !inlist(watersource,97,98,99,.);

gen malechild=1 if b4==1;
replace malechild=0 if malechild==.;

**HW: cleaning health outcome variables**;
replace htasd=. if htasd==9999|htasd==9998;
gen htasdreal=htasd/100;
label variable htasdreal "z-score height for age";

replace wthtsd=. if wthtsd==9999|wthtsd==9998;
gen wthtsdreal=wthtsd/100;
label variable wthtsdreal "z-score weight for height";

replace diarrhea=. if inlist(diarrhea,8,9);
replace diarrhea=1 if diarrhea==2;

label variable childage "age of child in months";
label variable childagewithdied "age of child in months with age at death if child died";
label variable childdied "dummy variable for child died";

label variable age "mother's current age";
label variable mothereducyrs "mother's education in years";
label variable muslim "dummy for respondent is muslim";
label variable motherworks "mother currently working outside the home";

label variable pipedwater "dummy for household's primary water source is piped water";
label variable tubewell "dummy for household's primary water source is tubewell";
label variable surfacewater "dummy for household's primary water source is surface water";

gen momwthtsd=v444a;
replace momwthtsd=. if momwthtsd==9998|momwthtsd==9999;
replace momwthtsd=momwthtsd/100;
label variable momwthtsd "Mother's weight for height z-score";

gen exclusivebf6=exclusivebf if childagewithdied<6 & exclusivebf!=.;
gen exclusivebf614=exclusivebf if childagewithdied>=6 & childagewithdied<=14 & exclusivebf!=.;
gen exclusivebf12=exclusivebf if childagewithdied>12 & exclusivebf!=.;
gen monthsbf6=1 if monthsbreast>=6 & childagewithdied>=6 & monthsbreast!=.;
replace monthsbf6=0 if monthsbreast<6 & childagewithdied>=6 & monthsbreast!=.;
gen monthsbf12=1 if monthsbreast>=12 & childagewithdied>=12 & monthsbreast!=.;
replace monthsbf12=0 if monthsbreast<12 & childagewithdied>=12 & monthsbreast!=.;
gen monthsbf18=1 if monthsbreast>=18 & childagewithdied>=18 & monthsbreast!=. ;
replace monthsbf18=0 if monthsbreast<18 & childagewithdied>=18 & monthsbreast!=. ;
gen monthsbf24=1 if monthsbreast>=24 & childagewithdied>=24 & monthsbreast!=.;
replace monthsbf24=0 if monthsbreast<24 & childagewithdied>=24 & monthsbreast!=.;
gen monthsbf36=1 if monthsbreast>=36 & childagewithdied>=36 & monthsbreast!=. ;
replace monthsbf36=0 if monthsbreast<36 & childagewithdied>=36 & monthsbreast!=. ;

#delimit ;
foreach varname of varlist s116* s118*{;
	replace `varname'=0 if `varname'==2;
	replace `varname'=. if `varname'==9;
};
**1999 doesn't ask about Asha or Proshika
**2004 has no one belonging to 'other organizations' and doesn't ask about Proshika;
**So to be consistent, only include Grameen Bank, BRAC, BRDB and Mother's Clubs;
egen indivclubs=rsum(s116a s118a s116b s118b s116e s118c s116f s118d);
gen anyindivclubs=indivclubs>0 if indivclubs!=.;

**HW: generates dummy variables for birthyear**;
tab childbyear, gen(childbyeardum);

ren childbyeardum2 byear1995;
ren childbyeardum3 byear1996;
ren childbyeardum4 byear1997;
ren childbyeardum5 byear1998;
ren childbyeardum6 byear1999;
ren childbyeardum7 byear2000;
ren childbyeardum8 byear2001;
ren childbyeardum9 byear2002;
ren childbyeardum10 byear2003;
ren childbyeardum11 byear2004;
ren childbyeardum12 byear2005;
ren childbyeardum13 byear2006;
ren childbyeardum14 byear2007;

**GKS: dropped because very very few observations relative to other years;
drop if childbyear==1994;
assert childbyeardum1==0;
drop childbyeardum1;

**Generate some more treatment variables;
gen post2002=childbyear>=2002;

cap gen fractioncont5=pctcontaminated5/100;
cap gen as_walkable5_g=as_walkable5/1000;

foreach measure in "fractioncont5" "as_walkable5_g" "numcontaminated5" {; 
	gen `measure'_2002=`measure'*post2002;
};

label variable as_walkable5_g_2002 "interaction of post-campaign and avg As in g in 5 mi";
label variable numcontaminated5_2002 "interaction of post-campaign and number of contaminated wells in 5 mi";

label variable post2002 "dummy born in 2002 or after";
label variable byear1995 "dummy for birth year 1995";
label variable byear1996 "dummy for birth year 1996";
label variable byear1997 "dummy for birth year 1997";
label variable byear1998 "dummy for birth year 1998";
label variable byear1999 "dummy for birth year 1999";
label variable byear2000 "dummy for birth year 2000";
label variable byear2001 "dummy for birth year 2001";
label variable byear2002 "dummy for birth year 2002";
label variable byear2003 "dummy for birth year 2003";
label variable byear2004 "dummy for birth year 2004";
label variable byear2005 "dummy for birth year 2005";
label variable byear2006 "dummy for birth year 2006";
label variable byear2007 "dummy for birth year 2007";
label variable year "survey year";
label variable pipedwater "household water source is piped water";
label variable malechild "dummy for child is male";

**HW: Creates a unique identifier for clusters to use for fixed effects**;
gen dhsidyear=year*1000+dhsid07;
replace dhsidyear=year*1000+dhsid04 if year==2004;
replace dhsidyear=year*1000+dhsid99 if year==1999;

**HW: Unique HH identifier**;
gen yr2=4 if year==2004;
replace yr2=7 if year==2007;
replace yr2=9 if year==1999;
gen hhid=yr2*1000000+dhsid07*1000+v002;
replace hhid=yr2*1000000+dhsid04*1000+v002 if year==2004;
replace hhid=yr2*1000000+dhsid99*1000+v002 if year==1999;
drop yr2;

*drop extra variables;
#delimit ;
aorder;
drop awfacte-b16 bidx bord h0- h46b hidx htasd hw2- m73 midx- ml101 ml101 s46g1d- snumdv sy506d v3a00a- v828; 

save "`outdataset'", replace;




