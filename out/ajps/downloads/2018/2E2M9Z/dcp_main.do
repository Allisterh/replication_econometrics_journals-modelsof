* ./dcp_main.do
* Replication script for Distelhorst and Locke. Does Compliance Pay?. AJPS.

* Main analyses
* Called by dcp_rundir.do
* For results, see ./output/

clear 
clear matrix 
clear mata
set maxvar 32000
set matsize 11000
set more off

* File management globals
global RESULTS output
global CSVTOTEX !sed -e 's/ 0\./\./g' -e 's/-0\./-\./g' -e 's/\,/\&/g' -e 's/$/ \\\\/g'

* Main replication data
use ./input/dcp_panel_repl, clear

* Variable globals
global COUNTRIES china india bangladesh vietnam indonesia thailand turkey philippines taiwan cambodia pakistan

global AUDITCATS childlabyr ilabyr forcedlabyr disciplineyr discrimyr healthyr envyr wagesyr hoursyr assocyr legalyr subconyr mgmtyr

global PRODUCTS clothing furniturehomedec toys cookware otherproduct

* Main analysis globals
global DV lestspend_dall
global DV_RAW estspend_dall
global COMP compyr
global PERF ontimeyr inspyr

* In panel models, only include factories with 2+ observations that contain performance data and years containing those data
global MAINIF (factoryobs_perf >=2 &  ontimeyr !=. & inspyr !=.)

* In expanded sample with unit-specific time trends, factories with 2+ observations (no matter how much performance data exists)
global TTIF factoryobs >=2


***********************************************************************
* Table A1: Summary Statistics of Panel

file open myfile using "./$RESULTS/Table_A1_SummaryStats.csv", write replace
file write myfile "Var, Mean, SD, Min, Max" _n  
global STATSIF  $MAINIF & $COMP !=. & $DV != . 
foreach var in $DV $DV_RAW gradeyr $COMP $AUDITCATS $COUNTRIES othercountry $PRODUCTS employeesyr $PERF {
  sum `var' if $STATSIF
  file write myfile "`var',"  %8.2f (r(mean)) "," %8.2f (r(sd)) ","
  file write myfile %8.2f (r(min)) "," %8.2f (r(max)) _n
}
egen factorytag = tag(fcode) if $STATSIF & $COMP !=. & $DV != .
count if factorytag == 1
file write myfile "Total factories, " %8.0f (r(N)) _n
count if $STATSIF & $COMP !=. & $DV != .
file write myfile "Total observations, " %8.0f (r(N)) _n

file close myfile

* Convert CSV to .tex. SPECIAL convert 0 and 1, drop leading 0s
!sed -e 's/1\.00/1/g' -e 's/0\.00/0/g' -e 's/ 0\./\./g' -e 's/\,/\&/g' -e 's/$/ \\\\/g' ./$RESULTS/Table_A1_SummaryStats.csv > ./$RESULTS/Table_A1_SummaryStats.tex


***********************************************************************
* Table 1: Within-2012, naive comparison of compliant and non-compliant
global NAIVE_IF year==2012 & ontimeyr!=. & inspyr != . & employeesyr !=. & $DV !=. & $COMP !=.
file open myfile using "./$RESULTS/Table_1_CrossSectional.csv", write replace
file write myfile "Variable, Compliant, Noncompliant, Difference, SE, pval" _n
foreach dv in $DV_RAW $DV $COUNTRIES othercountry $PRODUCTS employeesyr $PERF {
  di "Testing: `dv'"
  ttest `dv' if $NAIVE_IF, unequal by($COMP)
  file write myfile "`dv', " %8.2f (r(mu_2)) "," %8.2f (r(mu_1)) ","
  file write myfile %8.2f (r(mu_1)-r(mu_2)) "," %8.2f (r(se)) "," %7.3f (r(p)) _n
}
count if $COMP==1 & $NAIVE_IF
file write myfile "Factories," %8.0f (r(N)) "," 
count if $COMP==0 & $NAIVE_IF
file write myfile %8.0f (r(N)) _n
sum $COMP if estspend !=. & year==2012
file write myfile "Share of total," %8.2f (r(mean)) "," %8.2f (1-r(mean)) _n
tab $COMP if estspend !=. & year==2012
file close myfile

$CSVTOTEX ./$RESULTS/Table_1_CrossSectional.csv > ./$RESULTS/Table_1_CrossSectional.tex


