* ./dcp_bootstraps.do
* Replication script for Distelhorst and Locke. Does Compliance Pay?. AJPS.

* bootstrap estimates of effect magnitudes
* precursors: dcp_main.do --> ./int/data_postmain.dta and sets globals
* called by ./rundir.do

clear
clear matrix 
clear mata
set maxvar 32000
set matsize 11000
set more off

global RESULTS output

* Number of bootstrap resamples (BLOOPS) 
* Paper reports BLOOPS=1000 with following randomization seed
global BLOOPS 1000
local randomseed =  date("12/29/2017", "MDY", 2020)
set seed `randomseed'

***********************************************************************
* Table 3: Main effects magnitudes
clear
use ./int/data_postmain.dta

* Save reduced dataset, estimation sample only
keep fcode year gradeyr $COMP $DV $DV_RAW $PERF factoryobs* switcher 
keep if $MAINIF
save ./int/temp_bstrap.dta, replace

* holder matrices
matrix EFF_COMP = [.]
matrix EFF_COMP_PCT = [.]
matrix EFF_COMP_PERF = [.]
matrix EFF_COMP_PERF_PCT = [.]
matrix EFF_COMP_SWITCH = [.]
matrix EFF_COMP_SWITCH_PCT = [.]
matrix EFF_COMP_PERF_SWITCH = [.]
matrix EFF_COMP_PERF_SWITCH_PCT = [.]

global PREDICTIF $MAINIF & $DV!=. & $COMP !=. 

forvalues i=1/$BLOOPS {
  di "Main: Bootstrap `i'"
  * this samples by factory, not individual observations
  bsample, cluster(fcode)

  * relabel the factory codes, to make each unique
  qui gen s_fcode = string(fcode)
  sort s_fcode year
  qui by s_fcode year: egen series = seq()
  qui gen s_fcode2=s_fcode + string(series)
  qui encode s_fcode2, gen(fcode2)
  qui xtset fcode2 year

  * back up the explanatory variable
  qui gen comp_orig = $COMP
  
  *** 1. estimate on bootstrap sample: NO performance covars
  qui xtreg $DV $COMP i.year if $MAINIF, fe cluster(fcode)
  
  * calculate point estimate of average effect
  qui replace $COMP=0 if $PREDICTIF
  qui predict lestspend_C if $PREDICTIF, xb
  qui replace $COMP=1  if $PREDICTIF
  qui predict lestspend_A if $PREDICTIF, xb
  qui gen diffspend = exp(lestspend_A) - exp(lestspend_C)
  qui sum diffspend
  qui replace $COMP = comp_orig
  
  * store dollar total to matrix
  local diff = r(mean)
  matrix B = [`diff']
  matrix EFF_COMP = B , EFF_COMP
  
  * calculate and store pct to matrix
  qui sum $DV_RAW if $PREDICTIF  & $COMP==0
  local meanspend = r(mean)
  matrix B = [`diff'/`meanspend']
  matrix EFF_COMP_PCT = B , EFF_COMP_PCT
    
  * reset vars for next round
  drop lestspend_A lestspend_C diffspend 
  qui replace $COMP = comp_orig

  *** 2. estimate on bootstrap sample: YES performance covars
  qui xtreg $DV $COMP $PERF i.year if $MAINIF, fe cluster(fcode)

  * calculate point estimate of average effect
  qui replace $COMP=0 if $PREDICTIF
  qui predict lestspend_C if $PREDICTIF, xb
  qui replace $COMP=1  if $PREDICTIF
  qui predict lestspend_A if $PREDICTIF, xb
  qui gen diffspend = exp(lestspend_A) - exp(lestspend_C)
  qui sum diffspend
  qui replace $COMP = comp_orig

  * store to matrix
  local diff = r(mean)
  matrix B = [`diff']
  matrix EFF_COMP_PERF = B , EFF_COMP_PERF
  
  * calculate and store pct to matrix
  qui sum $DV_RAW if $PREDICTIF & $COMP==0
  local meanspend = r(mean)
  matrix B = [`diff'/`meanspend']
  matrix EFF_COMP_PERF_PCT = B , EFF_COMP_PERF_PCT
  
  * reset vars
  drop lestspend_A lestspend_C diffspend  
  qui replace $COMP = comp_orig
  
  *** 3. estimate on bootstrap sample: NO covars, switchers only
  clear
  use ./int/temp_bstrap
  bsample if switcher==1, cluster(fcode)

  * relabel the factory codees
  qui gen s_fcode = string(fcode)
  sort s_fcode year
  qui by s_fcode year: egen series = seq()
  qui gen s_fcode2=s_fcode + string(series)
  qui encode s_fcode2, gen(fcode2)
  qui xtset fcode2 year

  * backup the EV
  qui gen comp_orig = $COMP
  
  qui xtreg $DV $COMP i.year if $MAINIF & switcher==1, fe cluster(fcode)
  
  * calculate point estimate of average effect
  qui replace $COMP=0 if $PREDICTIF  & switcher==1
  qui predict lestspend_C if $PREDICTIF  & switcher==1, xb
  qui replace $COMP=1  if $PREDICTIF  & switcher==1
  qui predict lestspend_A if $PREDICTIF  & switcher==1, xb
  qui gen diffspend = exp(lestspend_A) - exp(lestspend_C)
  qui sum diffspend
  qui replace $COMP = comp_orig

  * store to matrix
  local diff = r(mean)
  matrix B = [`diff']
  matrix EFF_COMP_SWITCH = B , EFF_COMP_SWITCH
  
  * calculate and store pct to matrix
  qui sum $DV_RAW if $PREDICTIF & switcher==1 & $COMP==0
  local meanspend = r(mean)
  matrix B = [`diff'/`meanspend']
  matrix EFF_COMP_SWITCH_PCT = B , EFF_COMP_SWITCH_PCT

  * reset vars
  drop lestspend_A lestspend_C diffspend  
  qui replace $COMP = comp_orig

  *** 4. estimate on bootstrap sample: YES covars, switchers only
  qui xtreg $DV $COMP $PERF i.year if $MAINIF & switcher==1, fe cluster(fcode)

  * calculate point estimate of average effect
  qui replace $COMP=0 if $PREDICTIF & switcher==1
  qui predict lestspend_C if $PREDICTIF & switcher==1, xb
  qui replace $COMP=1  if $PREDICTIF & switcher==1
  qui predict lestspend_A if $PREDICTIF & switcher==1, xb
  qui gen diffspend = exp(lestspend_A) - exp(lestspend_C)
  qui sum diffspend 
  qui replace $COMP = comp_orig
  
  * store raw value and pct to matrix
  local diff = r(mean)
  matrix B = [`diff']
  matrix EFF_COMP_PERF_SWITCH = B , EFF_COMP_PERF_SWITCH
  
  * calculate and store pct to matrix
  qui sum $DV_RAW if $PREDICTIF & switcher==1 & $COMP==0
  local meanspend = r(mean)
  matrix B = [`diff'/`meanspend']
  matrix EFF_COMP_PERF_SWITCH_PCT = B , EFF_COMP_PERF_SWITCH_PCT

  * reset original data
  clear
  use ./int/temp_bstrap
  
  * next bootstrap sample
}
* End bootstrap resampling loop


