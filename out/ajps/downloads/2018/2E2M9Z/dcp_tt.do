* ./dcp_tt.do
* Replication script for Distelhorst and Locke. Does Compliance Pay?. AJPS.

* Generates rightmost panel of Table 2.
* precursors: dcp_main.do --> ./int/data_postmain.dta and sets globals
* called by ./rundir.do (if uncommented)

* Note: unit-specific time trends (Columns 11 and 12) are computationally intensive
* Suggest running overnight or using a remote computing cluster

* run after main.do to generate data_postmain.dta and needed globals
clear
set more off
use ./int/data_postmain.dta

* Main analysis globals
global DV lestspend_dall
global COMP compyr
global RESULTS output

di "***" _n "Factory-specific time trends" _n "***"
global TTIF factoryobs >=2

* Time-trend variable to interact with factory ID indicator
sort fcode year
by fcode: egen factorytt = seq() if $TTIF
global XVARS i.year i.fcode#c.factorytt

* Rightmost panel of Table 2, Columns 9-12 *
log using ./$RESULTS/Table_2_Cols_9_12.text, text replace

* Table 2. Column 9
xtreg $DV $COMP i.year if $TTIF, fe cluster(fcode)

* Table 2. Column 10
xtreg $DV gradeyr i.year if $TTIF, fe cluster(fcode)

* Factory-specific time trends
* Table 2. Column 11
xtreg $DV $COMP $XVARS if $TTIF, fe cluster(fcode)

* Table 2. Column 12
xtreg $DV gradeyr $XVARS if $TTIF, fe cluster(fcode)

log close