***********************************************************************
* Appendix Table A3: OLS cross-sectional model
reg $DV $COMP $COUNTRIES $PRODUCTS employeesyr $PERF if year==2012, robust
outreg2 using ./$RESULTS/Table_A3_CrossSectional.tex, tex replace dec(3)
reg $DV_RAW $COMP $COUNTRIES $PRODUCTS employeesyr $PERF if year==2012, robust
outreg2


***********************************************************************
* Table A2: Purchasing by country in World Justice Project data
* Save "bookmark"
save int/temp.dta, replace

* Sourcing agent total spend by country of factory
sort s_country
by s_country: egen countryspend = sum(estspend_dall)

* Spend in full data
egen totalspend = sum(estspend_dall)

* Merge World Justice Project country ratings
merge m:1 s_country using ./input/wjpsample.dta

* Keep one observation per country in WJP data
egen countryflattener  = tag(s_country) if wjplabor!=.
keep if countryflattener==1
drop countryflattener

* Make quartiles of the WJP ratings
egen wjptile_labor = cut(wjplabor), group(4) 
egen wjptile_assoc = cut(wjpassoc), group(4) 

* Sum spending within each WJP quartile
sort wjptile_labor
by wjptile_labor: egen spendbywjp_labor = sum(countryspend)
sort wjptile_assoc
by wjptile_assoc: egen spendbywjp_assoc = sum(countryspend)

* Country percentage of total spend
gen countryspendpct = countryspend/totalspend

* WJP quartile percentage of total spend
gen spendbywjp_labor_pct = 100*spendbywjp_labor / totalspend
gen spendbywjp_assoc_pct = 100*spendbywjp_assoc / totalspend

* These figures go into Figure 3 -- see R graphics script
tabstat spendbywjp_labor_pct, by(wjptile_labor) stat(mean n)
tabstat spendbywjp_assoc_pct, by(wjptile_assoc) stat(mean n)

* Adjust units for table
gen countryspend_m = countryspend / 1000
replace countryspendpct = 100 * countryspendpct

* Write Table A2 (left panel and right panel separately)

* Too many countries to display. Set minimum spend cutoff in million USD.
global MINVALUE 1

gsort -wjptile_labor s_country
outsheet wjptile_labor spendbywjp_labor_pct s_country countryspend_m countryspendpct if countryspend_m >= $MINVALUE & countryspend !=. using ./$RESULTS/Table_A2_LeftPanel.csv, comma replace
gsort -wjptile_assoc s_country
outsheet wjptile_assoc  spendbywjp_assoc_pct s_country countryspend_m countryspendpct if countryspend_m >= $MINVALUE  & countryspend !=.  using ./$RESULTS/Table_A2_RightPanel.csv, comma replace


* Restore dataset from "bookmark"
use int/temp.dta, clear

***********************************************************************
* TABLE 2: MAIN D-in-D effects on compliance 
* Note: Rightmost panel with unit time-trends generated in dcp_tt.do

* Mark "switchers" - factories whose compliance status changes over 2009-2012
sort fcode year
by fcode: egen compliantmax = max($COMP)
by fcode: egen compliantmin = min($COMP)
gen switcher = 0
replace switcher = 1 if compliantmin != compliantmax

xtreg $DV $COMP i.year if $MAINIF, fe cluster(fcode)
*outreg2 using ./$RESULTS/Table_2_Main.xls, excel replace dec(3)
outreg2 using ./$RESULTS/Table_2_Main.tex, tex replace dec(3)
xtreg $DV $COMP $PERF i.year if $MAINIF, fe cluster(fcode)
outreg2
xtreg $DV gradeyr i.year if $MAINIF, fe cluster(fcode)
outreg2
xtreg $DV gradeyr $PERF i.year if $MAINIF, fe cluster(fcode)
outreg2
xtreg $DV $COMP i.year if $MAINIF & switcher==1, fe cluster(fcode)
outreg2
xtreg $DV $COMP $PERF i.year if $MAINIF & switcher==1, fe cluster(fcode)
outreg2
xtreg $DV gradeyr i.year if $MAINIF & switcher==1, fe cluster(fcode)
outreg2
xtreg $DV gradeyr $PERF i.year if $MAINIF & switcher==1, fe cluster(fcode)
outreg2

!sed -e 's/ 0\./\./g' -e 's/-0\./-\./g' -e 's/(0\./(\./g' -i "" $RESULTS/Table_2_Main.tex 


***********************************************************************
* Table A12: HTE by length of sourcing relationship

* 2008 breaks factories into two roughly equal groups
count if sinceyr <= 2008 & sinceyr!=. & year==2012
count if sinceyr > 2008 & sinceyr!=. & year==2012

