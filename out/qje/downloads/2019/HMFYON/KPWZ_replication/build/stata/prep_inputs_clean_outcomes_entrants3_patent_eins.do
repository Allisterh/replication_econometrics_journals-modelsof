
*******************************************************************************
*******************************************************************************
* PREP input files for clean_outcomes_w2
*******************************************************************************
*******************************************************************************
set more off
clear 
set maxvar 8000

*******************************************************************************
*1.0 LOAD CSV OF EIN-YEAR-worker cohort file
*******************************************************************************
local dataset="entrants3"
insheet using $rawdir/mean_entrant3s.csv, clear	

*******************************************************************************
*2.0 CLEAN AND RENAME ELEMENTS
*******************************************************************************
*PAYER_TIN_W2_MAX,tax_yr,mean_entrant3_wages,entrant3s

rename payer_tin_w2_max tin
rename tax_yr year
rename entrant3s ent3
rename mean_entrant3_wages wage_ent3

*******************************************************************************
*3.0 SAVE
*******************************************************************************
compress
sort tin year
save $dumpdir/outcomes_patent_eins_w2_`dataset'.dta, replace
*}