* Transpose matrix and save to variable
foreach mat in EFF_COMP EFF_COMP_PERF EFF_COMP_SWITCH EFF_COMP_PERF_SWITCH {
  matrix `mat' = `mat''
  svmat float `mat', names(`mat')
  matrix `mat'_PCT = `mat'_PCT'
  svmat float `mat'_PCT, names(`mat'_PCT)
}

* Write results to file for Table 3
file open myfile using "./$RESULTS/Table_3_Magnitudes_b$BLOOPS.csv", write replace
file write myfile "Model, Effect USD, 95_low, 95_up, Effect(%), 95_low, 95_up" _n 

foreach var in EFF_COMP EFF_COMP_PERF EFF_COMP_SWITCH EFF_COMP_PERF_SWITCH {
	mean `var'1
	matrix M = e(b)
    file write myfile "`var'," %7.0f (M[1,1]) ","
	centile `var'1, centile(2.5 50 97.5)
    file write myfile %7.0f (r(c_1)) "," %7.0f (r(c_3)) ","
	mean `var'_PCT1
	matrix M = e(b)
    file write myfile %7.2f (100*M[1,1]) "%,"
	centile `var'_PCT1, centile(2.5 50 97.5)
	file write myfile %7.2f (100*r(c_1)) "%," %7.2f (100*r(c_3)) "%" _n
}
file close myfile

* Add model numbers to CSV
local localfile = "./output/Table_3_Magnitudes_b$BLOOPS.csv"
!sed -e "s/EFF_COMP,/Model 1,/g" -e "s/EFF_COMP_PERF,/Model 2,/g" -e "s/EFF_COMP_SWITCH,/Model 5,/g" -e "s/EFF_COMP_PERF_SWITCH,/Model 6,/g" -i "" `localfile'

* Tex-readable Table 3
$CSVTOTEX -e 's/%/\\%/g' $RESULTS/Table_3_Magnitudes_b$BLOOPS.csv >  $RESULTS/Table_3_Magnitudes_b$BLOOPS.tex


***********************************************************************
*  Figure 6 and Table A11: Effect magnitudes by factory size
clear
use ./int/data_postmain.dta 

* Save reduced dataset, estimation sample only
keep fcode year $COMP $DV $DV_RAW $PERF factoryobs* switcher facsize*
keep if $MAINIF
save ./int/temp_bstrap.dta, replace

* holder matrix
foreach size in 0 1 {
	matrix s`size'_COMP = [.]
	matrix s`size'_COMP_PCT = [.]
	matrix s`size'_COMP_PERF = [.]
	matrix s`size'_COMP_PERF_PCT = [.]
	matrix s`size'_COMP_SWITCH = [.]
	matrix s`size'_COMP_SWITCH_PCT = [.]
	matrix s`size'_COMP_PERF_SWITCH = [.]
	matrix s`size'_COMP_PERF_SWITCH_PCT = [.]
}

global PREDICTIF $MAINIF & $DV!=. & $COMP !=. 

* use BLOOPS from above
forvalues i=1/$BLOOPS {
  di "Effects by factory size: Bootstrap `i'"
  * this picks in clusters
  bsample, cluster(fcode)

  * relabel the factory codes
  qui gen s_fcode = string(fcode)
  sort s_fcode year
  qui by s_fcode year: egen series = seq()
  qui gen s_fcode2=s_fcode + string(series)
  qui encode s_fcode2, gen(fcode2)
  qui xtset fcode2 year

  * backup the explanatory variable
  qui gen comp_orig = $COMP
  
  *** 1. estimate on bootstrap sample: NO covars
  qui xtreg $DV facsize2#c.$COMP i.year if $MAINIF, fe cluster(fcode)
  
  foreach size in 0 1 {  
	  * calculate point estimate of average effect
	  qui replace $COMP=0 if $PREDICTIF
	  qui predict lestspend_C if $PREDICTIF & facsize2==`size', xb
	  qui replace $COMP=1  if $PREDICTIF
	  qui predict lestspend_A if $PREDICTIF & facsize2==`size', xb
	  qui gen diffspend = exp(lestspend_A) - exp(lestspend_C) if facsize2==`size'
	  qui sum diffspend if facsize2==`size'
      qui replace $COMP = comp_orig
	  
	  * store dollar total to matrix
	  local diff = r(mean)
	  matrix B = [`diff']
	  matrix s`size'_COMP = B , s`size'_COMP
  
	  * calculate and store pct to matrix
	  qui sum $DV_RAW if $PREDICTIF & facsize2==`size' & $COMP==0
	  local meanspend = r(mean)
	  matrix B = [`diff'/`meanspend']
	  matrix s`size'_COMP_PCT = B , s`size'_COMP_PCT
    
	* reset vars for next simulation
	drop lestspend_A lestspend_C diffspend 
  }
	
  * prepare next regression
  qui replace $COMP = comp_orig

  *** 2. estimate on bootstrap sample: YES covars
  qui xtreg $DV facsize2#c.$COMP $PERF i.year if $MAINIF, fe cluster(fcode)

  foreach size in 0 1 {  
	  * calculate point estimate of average effect
	  qui replace $COMP=0 if $PREDICTIF
	  qui predict lestspend_C if $PREDICTIF & facsize2==`size', xb
	  qui replace $COMP=1  if $PREDICTIF
	  qui predict lestspend_A if $PREDICTIF & facsize2==`size', xb
	  qui gen diffspend = exp(lestspend_A) - exp(lestspend_C) if facsize2==`size'
	  qui sum diffspend if facsize2==`size'
      qui replace $COMP = comp_orig
	  
	  * store dollar total to matrix
	  local diff = r(mean)
	  matrix B = [`diff']
	  matrix s`size'_COMP_PERF = B , s`size'_COMP_PERF

	  * calculate and store pct to matrix
	  qui sum $DV_RAW if $PREDICTIF & facsize2==`size' & $COMP==0
	  local meanspend = r(mean)
	  matrix B = [`diff'/`meanspend']
	  matrix s`size'_COMP_PERF_PCT = B , s`size'_COMP_PERF_PCT

	  * reset vars for next simulation
	  drop lestspend_A lestspend_C diffspend 
  }

  * prepare next regression
  qui replace $COMP = comp_orig
  
  *** 3. estimate on bootstrap sample: NO covars, switchers only
  qui xtreg $DV facsize2#c.$COMP i.year if $MAINIF & switcher==1, fe cluster(fcode)
  
  foreach size in 0 1 {  
	  * calculate point estimate of average effect
	  qui replace $COMP=0 if $PREDICTIF
	  qui predict lestspend_C if $PREDICTIF & facsize2==`size', xb
	  qui replace $COMP=1  if $PREDICTIF
	  qui predict lestspend_A if $PREDICTIF & facsize2==`size', xb
	  qui gen diffspend = exp(lestspend_A) - exp(lestspend_C) if facsize2==`size'
	  qui sum diffspend if facsize2==`size'
      qui replace $COMP = comp_orig
	  
	  * store dollar total to matrix
	  local diff = r(mean)
	  matrix B = [`diff']
	  matrix s`size'_COMP_SWITCH = B , s`size'_COMP_SWITCH

	  * calculate and store pct to matrix
	  qui sum $DV_RAW if $PREDICTIF & facsize2==`size'  & $COMP==0
	  local meanspend = r(mean)
	  matrix B = [`diff'/`meanspend']
	  matrix s`size'_COMP_SWITCH_PCT = B , s`size'_COMP_SWITCH_PCT

	  * reset vars for next simulation
	  drop lestspend_A lestspend_C diffspend 
  }

  * prepare next regression
  qui replace $COMP = comp_orig

  *** 4. estimate on bootstrap sample: YES covars, switchers only
  qui xtreg $DV facsize2#c.$COMP $PERF i.year if $MAINIF & switcher==1, fe cluster(fcode)

  foreach size in 0 1 {  
	  * calculate point estimate of average effect
	  qui replace $COMP=0 if $PREDICTIF
	  qui predict lestspend_C if $PREDICTIF & facsize2==`size', xb
	  qui replace $COMP=1  if $PREDICTIF
	  qui predict lestspend_A if $PREDICTIF & facsize2==`size', xb
	  qui gen diffspend = exp(lestspend_A) - exp(lestspend_C) if facsize2==`size'
	  qui sum diffspend if facsize2==`size'
      qui replace $COMP = comp_orig
	  
	  * store dollar total to matrix
	  local diff = r(mean)
	  matrix B = [`diff']
	  matrix s`size'_COMP_PERF_SWITCH = B , s`size'_COMP_PERF_SWITCH

	  * calculate and store pct to matrix
	  qui sum $DV_RAW if $PREDICTIF & facsize2==`size'  & $COMP==0
	  local meanspend = r(mean)
	  matrix B = [`diff'/`meanspend']
	  matrix s`size'_COMP_PERF_SWITCH_PCT = B , s`size'_COMP_PERF_SWITCH_PCT

	  * reset vars for next simulation
	  drop lestspend_A lestspend_C diffspend 
  }

  * reset original data for next bootstrap sample
  clear
  use ./int/temp_bstrap
}
* End bootstrap sampling loop


* Transpose matrix and save to variables
foreach mat in COMP COMP_PERF COMP_SWITCH COMP_PERF_SWITCH {
  foreach size in 0 1 {
	  matrix s`size'_`mat' = s`size'_`mat''
	  svmat s`size'_`mat', names(s`size'_`mat')
	  matrix s`size'_`mat'_PCT = s`size'_`mat'_PCT'
	  svmat float s`size'_`mat'_PCT, names(s`size'_`mat'_PCT)
  }
}

* Write factory effects magnitudes to file
file open myfile using "./$RESULTS/Table_A11_Facsize_b$BLOOPS.csv", write replace
file write myfile "Variable, Effect USD, 95_low, 95_up, Effect(%), 95_low, 95_up" _n 
foreach size in 0 1 {
	foreach var in COMP COMP_PERF COMP_SWITCH COMP_PERF_SWITCH {
		mean s`size'_`var'1
		matrix M = e(b)
		file write myfile "s`size'_`var'," %7.0f (M[1,1]) ","
		centile s`size'_`var'1, centile(2.5 50 97.5)
		file write myfile %7.0f (r(c_1)) "," %7.0f (r(c_3)) ","
		mean s`size'_`var'_PCT1
		matrix M = e(b)
		file write myfile %7.2f (100*M[1,1]) "%,"
		centile s`size'_`var'_PCT1, centile(2.5 50 97.5)
		file write myfile %7.2f (100*r(c_1)) "%," %7.2f (100*r(c_3)) "%" _n
	}
}
file close myfile



***********************************************************************
* Figure A1: Effects by individual audit item
clear
use ./int/data_postmain.dta

* Reduce the dataset for estimation sample only
keep fcode year $COMP $AUDITCATS $DV $DV_RAW $PERF validcatsobs factoryobs*
keep if validcatsobs >= 2
save ./int/temp_bstrap.dta, replace

* holder matrices
foreach cat in $AUDITCATS {
	matrix `cat' = [.]
	matrix `cat'_PCT = [.]
	matrix `cat'_PERF = [.]
	matrix `cat'_PERF_PCT = [.]
}

global PREDICTIF $MAINIF_CAT & $DV != . & $COMP !=. 

*** LOOP START
* use BLOOPS from above
forvalues i=1/$BLOOPS {
  di "Effects by audit item: Bootstrap `i'"
  * this picks in clusters
  bsample, cluster(fcode)

  * relabel the factory codes
  qui gen s_fcode = string(fcode)
  sort s_fcode year
  qui by s_fcode year: egen series = seq()
  qui gen s_fcode2=s_fcode + string(series)
  qui encode s_fcode2, gen(fcode2)
  qui xtset fcode2 year

  * backup all explanatory variables
  foreach var in $AUDITCATS {
	qui gen `var'_orig = `var'
  }

  * 1. Estimate auditcats model (no performance covariates)
  qui xtreg $DV $AUDITCATS i.year if $MAINIF_CAT, fe cluster(fcode)

  foreach var in $AUDITCATS {  
	  * calculate point estimate of average effect
	  qui replace `var'=0 if $PREDICTIF & `var' != .
	  qui predict lestspend_fail if $PREDICTIF & `var' != ., xb
	  qui replace `var'=1  if $PREDICTIF & `var' != .
	  qui predict lestspend_pass if $PREDICTIF & `var' != ., xb
	  qui gen diffspend = exp(lestspend_pass) - exp(lestspend_fail) if $PREDICTIF & `var' != .
	  qui sum diffspend if $PREDICTIF & `var' != .
	  
	  * store dollar total to matrix
	  local diff = r(mean)
	  matrix B = [`diff']
	  matrix `var' = B , `var'

	  * calculate and store pct to matrix
	  qui sum $DV_RAW if $PREDICTIF & `var' != .  & $COMP==0
	  local meanspend = r(mean)
	  matrix B = [`diff'/`meanspend']
	  matrix `var'_PCT = B , `var'_PCT

	  * reset vars for next simulation
	  drop lestspend_pass lestspend_fail diffspend 
  }

  * reset all explanatory variables
  foreach var in $AUDITCATS {
	qui replace `var' = `var'_orig
  }

  
  * 2. Estimate auditcats + performance covariates
  qui xtreg $DV $AUDITCATS $PERF i.year if $MAINIF_CAT, fe cluster(fcode)

  foreach var in $AUDITCATS {  
	  * calculate point estimate of average effect
	  qui replace `var'=0 if $PREDICTIF & `var' != .
	  qui predict lestspend_fail if $PREDICTIF & `var' != ., xb
	  qui replace `var'=1  if $PREDICTIF & `var' != .
	  qui predict lestspend_pass if $PREDICTIF & `var' != ., xb
	  qui gen diffspend = exp(lestspend_pass) - exp(lestspend_fail) if $PREDICTIF & `var' != .
	  qui sum diffspend if $PREDICTIF & `var' != .
	  
	  * store dollar total to matrix
	  local diff = r(mean)
	  matrix B = [`diff']
	  matrix `var'_PERF = B , `var'_PERF

	  * calculate and store pct to matrix
	  qui sum $DV_RAW if $PREDICTIF & `var' != . & $COMP==0
	  local meanspend = r(mean)
	  matrix B = [`diff'/`meanspend']
	  matrix `var'_PERF_PCT = B , `var'_PERF_PCT

	  * reset vars for next simulation
	  drop lestspend_pass lestspend_fail diffspend 
  }

  * reset original data for next bootstrap sample
  clear
  use ./int/temp_bstrap
}


* Transpose matrix and save to variables
foreach var in $AUDITCATS {
  matrix `var' = `var''
  matrix `var'_PCT = `var'_PCT'
  matrix `var'_PERF = `var'_PERF'
  matrix `var'_PERF_PCT = `var'_PERF_PCT'
  svmat float `var', names(`var'_mag)
  svmat float `var'_PCT, names(`var'_mag_PCT)
  svmat float `var'_PERF, names(`var'_mag_PERF)
  svmat float `var'_PERF_PCT, names(`var'_mag_PERF_PCT)
}
  
* Write to CSV
file open myfile using "./$RESULTS/Figure_A1_Items_b$BLOOPS.csv", write replace
file write myfile "Variable, Effect USD, 95_low, 95_up, Effect(%), 95_low, 95_up" _n 

foreach cat in $AUDITCATS {
	foreach suffix in mag mag_PERF {
		mean `cat'_`suffix'1
		matrix M = e(b)
		file write myfile "`cat'_`suffix'," %7.0f (M[1,1]) ","
		centile `cat'_`suffix'1, centile(2.5 50 97.5)
		file write myfile %7.0f (r(c_1)) "," %7.0f (r(c_3)) ","
		mean `cat'_`suffix'_PCT1
		matrix M = e(b)
		file write myfile %7.2f (100*M[1,1]) "%,"
		centile `cat'_`suffix'_PCT1, centile(2.5 50 97.5)
		file write myfile %7.2f (100*r(c_1)) "%," %7.2f (100*r(c_3)) "%" _n
	}
}
file close myfile