gen longrel = .
replace longrel = 0 if sinceyr >= 2009 & sinceyr != .
replace longrel = 1 if sinceyr <= 2008 & sinceyr != .

xtreg $DV  longrel#c.$COMP $PERF i.year if $MAINIF, fe cluster(fcode)
*outreg2 using ./$RESULTS/HTE_longrel.xls, excel replace dec(3)
outreg2 using ./$RESULTS/Table_A12_Relationship.tex, tex replace dec(3)
xtreg $DV longrel#c.gradeyr $PERF i.year if $MAINIF, fe cluster(fcode)
outreg2
xtreg $DV  longrel#c.$COMP $PERF i.year if $MAINIF & switcher==1, fe cluster(fcode)
outreg2
xtreg $DV longrel#c.gradeyr $PERF i.year if $MAINIF & switcher==1, fe cluster(fcode)
outreg2

!sed -e 's/ 0\./\./g' -e 's/-0\./-\./g' -e 's/(0\./(\./g' -i "" $RESULTS/Table_A12_Relationship.tex 

* Is the difference significant?
xtreg $DV  longrel#c.$COMP $PERF i.year if $MAINIF, fe cluster(fcode)
test 0.longrel#c.$COMP = 1.longrel#c.$COMP 

***********************************************************************
* TABLE A4: Robustness, 
* Non-linear performance controls, industry trends, length of relationship,
* Years of sourcing relationship
gen relyrs = year-sinceyr
gen relyrs2 = relyrs^2

* More flexible performance controls  
gen inspyr2 = inspyr^2
gen ontimeyr2 = ontimeyr^2

* Industry-specific time trends
sort fcode year
by fcode: egen trendvar = seq()
global TRENDVARS c.clothing#c.trendvar c.furniturehomedec#c.trendvar c.toys#c.trendvar c.cookware#c.trendvar c.otherproduct#c.trendvar

xtreg $DV $COMP  ontimeyr ontimeyr2 inspyr inspyr2 i.year if $MAINIF, fe cluster(fcode)
outreg2 using ./$RESULTS/Table_A4_Robustness.tex, tex replace dec(3)
xtreg $DV gradeyr  ontimeyr ontimeyr2 inspyr inspyr2 i.year if $MAINIF, fe cluster(fcode)
outreg2
* Industry trends
xtreg $DV $COMP  ontimeyr ontimeyr2 inspyr inspyr2 $TRENDVARS i.year if $MAINIF, fe cluster(fcode)
outreg2
xtreg $DV gradeyr  ontimeyr ontimeyr2 inspyr inspyr2 $TRENDVARS i.year if $MAINIF, fe cluster(fcode)
outreg2
* Relationship length
xtreg $DV $COMP  ontimeyr ontimeyr2 inspyr inspyr2 $TRENDVARS  relyrs relyrs2 i.year if $MAINIF, fe cluster(fcode)
outreg2
xtreg $DV gradeyr  ontimeyr ontimeyr2 inspyr inspyr2 $TRENDVARS relyrs relyrs2 i.year if $MAINIF, fe cluster(fcode)
outreg2

!sed -e 's/ 0\./\./g' -e 's/-0\./-\./g' -e 's/(0\./(\./g' -i "" $RESULTS/Table_A4_Robustness.tex 


***********************************************************************
* Table A6, A7 and Figures 4, 5: Entropy balancing estimates

* DV Pre-trend
sort fcode year
gen lestspend_diff = lestspend_dall - lestspend_dall[_n-1] if fcode==fcode[_n-1]
replace lestspend_diff = 0 if lestspend_dall !=. & year==2009

file open myfile using "$RESULTS/Entropy_balancing.csv", write replace
file write myfile "DV, De-meaned, Ebal, Factories, Startyear, Group, Year, Mean, SE, LL, UL" _n
xtreg lestspend_dall, fe cluster(fcode)
*outreg2 using "$RESULTS/Table_A7_EbalRegs.xls", excel replace
outreg2 using "$RESULTS/Table_A7_EbalRegs.tex", tex replace

foreach yr in 2009 2010 2011 {
    
	* mark the relevant observations in yr and nextyr
	local nextyr = `yr' + 1
	di "Nextyr = `nextyr'"
	global RESTRICTION (year==`yr' | year==`nextyr') & $COMP != . & $DV != .
	by fcode: egen mini`yr' = count(year) if $RESTRICTION 
	
	gen temp = $COMP if $RESTRICTION & mini`yr'==2 & year==`yr' & lestspend_diff !=.
	by fcode: egen comp`yr' = mode(temp)
	gen temp2 = $COMP if $RESTRICTION & mini`yr'==2 & year==`yr'+1 & lestspend_diff[_n-1] != .
	by fcode: egen comp`nextyr' = mode(temp2)
	drop temp*

	* Set four groups
	* comp`yr' and comp`nextyr' only have values for the years studied
	global CC comp`yr'==1 & comp`nextyr'==1
	global NN comp`yr'==0 & comp`nextyr'==0
	global NC comp`yr'==0 & comp`nextyr'==1
	global CN comp`yr'==1 & comp`nextyr'==0
    
	* set entropy balancing weights
	* No pretrends available in 2009
	if (`yr'==2009) {
		ebalance comp`nextyr' $DV $COUNTRIES $PRODUCTS if comp`yr'==1 ///
		& mini`yr'==2 & year==`yr', targets(2) gen(temp1) ///
		keep("$RESULTS/Table_A6_`yr'_leftpanel") replace

		ebalance comp`nextyr' $DV $COUNTRIES $PRODUCTS if comp`yr'==0 ///
		& mini`yr'==2 & year==`yr', targets(2) gen(temp0) /// 
		keep("./$RESULTS/Table_A6_`yr'_rightpanel") replace
	}
	* Include pretrends for 2010 and 2011 panels
	else {
		ebalance comp`nextyr' $DV lestspend_diff $COUNTRIES $PRODUCTS ///
		if comp`yr'==1 & mini`yr'==2 & year==`yr', targets(2) gen(temp1) ///
		keep("$RESULTS/Table_A6_`yr'_leftpanel") replace	
		
		ebalance comp`nextyr' $DV lestspend_diff $COUNTRIES $PRODUCTS ///
		if comp`yr'==0 & mini`yr'==2 & year==`yr', targets(2) gen(temp0) ///
		keep("./$RESULTS/Table_A6_`yr'_rightpanel") replace
	}
	* Populate the weights throughout each factory within the mini-panel
    by fcode: egen wt1_`yr' = mode(temp1) if mini`yr'==2	
    by fcode: egen wt0_`yr' = mode(temp0) if mini`yr'==2

	* Combine the weights for the final anlaysis including both improvers and decliners
	gen wt_`yr' = wt0_`yr'
	replace wt_`yr' = wt1_`yr' if wt_`yr'==.
	drop temp* wt0* wt1*

	* Regressions: raw results, improvers balanced, decliners balanced, combined balanced
	xtreg $DV $COMP i.year if mini`yr'==2, fe cluster(fcode)
    outreg2
    xtreg $DV $COMP i.year if mini`yr'==2 & (($NC) | ($NN)) [aweight=wt_`yr'], fe cluster(fcode)
	outreg2
    xtreg $DV $COMP i.year if mini`yr'==2 & (($CN) | ($CC)) [aweight=wt_`yr'], fe cluster(fcode)
	outreg2
    xtreg $DV $COMP i.year if mini`yr'==2 & (($CN) | ($CC) | ($NC) | ($NN)) [aweight=wt_`yr'], fe cluster(fcode)
	outreg2
	
	
	* Generate data for Figures 4 and 5
	gen tr`yr' = .
	replace tr`yr' = 0 if year==`yr' & mini`yr'==2
	replace tr`yr' = 1 if year==`nextyr' & mini`yr'==2
	tab tr`yr'

	foreach rest in CC NN NC CN {
	  di "Testing `rest'"
	  *ttest $DV if $`rest', by(tr) 

	  foreach switch in 0 1 {
		  
		  * Pre-entropy balancing differences
		  mean $DV if $`rest' & tr`yr'==`switch' 
		  mat B = r(table)
		  ** [1,1] = mean, [2,1] = se, [5,1] = ll, [6,1] = ul
		  file write myfile "$DV,No,un," %5.0f (e(N)) ",`yr',`rest',`switch',"
		  file write myfile %9.3f (B[1,1]) "," %9.3f (B[2,1]) ","
		  file write myfile %9.3f (B[5,1]) "," %9.3f (B[6,1]) _n
		
		  ** De-mean by year
		  egen yearavg`switch' = mean($DV) if tr`yr'==`switch' & (($CN) | ($CC) | ($NC) | ($NN))
		  gen demeaned_$DV_`switch' = ($DV - yearavg`switch') if tr`yr'==`switch' & $`rest' 
		  
		  mean demeaned_$DV_`switch' if $`rest' & tr`yr'==`switch' 
		  mat B = r(table)
		  ** [1,1] = mean, [2,1] = se, [5,1] = ll, [6,1] = ul
		  file write myfile "$DV,Yes,un," %5.0f (e(N)) ",`yr',`rest',`switch',"
		  file write myfile %9.3f (B[1,1]) "," %9.3f (B[2,1]) ","
		  file write myfile %9.3f (B[5,1]) "," %9.3f (B[6,1]) _n

		  
		  * Post-entropy balancing differences
   	      mean $DV if $`rest' & tr`yr'==`switch'  [aweight=wt_`yr']  
		  mat B = r(table)
		  ** [1,1] = mean, [2,1] = se, [5,1] = ll, [6,1] = ul
		  file write myfile "$DV,No,ebal," %5.0f (e(N)) ",`yr',`rest',`switch',"
		  file write myfile %9.3f (B[1,1]) "," %9.3f (B[2,1]) ","
		  file write myfile %9.3f (B[5,1]) "," %9.3f (B[6,1]) _n

		  mean demeaned_$DV_`switch' if $`rest' & tr`yr'==`switch'  [aweight=wt_`yr']
		  mat B = r(table)
		  ** [1,1] = mean, [2,1] = se, [5,1] = ll, [6,1] = ul
		  file write myfile "$DV,Yes,ebal," %5.0f (e(N)) ",`yr',`rest',`switch',"
		  file write myfile %9.3f (B[1,1]) "," %9.3f (B[2,1]) ","
		  file write myfile %9.3f (B[5,1]) "," %9.3f (B[6,1]) _n
		  
		  drop yearavg* 
		  drop demeaned_*
	  }
	}
	drop comp20*
	drop wt*

}
drop mini20*  
drop tr20* 

file close myfile
* End: Entropy balancing analysis


***********************************************************************
* Table 4: Heterogeneous effects by exporter industry

global IxCOMP c.clothing#c.$COMP c.furniturehomedec#c.$COMP c.toys#c.$COMP c.cookware#c.$COMP c.otherproduct#c.$COMP

global IxGRADE c.clothing#c.gradeyr c.furniturehomedec#c.gradeyr c.toys#c.gradeyr c.cookware#c.gradeyr c.otherproduct#c.gradeyr

xtreg $DV $IxCOMP $PERF i.year if $MAINIF,  cluster(fcode) fe 
outreg2 using ./$RESULTS/Table_4_Industry.tex, tex replace dec(3)
xtreg $DV $IxGRADE $PERF i.year if $MAINIF,  cluster(fcode) fe 
outreg2
xtreg $DV $IxCOMP $PERF i.year if $MAINIF & switcher==1,  cluster(fcode) fe 
outreg2
xtreg $DV $IxGRADE $PERF i.year if $MAINIF  & switcher==1,  cluster(fcode) fe 
outreg2

!sed -e 's/ 0\./\./g' -e 's/-0\./-\./g' -e 's/(0\./(\./g' -i "" $RESULTS/Table_4_Industry.tex 

***********************************************************************
* Table A9.  Effects in full sample, China alone, and elsewhere

xtreg $DV $COMP $PERF i.year if $MAINIF,  cluster(fcode) fe 
outreg2 using ./$RESULTS/Table_A9_China.tex, tex replace dec(3)
xtreg $DV gradeyr $PERF i.year if $MAINIF,  cluster(fcode) fe 
outreg2
xtreg $DV $COMP $PERF i.year if $MAINIF & s_country=="CHINA",  cluster(fcode) fe 
outreg2
xtreg $DV gradeyr $PERF i.year if $MAINIF & s_country=="CHINA",  cluster(fcode) fe 
outreg2
xtreg $DV $COMP $PERF i.year if $MAINIF & s_country!="CHINA",  cluster(fcode) fe 
outreg2
xtreg $DV gradeyr $PERF i.year if $MAINIF & s_country!="CHINA",  cluster(fcode) fe 
outreg2

!sed -e 's/ 0\./\./g' -e 's/-0\./-\./g' -e 's/(0\./(\./g' -i "" $RESULTS/Table_A9_China.tex 

***********************************************************************
* Table A10: Heterogeneous effects by factory size
sort fcode
by fcode: egen avgempl = mean(employeesyr) if $MAINIF 
by fcode: egen temp = mode(avgempl)
replace avgempl = temp
drop temp
egen facsize2 = cut(avgempl), group(2)

* Characteristics of factory pools
tabstat avgempl, by(facsize2) stat(max min mean median n)

xtreg $DV facsize2#c.$COMP i.year if $MAINIF, fe cluster(fcode)
outreg2 using ./$RESULTS/Table_A10_Facsize.tex, tex replace dec(3)
xtreg $DV facsize2#c.$COMP $PERF i.year if $MAINIF, fe cluster(fcode)
outreg2
xtreg $DV facsize2#c.$COMP i.year if $MAINIF & switcher==1, fe cluster(fcode)
outreg2
xtreg $DV facsize2#c.$COMP $PERF i.year if $MAINIF & switcher==1, fe cluster(fcode)
outreg2

tabstat avgempl if year==2012, by(facsize2) stat(mean n min max)
tabstat $DV_RAW, by(facsize2)

***********************************************************************
* Table A8: Effects of individual audit items (see also Figure A1)
* Which dimensions of compliance pay-off?

* Analyze if no missing data for all 13 categories
gen allcatsvalid=.
replace allcatsvalid = 1 if healthyr!=. & envyr !=. & wagesyr !=. & hoursyr !=. & legalyr!=. & mgmtyr !=. & childlabyr!=. & ilabyr!=. &  forcedlabyr!=. & disciplineyr!=. & discrimyr!=. & assocyr!=. & subconyr!=. & $COMP != . & $DV != .

sort fcode 
by fcode: egen validcatsobs = count(allcatsvalid)
global MAINIF_CAT validcatsobs >=2 & ontimeyr != . & inspyr!=. & $MAINIF

xtreg $DV $AUDITCATS i.year if $MAINIF_CAT, fe cluster(fcode)
outreg2 using ./$RESULTS/Table_A8_AuditItems.tex, tex replace dec(2)
xtreg $DV $AUDITCATS $PERF i.year if $MAINIF_CAT, fe cluster(fcode)
outreg2


***********************************************************************
* Table A5: Effects at each spend cutpoint in linear probability models
* The data provided were binned above/below the following breakpoints (thou USD)
global CUTS 1 50 100 250 500 750 1000 5000 10000 20000 30000 40000
foreach cut in $CUTS {
  gen spendbin`cut' = .
  replace spendbin`cut' = 0 if estspend < `cut' & estspend !=.
  replace spendbin`cut' = 1 if estspend >= `cut' & estspend !=.
}

global CUTS_SM 50 100 250 500 750 1000 5000 10000 
xtreg spendbin1 $COMP $PERF i.year if $MAINIF, fe cl(fcode)
outreg2 using $RESULTS/Table_A5_Thresholds.tex, excel replace dec(3)
foreach cut in $CUTS_SM {
  xtreg spendbin`cut' $COMP $PERF i.year if $MAINIF, fe cl(fcode)
  outreg2
}

!sed -e 's/ 0\./\./g' -e 's/-0\./-\./g' -e 's/(0\./(\./g' -i "" $RESULTS/Table_A5_Thresholds.tex 


***********************************************************************
* Table (not reported): Replicate results using topcoding at 1m spend

* Review the bins
tab estspend if year==2012

xtreg lestspend_tc1m_dall $COMP i.year if $MAINIF, fe cluster(fcode)
outreg2 using ./$RESULTS/Table_Topcoded_DV.tex, tex replace dec(3)
xtreg lestspend_tc1m_dall $COMP $PERF i.year if $MAINIF, fe cluster(fcode)
outreg2
xtreg lestspend_tc1m_dall gradeyr i.year if $MAINIF, fe cluster(fcode)
outreg2
xtreg lestspend_tc1m_dall gradeyr $PERF i.year if $MAINIF, fe cluster(fcode)
outreg2
xtreg lestspend_tc1m_dall $COMP i.year if $MAINIF & switcher==1, fe cluster(fcode)
outreg2
xtreg lestspend_tc1m_dall $COMP $PERF i.year if $MAINIF & switcher==1, fe cluster(fcode)
outreg2
xtreg lestspend_tc1m_dall gradeyr i.year if $MAINIF & switcher==1, fe cluster(fcode)
outreg2
xtreg lestspend_tc1m_dall gradeyr $PERF i.year if $MAINIF & switcher==1, fe cluster(fcode)
outreg2


* THIS TEMP FILE USED FOR BOOTSTRAPS and TIME TRENDS
save ./int/data_postmain.dta, replace

* Clean the .txt files from output directory
cd output
!rm *.txt
cd ..



